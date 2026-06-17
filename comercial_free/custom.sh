#!/bin/bash
# Curitiba 11 de Junho de 2026.
# Editor: Jeverson D Silva   ///@JCGAMESCLASSICOS...
# fliperama-comercial

# O Batocera chama este script com "start" no boot e "stop" no desligamento.
# Só executamos no boot.
if [ "$1" = "stop" ]; then
    exit 0
fi

pkill unclutter

BATOCERA_CONF="/userdata/system/batocera.conf"
LAST_INPUT="/userdata/system/configs/emulationstation/es_last_input.cfg"
ES_INPUT="/userdata/system/configs/emulationstation/es_input.cfg"
ES_INPUT_TEMPLATE="/userdata/system/.dev/es_input_livre.cfg"

JC_PROCESSOS="/userdata/system/.dev/scripts/jc_processos.sh" 

# Lê o valor de MODO_COMERCIAL_DESATIVADO (com ou sem espaços ao redor do =)
VALOR=$(grep -E "^MODO_COMERCIAL_DESATIVADO\s*=\s*" "$BATOCERA_CONF" | sed 's/.*=\s*//' | tr -d '[:space:]')

ES_INPUT_LIVRE_BKP="/userdata/system/.dev/es_input_livre.bkp"

if [ "$VALOR" = "1" ]; then
    echo "Modo livre ativado. Aplicando configuração de input..."
    killall -9 python3.12
    killall -9 python3.14
    killall -9 python3.13

    # Garante que os daemons do modo comercial não fiquem rodando
    "$JC_PROCESSOS" parar

    # Cria o backup do modo livre APENAS se ele ainda não existir.
    # Fonte preferida: /userdata/system/.dev/es_input.cfg
    # Fallback: /userdata/system/configs/emulationstation/es_last_input.cfg
    ES_INPUT_DEV="/userdata/system/.dev/es_input.cfg"
    if [ ! -f "$ES_INPUT_LIVRE_BKP" ]; then
        if [ -f "$ES_INPUT_DEV" ]; then
            cp -f "$ES_INPUT_DEV" "$ES_INPUT_LIVRE_BKP"
            echo "Backup es_input_livre.bkp criado a partir de $ES_INPUT_DEV"
        elif [ -f "$LAST_INPUT" ]; then
            cp -f "$LAST_INPUT" "$ES_INPUT_LIVRE_BKP"
            echo "Backup es_input_livre.bkp criado a partir de $LAST_INPUT"
        else
            echo "AVISO: Nenhuma fonte encontrada para criar o backup."
        fi
    fi

    # Mescla o bloco <inputConfig> do es_last_input.cfg dentro do backup:
    # se já existir um bloco com o mesmo deviceGUID + deviceName, ele é substituído;
    # caso contrário, o bloco é adicionado antes de </inputList>.
    if [ -f "$LAST_INPUT" ] && [ -f "$ES_INPUT_LIVRE_BKP" ]; then
        GUID=$(grep -o 'deviceGUID="[^"]*"' "$LAST_INPUT" | head -n1)
        NAME=$(grep -o 'deviceName="[^"]*"' "$LAST_INPUT" | head -n1)
        if [ -n "$GUID" ]; then
            BLOCO=$(awk '/<inputConfig /,/<\/inputConfig>/' "$LAST_INPUT")
            export BLOCO GUID NAME
            awk '
                $0 ~ /<inputConfig / && index($0, ENVIRON["GUID"]) && index($0, ENVIRON["NAME"]) { skip=1 }
                skip && /<\/inputConfig>/ { skip=0; next }
                skip { next }
                /<\/inputList>/ { print ENVIRON["BLOCO"] }
                { print }
            ' "$ES_INPUT_LIVRE_BKP" > "$ES_INPUT_LIVRE_BKP.tmp" && mv "$ES_INPUT_LIVRE_BKP.tmp" "$ES_INPUT_LIVRE_BKP"
            echo "Bloco de $LAST_INPUT mesclado em es_input_livre.bkp (GUID: $GUID)"
        else
            echo "AVISO: Nenhum deviceGUID encontrado em $LAST_INPUT. Merge ignorado."
        fi
    fi

    # Restaura diretamente o backup do modo livre, ignorando configurações temporárias
    if [ -f "$ES_INPUT_LIVRE_BKP" ]; then
        cp -f "$ES_INPUT_LIVRE_BKP" "$ES_INPUT"
        echo "Configuração restaurada do backup es_input_livre.bkp"
    else
        echo "AVISO: Backup $ES_INPUT_LIVRE_BKP não encontrado. Mantendo atual."
	/userdata/system/.dev/scripts/jc_processos.sh iniciar
    fi

    # Desativa (comenta) as configurações do modo comercial no batocera.conf
    sed -i 's/^\(global\.retroarch\.menu_driver=rgui\)/##\1/;
