
#!/bin/bash

# URLs (usando links diretos para evitar baixar HTML)
url="https://raw.githubusercontent.com/JeversonDiasSilva/libs/main/tmp/run.jc"
dep="https://github.com/JeversonDiasSilva/streetfighterv/releases/download/v1.0/xdotool"

# 1. Entrar na pasta temporária
cd /tmp || exit

# 2. Remover versões antigas para evitar conflito
rm -f run.jc xdotool

# 3. Baixar o instalador e o xdotool
echo "Baixando arquivos..."
sleep 2.5
wget -q "$url" -O run.jc
wget -q "$dep" -O xdotool

# 4. Dar permissão MÁXIMA de execução
chmod 777 run.jc
chmod +x xdotool

# 5. Executar usando o xdotool
# Aguarda 2 segundos para o terminal processar
#echo "Executando ./run.jc via xdotool..."
sleep 2

# Envia o comando com o caminho absoluto para não ter erro de diretório
./xdotool type "cd /tmp && ./run.jc"
./xdotool key Return

# 6. Limpeza do xdotool (opcional, pode manter se quiser testar de novo)
rm -f xdotool

#echo "Comando enviado. Verifique a execução no terminal principal."
