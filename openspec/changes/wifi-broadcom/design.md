# Design

## Context

Ver `proposal.md` (Why). Medido en `debian:trixie` (kernel `6.12.117-1`, `firmware-brcm80211` `20250410-2`):

- `brcmsmac` pide `brcm/bcm43xx-0.fw` y `brcm/bcm43xx_hdr-0.fw` y reclama `bcma:m04BFid0812rev11`, `rev17` y `rev18`.
- `b43` reclama esos mismos tres alias en `bcma` (y otros en `bcma` y `ssb`), y su firmware (`b43/ucode*.fw`) no está en Debian: `firmware-b43-installer` lo descarga al instalarse.
- `firmware-brcm80211` ocupa 5,4 MB descargado y 18 MB instalado, no tiene dependencias y solo sugiere `initramfs-tools`.
- La ISO actual pesa 878 706 688 bytes; el límite es 1 000 000 000.
- Hoy ninguna configuración de `modprobe.d` de Debian bloquea `b43`.

## Goals / Non-Goals

**Goals:**

- Wi-Fi funcional en la MacBook Air 2012 y, en general, en tarjetas `brcmsmac`, sin pasos manuales en la sesión live.

**Non-Goals:**

- El driver propietario `wl` (`broadcom-sta-dkms`): requiere compilar un módulo con DKMS en cada kernel y está en `non-free`. Queda fuera mientras `brcmsmac` cubra el hardware objetivo.
- Soporte de tarjetas que solo maneja `b43`: necesitan `firmware-b43-installer`, que descarga el firmware de internet.
- Control automático de esto en CI: el cambio es pequeño y se verifica una vez con la ISO de CI. Un control permanente se puede sumar a CI más adelante si hay regresiones.

## Decisions

### 1. `firmware-brcm80211` en `30-red-firmware.list.chroot`

Se declara junto al resto del firmware Wi-Fi, en el mismo grupo que Intel, MediaTek y Realtek, y se actualiza el comentario del grupo. El paquete trae también el firmware de `brcmfmac` (Broadcom SDIO/USB/PCIe recientes): no se recorta, porque recortarlo exigiría modificar un paquete de Debian, y son pocos MB.

### 2. Bloqueo de `b43` con `modprobe.d`

Archivo `live-build/config/includes.chroot/etc/modprobe.d/mklinux-broadcom.conf` con `blacklist b43` y un comentario que explica el motivo y cómo revertirlo. `blacklist` solo impide la carga automática por alias: un `modprobe b43` manual sigue funcionando, y eso deja una salida a quien instale `firmware-b43-installer`.

Se sigue el patrón de configuración que ya usa la imagen (`includes.chroot` para `etc/default/keyboard`, LightDM y el panel de XFCE). Alternativa descartada: un paquete `mklinux-*` para un archivo de una línea. Tendría sentido si el bloqueo tuviera que actualizarse en sistemas instalados con `apt`, algo que se puede decidir con Calamares.

También se descarta bloquear `bcma`: es el bus que usa `brcmsmac`.

### 3. Comprobar también el initramfs

live-build regenera el initramfs dentro del chroot después de copiar `includes.chroot`, e `initramfs-tools` copia `/etc/modprobe.d` al initramfs. Si el `initrd.img` trae `b43`, el bloqueo tiene que estar dentro para que no lo cargue `udev` antes del sistema real. Se verifica con `lsinitramfs` sobre el `initrd.img` de la ISO (tarea 2.1).

## Risks / Trade-offs

- [`b43` o `brcmsmac` entran al initramfs sin el bloqueo] → Tarea 2.1. Si el bloqueo falta, se agrega un hook de chroot que ejecute `update-initramfs -u` después de copiar los includes.
- [`brcmsmac` carga pero la Wi-Fi no conecta (problemas conocidos de rendimiento en algunas BCM43224)] → La prueba en hardware real lo detecta. La alternativa (`wl`) se trataría en un cambio propio.
- [QEMU no prueba la Wi-Fi] → Aceptación con la ISO de CI en la MacBook Air 2012 por USB; en QEMU solo se repite una prueba rápida de no regresión.
- [El bloqueo afecta a tarjetas que solo maneja `b43`] → Sin su firmware no funcionaban; se documenta cómo quitar el bloqueo.

## Migration Plan

Sin migración: la ISO se regenera en cada build. Para revertir, se quita el paquete de la lista y el archivo de `modprobe.d`.
