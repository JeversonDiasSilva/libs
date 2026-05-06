# INCLUDE

# sed
```bash
grep -q '^PIX_ASAAS_STATIC *= *true' /userdata/system/batocera.conf || \
sed -i '/^PIX_ON *=/a PIX_ASAAS_STATIC = true' /userdata/system/batocera.conf
```

PIX_ASAAS_STATIC = true >> /userdata/system/batocera.conf
