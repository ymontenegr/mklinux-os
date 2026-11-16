# Proposal: wifi-broadcom

## Why

La ISO no trae el firmware que necesita el driver libre `brcmsmac`. Por eso las tarjetas Wi-Fi Broadcom que dependen de él no funcionan en la sesión live; entre ellas está la BCM43224 de la MacBook Air 2012 (`MacBookAir5,2`, `14e4:4353`), la máquina de desarrollo del proyecto. Además, en Debian el driver `b43` reclama los mismos núcleos 802.11 en el bus `bcma` (revisiones 0x11, 0x17 y 0x18). Si `b43` toma la tarjeta primero, falla por no tener su firmware (`firmware-b43-installer` lo descarga de internet y no puede ir en la ISO), y `brcmsmac` nunca la toma. Arrancar MKLinux OS desde una memoria USB en esa laptop es el siguiente uso previsto, y sin Wi-Fi solo hay red por anclaje USB o por un adaptador cableado.

## What Changes

- Se agrega `firmware-brcm80211` (non-free-firmware) a la lista de firmware de la imagen. Trae `brcm/bcm43xx-0.fw` y `brcm/bcm43xx_hdr-0.fw` para `brcmsmac` y el firmware de `brcmfmac` (Broadcom SDIO/USB/PCIe más recientes).
- Se bloquea la carga automática del módulo `b43` en la imagen, para que `brcmsmac` tome las tarjetas que ambos reclaman. `b43` no puede funcionar en la sesión live porque su firmware no está en la ISO.
- Se documenta cómo volver a habilitar `b43` en un sistema persistente o instalado que lo necesite.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `iso-build`: nuevo requisito de firmware Wi-Fi Broadcom (`firmware-brcm80211` incluido y `b43` bloqueado).
- `live-session`: nuevo requisito de Wi-Fi en tarjetas Broadcom compatibles con `brcmsmac`, verificado en hardware real.

## Impact

- Archivos: `live-build/config/package-lists/30-red-firmware.list.chroot`, un archivo nuevo en `live-build/config/includes.chroot/etc/modprobe.d/` y `docs/build.md`.
- Tamaño: unos +5 MB descargados (18 MB instalados) en una ISO de 879 MB. Sigue por debajo del límite de 1 000 000 000 bytes.
- Hardware: las tarjetas Broadcom antiguas que solo soporta `b43` (por ejemplo, BCM4306, BCM4311, BCM4318) ya no funcionaban en la ISO y siguen sin funcionar. En un sistema persistente o instalado se puede quitar el bloqueo e instalar `firmware-b43-installer`.
- Prueba: QEMU no emula tarjetas Wi-Fi Broadcom. La aceptación de la Wi-Fi requiere arrancar la ISO desde una memoria USB en la MacBook Air 2012; en QEMU solo se comprueba que nada más se rompe.
