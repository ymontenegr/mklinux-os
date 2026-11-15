# Tasks

## 1. Referencia de la v0.1

- [x] 1.1 Guardar fuera del repo (`out/referencia-v0.1/`) el `live/filesystem.packages`, el tamaño de la ISO, de `filesystem.squashfs` y de `initrd.img` de la ISO v0.1 actual; verificar que el archivo tiene 981 líneas y que los tamaños coinciden con los de `design.md` (Context)

## 2. Listas de paquetes sin recomendados

- [x] 2.1 Cambiar `live-build/auto/config` a `--apt-recommends false`; verificar con `lb config` en un contenedor `debian:trixie` que `LB_APT_RECOMMENDS="false"`
- [x] 2.2 Reemplazar `mklinux.list.chroot` por las listas `10-base`, `20-escritorio`, `30-red-firmware`, `40-audio`, `50-idioma`, `60-aplicaciones` y `90-mklinux` de la Decisión 1 (incluida la selección de `xfce4-goodies` de la Decisión 2), con un comentario por grupo; verificar con `apt-get install --simulate --no-install-recommends` en `debian:trixie` (con `non-free-firmware`) que todo resuelve y que `firmware-nvidia-graphics`, `desktop-base` y `task-spanish` no entran
- [x] 2.3 Actualizar `docs/build.md` con una sección "Qué incluye la ISO y cómo agregar paquetes" (listas por función, sin recomendados, cómo instalar el firmware NVIDIA en la sesión live); verificar que los nombres de archivos y comandos citados existen

## 3. Control de tamaño y contenido en CI

- [x] 3.1 Agregar a `build-iso.yml` el paso "Verificar tamaño y contenido" de la Decisión 5 (`MAX_ISO_BYTES=1000000000`, resumen en `$GITHUB_STEP_SUMMARY`, fallo si se supera el límite, si aparecen `firmware-nvidia-graphics` o `desktop-base`, o si falta `pulseaudio`); verificar con `actionlint` y ejecutando la lógica del paso en local contra la ISO v0.1, donde debe fallar por tamaño y por `desktop-base`
- [x] 3.2 Hacer push a `main` y verificar que el workflow termina en verde, que el resumen muestra tamaño ≤ 1 000 000 000 bytes, y anotar en esta tarea tamaño de ISO, `filesystem.squashfs`, `initrd.img` y número de paquetes
  - Resultado (run 43742980112): ISO 860 880 896 bytes (v0.1: 1 225 752 576), `filesystem.squashfs` 785 821 696 (v0.1: 1 094 828 032), `initrd.img` 48 460 163 (v0.1: 104 116 037), 626 paquetes (v0.1: 981).

## 4. Revisión de lo eliminado

- [x] 4.1 Comparar con `comm` el `filesystem.packages` de la ISO nueva con la referencia de 1.1 y revisar los paquetes eliminados que no son librerías; para cada uno con función visible, volver a declararlo o anotar aquí por qué se acepta su ausencia; verificar que no queda ninguno sin decidir
  - Comparación: 357 paquetes eliminados (135 no son librerías ni datos), 2 nuevos (`firefox-esr-l10n-es-mx`, `hunspell-es`).
  - Vueltos a declarar (funciones de la v0.1 que solo llegaban como recomendados): `user-setup`, `live-tools`, `apparmor`, `ca-certificates`, `man-db`, `unzip`, `xz-utils`, `zstd`, `bzip2`, `rsync`, `ntfs-3g`, `dosfstools`, `exfatprogs`, `xarchiver`, `tumbler`, `xfce4-power-manager-plugins`, `glib-networking`, `wireless-regdb`, `firmware-ath9k-htc`, `firmware-carl9170`, `rtkit` y, por decisión del mantenedor, la aceleración de vídeo (`intel-media-va-driver`, `i965-va-driver`, `mesa-va-drivers`, `mesa-vdpau-drivers`).
  - Ausencia aceptada por el mantenedor: `gnome-keyring` (llavero), ModemManager/`ppp` (módem 3G/4G).
  - Ausencia aceptada, prevista en el diseño o sin uso en la sesión live: `desktop-base`, Plymouth, SANE, `task-spanish`/`manpages-es`/`debian-reference-es`/`tasksel`, componentes de `xfce4-goodies` no seleccionados, `firmware-nvidia-graphics`, `light-locker` (sesión sin contraseña), drivers Xorg `intel`/`qxl` y `xserver-xorg-legacy` (los cubre `modesetting`), `mesa-vulkan-drivers`, corrector en inglés, temas de iconos adicionales, `7zip`, `lm-sensors`, `colord`/`xiccd`, `avahi-daemon`, `x11-apps`/`x11-utils`/`xinit`/`xauth`, `xfonts-75dpi`/`100dpi`/`scalable`, Qt (`qt5-gtk-platformtheme`, `qtwayland5`).

## 5. Aceptación en QEMU

- [ ] 5.1 Descargar la ISO de CI (según `docs/build.md`) y, en `scripts/test-qemu.sh bios`, verificar los escenarios previos de `live-session` y `os-identity` (llegada al escritorio, `mk`, `sudo`, `hostname`, `locale`, `latam`, `-05`, `os-release`)
- [ ] 5.2 En la misma sesión BIOS, verificar los escenarios nuevos de `live-session`: `pactl info`, indicadores de volumen y red en el panel, `nmcli -t -f STATE general` → `connected`, `nmcli general permissions` (network-control y enable-disable-wifi en `yes`), `gio trash` + `gio list trash://`, `udisksctl status`, `xdg-open https://www.debian.org` abre Firefox, menú en español y `aspell -l es list` → `kasa`
  - Primera prueba (ISO del run 43747281911, 876 609 536 bytes, 668 paquetes): pasan identidad, `mk`, `sudo`, hostname, idioma, teclado, zona, `pactl info` (servidor `pulseaudio`; sumidero `auto_null` porque la VM no tiene tarjeta de sonido), red y permisos, `udisksctl`, Firefox con `xdg-open`, menú en español y `aspell`. Fallan: `gio` no existe (llegaba como recomendado en `libglib2.0-bin`) y el panel no muestra el indicador de volumen (el panel por defecto de `xfce4-panel` no incluye el plugin). Arreglos: declarar `libglib2.0-bin` y configuración del panel propia con el plugin `pulseaudio` (probado en vivo con `xfconf-query`). Pendiente repetir la prueba con la ISO nueva.
- [ ] 5.3 Repetir 5.1 y 5.2 con `scripts/test-qemu.sh uefi`

## Workflow follow-up

- Archivar el cambio (`openspec-archive-change`) cuando la aceptación en QEMU esté completa, para incorporar los requisitos nuevos a los specs principales.
