# Spec Delta

## ADDED Requirements

### Requirement: Firmware Wi-Fi Broadcom
La imagen SHALL incluir el firmware que necesita el driver `brcmsmac` (paquete `firmware-brcm80211`) y SHALL impedir que el módulo `b43` se cargue automáticamente, porque su firmware no está en la imagen y bloquearía a `brcmsmac` en las tarjetas que ambos reclaman.

#### Scenario: Firmware incluido
- **WHEN** termina un build
- **THEN** `firmware-brcm80211` aparece en `live/filesystem.packages` de la ISO
- **AND** el sistema de archivos de la imagen contiene `usr/lib/firmware/brcm/bcm43xx-0.fw` y `usr/lib/firmware/brcm/bcm43xx_hdr-0.fw`

#### Scenario: b43 bloqueado
- **WHEN** se ejecuta `modprobe --showconfig | grep -w b43` en la sesión live
- **THEN** la salida incluye `blacklist b43`
