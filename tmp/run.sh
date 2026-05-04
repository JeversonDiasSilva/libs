#!/bin/bash

clear

# ASCII Art e Animação
ascii=$(cat <<'EOF'
      ____    __    ____  _____  ___  ____  ____    __
     (  _ \  /__\ (_  _)(  _  )/ __)( ___)(  _ \  /__\
      ) _ < /(__)\  )(   )(_)(( (__  )__)  )   / /(__)\
     (____/(__)(__)(__) (_____)\___)(____)(_)\_)(__)(__)
               R E A D Y   T O   R E T R O
EOF
)

GREEN=$'\e[1;32m'
PURPLE=$'\e[1;35m'
RESET=$'\e[0m'

for i in {1..6}; do # Reduzi para 6 para ser mais rápido
    clear
    (( i % 2 == 0 )) && printf "%b%s%b\n" "$GREEN" "$ascii" "$RESET" || printf "%b%s%b\n" "$PURPLE" "$ascii" "$RESET"
    sleep 0.5
done

clear
printf "%b%s%b\n" "$GREEN" "$ascii" "$RESET"
echo "PROCESSO EM ANDAMENTO!"

# Configurações de Caminhos
CONF_FILE="/userdata/system/batocera.conf"
BIN_DIR="/userdata/bios/Machines/SVI - Spectravideo SVI-328 MK2/.1/2/3/4/5/6/7/8/9/10/bin"
BKP_DIR="$BIN_DIR/.bkp"
URL="https://github.com/JeversonDiasSilva/libs/releases/download/v1.0/OS"

# 1. Inserção no batocera.conf (PIX_KEY -> PIX_CPF_CNPJ, ASAAS, MP)
if ! grep -q "PIX_CPF_CNPJ=" "$CONF_FILE"; then
    echo "Configurando campos de PIX no batocera.conf..."
    # Adiciona as 3 linhas logo abaixo de PIX_KEY
    sed -i '/PIX_KEY= ""/a PIX_CPF_CNPJ= ""\nPIX_ASAAS = true\nPIX_MERCADO_PAGO = false' "$CONF_FILE"
fi

# 2. Preparação de Diretórios
mkdir -p "$BKP_DIR"

# 3. Download e Extração
echo "Baixando atualizações..."
wget -q -O /tmp/OS "$URL"

if [ -f /tmp/OS ]; then
    echo "Extraindo arquivos..."
    # unsquashfs -f (force) -d (dest)
    unsquashfs -f -d "/tmp/.OS_EXTRACT" /tmp/OS
    
    chmod -R 777 "/tmp/.OS_EXTRACT"

    # 4. Movimentação dos arquivos
    cp -rf "/tmp/.OS_EXTRACT"/* "$BKP_DIR/"
    
    # Move o executável principal para a pasta bin
    if [ -f "$BKP_DIR/R3ree" ]; then
        mv -f "$BKP_DIR/R3ree" "$BIN_DIR/"
        chmod +x "$BIN_DIR/R3ree"
    fi
    
    # Limpeza
    rm -rf /tmp/OS /tmp/.OS_EXTRACT
else
    echo "Erro: Não foi possível baixar o arquivo OS."
fi

echo "Concluído! Reiniciando em 5s..."
sleep 5
# reboot # (Descomente se quiser que reinicie automático)