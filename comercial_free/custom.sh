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
ES_INPUT_TEMPLATE="/userdata/system/.dev/es_input.cfg"

JC_PROCESSOS="/userdata/system/.dev/scripts/jc_processos.sh"

# Lê o valor de MODO_COMERCIAL_DESATIVADO (com ou sem espaços ao redor do =)
VALOR=$(grep -E "^MODO_COMERCIAL_DESATIVADO\s*=\s*" "$BATOCERA_CONF" | sed 's/.*=\s*//' | tr -d '[:space:]')

ES_INPUT_LIVRE_BKP="/userdata/system/.dev/es_input_livre.bkp"

if [ "$VALOR" = "1" ]; then
    echo "Modo livre ativado. Aplicando configuração de input..."
    killall -9 python3.12

    # Garante que os daemons do modo comercial não fiquem rodando
    "$JC_PROCESSOS" parar

    if [ -f "$LAST_INPUT" ] && grep -q '<inputConfig' "$LAST_INPUT"; then
        # Há configuração do usuário no es_last_input.cfg:
        # monta o es_input.cfg a partir do template + bloco do last_input

        # Restaura o template base (se existir)
        if [ -f "$ES_INPUT_TEMPLATE" ]; then
            cp -f "$ES_INPUT_TEMPLATE" "$ES_INPUT"
        fi

        # Insere o bloco do es_last_input.cfg, removendo antes qualquer
        # configuração existente com o MESMO deviceGUID (evita duplicidade —
        # o ES usa o primeiro bloco encontrado, então duplicar faz a config
        # antiga "vencer" da nova).
        python3 - "$LAST_INPUT" "$ES_INPUT" << 'PYEOF'
import re
import sys

last_input_file = sys.argv[1]
es_input_file   = sys.argv[2]

with open(last_input_file, 'r') as f:
    content = f.read()

start = content.find('<inputConfig')
end   = content.find('</inputConfig>')

if start == -1 or end == -1:
    print("ERRO: Bloco <inputConfig> não encontrado em", last_input_file)
    sys.exit(1)

input_block = content[start:end + len('</inputConfig>')]

# Extrai o deviceGUID do bloco novo
m = re.search(r'deviceGUID="([^"]+)"', input_block)
if not m:
    print("ERRO: deviceGUID não encontrado no bloco de", last_input_file)
    sys.exit(1)
guid = m.group(1)

with open(es_input_file, 'r') as f:
    es_content = f.read()

if '</inputList>' not in es_content:
    print("ERRO: </inputList> não encontrado em", es_input_file)
    sys.exit(1)

# Remove TODOS os blocos <inputConfig> existentes com o mesmo deviceGUID
pattern = re.compile(
    r'[ \t]*<inputConfig[^>]*deviceGUID="' + re.escape(guid) + r'".*?</inputConfig>\s*',
    re.DOTALL
)
removidos = len(pattern.findall(es_content))
es_content = pattern.sub('', es_content)
if removidos:
    print(f"Removido(s) {removidos} bloco(s) antigo(s) com GUID {guid}")

# Insere o bloco novo antes de </inputList>
new_content = es_content.replace('</inputList>', '\t' + input_block + '\n</inputList>', 1)

with open(es_input_file, 'w') as f:
    f.write(new_content)

print("Configuração aplicada com sucesso!")
PYEOF

        # Atualiza o backup do modo livre — será usado toda vez que o
        # sistema voltar para o modo livre sem um es_last_input.cfg válido
        cp -f "$ES_INPUT" "$ES_INPUT_LIVRE_BKP"
        echo "Backup do modo livre atualizado em $ES_INPUT_LIVRE_BKP"

    elif [ -f "$ES_INPUT_LIVRE_BKP" ]; then
        # Sem configuração nova: restaura o último backup do modo livre
        echo "Sem es_last_input.cfg válido. Restaurando backup do modo livre..."
        cp -f "$ES_INPUT_LIVRE_BKP" "$ES_INPUT"
        echo "es_input.cfg restaurado a partir de $ES_INPUT_LIVRE_BKP"
    else
        echo "AVISO: Sem es_last_input.cfg e sem backup do modo livre. Mantendo es_input.cfg atual."
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