s/^\(global\.retroarch\.crt_switch_resolution = "4"\)/##\1/;
s/^\(global notifications can be avoid with replacing "true" by "false"\)/##\1/;
s/^\(global\.retroarch\.notification_show_autoconfig = "true"\)/##\1/;
s/^\(global\.retroarch\.notification_show_cheats_applied = "true"\)/##\1/;
s/^\(global\.retroarch\.notification_show_config_override_load = "true"\)/##\1/;
s/^\(global\.retroarch\.notification_show_fast_forward = "true"\)/##\1/;
s/^\(global\.retroarch\.notification_show_netplay_extra = "true"\)/##\1/;
s/^\(global\.retroarch\.notification_show_patch_applied = "true"\)/##\1/;
s/^\(global\.retroarch\.notification_show_remap_load = "true"\)/##\1/;
s/^\(global\.retroarch\.notification_show_screenshot = "true"\)/##\1/;
s/^\(global\.retroarch\.notification_show_set_initial_disk = "true"\)/##\1/;
s/^\(mame\.rotation=none\)/##\1/;
s/^\(fbneo\.video_allow_rotate=off\)/##\1/;' "$BATOCERA_CONF"
    echo "Configurações do modo comercial comentadas no batocera.conf"

else
    echo "Modo comercial ativo. Restaurando configuração padrão de input..."
    if [ -f "$ES_INPUT_TEMPLATE" ]; then
        cp -f "$ES_INPUT_TEMPLATE" "$ES_INPUT"
        echo "es_input.cfg restaurado a partir do template."	
	/userdata/system/.dev/scripts/jc_processos.sh iniciar
    else
        echo "ERRO: Template $ES_INPUT_TEMPLATE não encontrado!"
    fi

    # Limpa inputs desnecessários dos joysticks no es_input.cfg
    # NÃO altera o bloco do teclado
    awk '
    /<inputConfig type="joystick"/ { injoy=1 }
    injoy && /<\/inputConfig>/ { injoy=0 }
    injoy && $0 ~ /name="(start|select|a|x|y|l2|r2|hotkey)"/ { next } #|pagedown|pageup|left|right|joystick2left|joystick1left
    { print }
    ' "$ES_INPUT" > "$ES_INPUT.tmp" && mv "$ES_INPUT.tmp" "$ES_INPUT"
    echo "Limpeza de inputs concluída em $ES_INPUT"

    # Inicia os daemons do modo comercial (one e 3ree), se não estiverem rodando
    "$JC_PROCESSOS" iniciar

    # Reativa (descomenta) as configurações do modo comercial no batocera.conf
    sed -i 's/^##\(global\.retroarch\.menu_driver=rgui\)/\1/;
s/^##\(global\.retroarch\.crt_switch_resolution = "4"\)/\1/;
s/^##\(global notifications can be avoid with replacing "true" by "false"\)/\1/;
s/^##\(global\.retroarch\.notification_show_autoconfig = "true"\)/\1/;
s/^##\(global\.retroarch\.notification_show_cheats_applied = "true"\)/\1/;
s/^##\(global\.retroarch\.notification_show_config_override_load = "true"\)/\1/;
s/^##\(global\.retroarch\.notification_show_fast_forward = "true"\)/\1/;
s/^##\(global\.retroarch\.notification_show_netplay_extra = "true"\)/\1/;
s/^##\(global\.retroarch\.notification_show_patch_applied = "true"\)/\1/;
s/^##\(global\.retroarch\.notification_show_remap_load = "true"\)/\1/;
s/^##\(global\.retroarch\.notification_show_screenshot = "true"\)/\1/;
s/^##\(global\.retroarch\.notification_show_set_initial_disk = "true"\)/\1/;
s/^##\(mame\.rotation=none\)/\1/;
s/^##\(fbneo\.video_allow_rotate=off\)/\1/;' "$BATOCERA_CONF"
    echo "Configurações do modo comercial reativadas no batocera.conf"
fi

ARQUIVO="/userdata/system/batocera.conf"
BKP="/userdata/system/.dev/batocera.conf.bkp"

LINHAS=$(wc -l < "$ARQUIVO")

if [ "$LINHAS" -gt 10 ]; then
    echo "Arquivo tem mais de 10 linhas ($LINHAS). Criando backup..."
    cp "$ARQUIVO" "$BKP"
elif [ "$LINHAS" -lt 10 ]; then
    echo "Arquivo tem menos de 10 linhas ($LINHAS). Restaurando backup..."
    if [ -f "$BKP" ]; then
        cp "$BKP" "$ARQUIVO"
    else
        echo "Backup não encontrado!"
    fi
else
    echo "Arquivo tem exatamente 10 linhas. Nenhuma ação."
fi
