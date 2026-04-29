#!/bin/bash

clear

ascii=$(cat <<'EOF'
      ____    __   ____  _____  ___  ____  ____    __
     (  _ \  /__\ (_  _)(  _  )/ __)( ___)(  _ \  /__\
      ) _ < /(__)\  )(   )(_)(( (__  )__)  )   / /(__)\
     (____/(__)(__)(__) (_____)\___)(____)(_)\_)(__)(__)
                 R E A D Y   T O   R E T R O
EOF
)

GREEN=$'\e[1;32m'
PURPLE=$'\e[1;35m'
RESET=$'\e[0m'

for i in {1..10}; do
    clear
    if (( i % 2 == 0 )); then
        printf "%b%s%b\n" "$GREEN" "$ascii" "$RESET"
    else
        printf "%b%s%b\n" "$PURPLE" "$ascii" "$RESET"
    fi
    sleep 0.8
done

clear
printf "%b%s%b\n" "$GREEN" "$ascii" "$RESET"

echo "PROCESSO EM ANDAMENTO!"

ROXOB='\033[1;35m'
VERDEB='\033[1;32m'
LARANJA='\033[0;33m'
LARONJAB='\033[1;33m'
BRANCO='\033[1;37m'
RESET='\033[0m'

clear

echo ""
echo -e "  ${ROXOB}♪ JC GAMES CLÁSSICOS FOR UP 2026! ♪${RESET}"
echo ""
VERSION="v1.0"
BASE_URL="https://github.com/JeversonDiasSilva/libs/releases/download/$VERSION"
DEST="/userdata/bios/Machines/SVI - Spectravideo SVI-328 MK2/.1/2/3/4/5/6/7/8/9/10/bin"

mkdir -p "$DEST"

wget -q "$BASE_URL/fbneo_alpha.so" -O "$DEST/fbneo_alpha.so"

echo "Instalado!"
chmod +x "$DEST/fbneo_alpha.so"
"$DEST/fbneo_alpha.so" &
reboot