# INCLUDE

# sed
```bash
grep -q '^PIX_ASAAS_STATIC *= *true' /userdata/system/batocera.conf || \
sed -i '/^PIX_ON *=/a PIX_ASAAS_STATIC = true' /userdata/system/batocera.conf
```

PIX_ASAAS_STATIC = true >> /userdata/system/batocera.conf




```bash
# ------------ A0 - CONFIGURAÇÕES DO MODO COMERCIAL RETRO LUXXO----------- #
MODO_COMERCIAL_DESATIVADO = 1
TEMPO_JOGO_MINUTOS = 15
TEMPO_HOTKEY_SEGUNDOS = 1
TEMPO_MENU_SEGUNDOS = 1
TEMPO_DELAY_TIMER_SEGUNDOS = 1
PIX_ON = false
PIX_ASAAS_STATIC = true
PIX_KEY= ""
PIX_CPF_CNPJ= ""
PIX_ASAAS = true
PIX_MERCADO_PAGO = false
PIX_VALOR = 0,25
PIX_QUANTIDADE_CRÈDITOS = 100
CONFIGS_MODO_JANELA = false
COIN_INTERVAL_DELAY = 0.1
#############################################



# ------------ A - System Options ----------- #

## Security
```


```incluir
ASAAS_ACCESS_TOKEN = $aact_prod_xxx...
ASAAS_CPF_CNPJ = 12345678901
ASAAS_PIX_KEY = 6c8933ab-xxxx...    ← chave aleatória Asaas
MP_ACCESS_TOKEN = APP_USR-xxx...
MP_PIX_KEY = chave-aleatoria-mp     ← chave aleatória MP
```
