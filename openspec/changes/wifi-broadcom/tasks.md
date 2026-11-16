# Tasks

## 1. Firmware y bloqueo de b43

- [x] 1.1 Agregar `firmware-brcm80211` a `live-build/config/package-lists/30-red-firmware.list.chroot` y mencionar Broadcom en el comentario del grupo de firmware; verificar con `apt-get install --simulate --no-install-recommends` en `debian:trixie` (con `non-free-firmware`) que el paquete resuelve sin arrastrar paquetes nuevos
- [x] 1.2 Crear `live-build/config/includes.chroot/etc/modprobe.d/mklinux-broadcom.conf` con `blacklist b43` y un comentario con el motivo y cómo revertirlo (Decisión 2); verificar en un contenedor `debian:trixie` con `linux-image-amd64` y el archivo copiado que `modprobe --showconfig | grep -w b43` muestra `blacklist b43`
- [x] 1.3 Actualizar `docs/build.md`: en la tabla de listas, mencionar Broadcom en `30-red-firmware`; agregar una sección para grabar la ISO en una memoria USB (`lsblk`, `dd` y la aplicación Discos) y arrancarla en una Mac (tecla Option, entrada "EFI Boot"); agregar una nota de cómo quitar el bloqueo de `b43` en un sistema persistente; verificar que las rutas y los comandos citados existen

## 2. Build y comprobación de la ISO

- [x] 2.1 Hacer push a `main` y verificar que `build-iso` termina en verde con tamaño ≤ 1 000 000 000 bytes. Con la ISO descargada (según `docs/build.md`), verificar: `firmware-brcm80211` en `live/filesystem.packages`; `usr/lib/firmware/brcm/bcm43xx-0.fw` y `bcm43xx_hdr-0.fw` en el squashfs (`unsquashfs -l`); `etc/modprobe.d/mklinux-broadcom.conf` en el squashfs. Con `lsinitramfs` sobre `live/initrd.img`, verificar que, si el initrd contiene `b43.ko`, también contiene el bloqueo (Decisión 3). Anotar aquí el tamaño de la ISO, el número de paquetes y el resultado de `lsinitramfs`
  - Resultado (run 43785482423): ISO 890 241 024 bytes (antes 878 706 688; +11,5 MB), 671 paquetes, `filesystem.squashfs` 816 955 392, `initrd.img` 46 494 486. `firmware-brcm80211` `20250410-2` en `filesystem.packages`; `bcm43xx-0.fw`, `bcm43xx_hdr-0.fw` y `etc/modprobe.d/mklinux-broadcom.conf` en el squashfs. `lsinitramfs`: el initrd no contiene `b43.ko`, `brcmsmac.ko` ni `bcma.ko` (la Wi-Fi se carga desde el sistema raíz) y sí contiene `etc/modprobe.d/mklinux-broadcom.conf`.
- [x] 2.2 En `scripts/test-qemu.sh bios`, prueba rápida de no regresión: llegar al escritorio, `nmcli -t -f STATE general` → `connected`, `modprobe --showconfig | grep -w b43` → `blacklist b43` y el indicador de volumen en el panel

## 3. Aceptación en la MacBook Air 2012

- [x] 3.1 El mantenedor graba la ISO de 2.1 en una memoria USB siguiendo `docs/build.md` y arranca la MacBook Air 2012 con Option → "EFI Boot"; verificar que llega al escritorio XFCE del usuario `mk`
  - Resultado: la ISO arranca desde una memoria USB (Kingston DataTraveler 3.0) en la MacBook Air 2012 y llega al escritorio. Gráficos, rendimiento, vídeo de YouTube en Firefox y sonido funcionan bien en el hardware real.
- [x] 3.2 En esa sesión, verificar los escenarios de `live-session` "Wi-Fi Broadcom con brcmsmac": `lspci -nnk -d 14e4:4353` muestra `bcma-pci-bridge`, `lsmod` muestra `brcmsmac` y no `b43`, `nmcli device wifi list` muestra redes y la conexión a una red desde el panel deja `wifi:connected`. Anotar aquí el resultado
  - Resultado: el mantenedor eligió la red Wi-Fi de su casa en el indicador de red del panel, se conectó con su contraseña y navegó (YouTube con vídeo y sonido) sin cable ni anclaje USB. No se ejecutaron `lspci`, `lsmod` ni `nmcli`, así que no hay salida registrada de esos comandos. El driver se deduce por descarte: la ISO no trae `wl` (`broadcom-sta-dkms`) y `b43` está bloqueado y sin firmware, así que solo `brcmsmac` puede manejar la BCM43224. El mantenedor aceptó esta evidencia para cerrar la tarea.

## Workflow follow-up

- Archivar el cambio (`openspec-archive-change`) cuando la aceptación esté completa.
