# Tasks

## 1. Referencia de la v0.1

- [x] 1.1 Guardar fuera del repo (`out/referencia-v0.1/`) el `live/filesystem.packages`, el tamaño de la ISO, de `filesystem.squashfs` y de `initrd.img` de la ISO v0.1 actual; verificar que el archivo tiene 981 líneas y que los tamaños coinciden con los de `design.md` (Context)

## 2. Listas de paquetes sin recomendados

- [x] 2.1 Cambiar `live-build/auto/config` a `--apt-recommends false`; verificar con `lb config` en un contenedor `debian:trixie` que `LB_APT_RECOMMENDS="false"`
- [x] 2.2 Reemplazar `mklinux.list.chroot` por las listas `10-base`, `20-escritorio`, `30-red-firmware`, `40-audio`, `50-idioma`, `60-aplicaciones` y `90-mklinux` de la Decisión 1 (incluida la selección de `xfce4-goodies` de la Decisión 2), con un comentario por grupo; verificar con `apt-get install --simulate --no-install-recommends` en `debian:trixie` (con `non-free-firmware`) que todo resuelve y que `firmware-nvidia-graphics`, `desktop-base` y `task-spanish` no entran
- [x] 2.3 Actualizar `docs/build.md` con una sección "Qué incluye la ISO y cómo agregar paquetes" (listas por función, sin recomendados, cómo instalar el firmware NVIDIA en la sesión live); verificar que los nombres de archivos y comandos citados existen

## 3. Control de tamaño y contenido en CI

- [x] 3.1 Agregar a `build-iso.yml` el paso "Verificar tamaño y contenido" de la Decisión 5 (`MAX_ISO_BYTES=1000000000`, resumen en `$GITHUB_STEP_SUMMARY`, fallo si se supera el límite, si aparecen `firmware-nvidia-graphics` o `desktop-base`, o si falta `pulseaudio`); verificar con `actionlint` y ejecutando la lógica del paso en local contra la ISO v0.1, donde debe fallar por tamaño y por `desktop-base`
- [ ] 3.2 Hacer push a `main` y verificar que el workflow termina en verde, que el resumen muestra tamaño ≤ 1 000 000 000 bytes, y anotar en esta tarea tamaño de ISO, `filesystem.squashfs`, `initrd.img` y número de paquetes

## 4. Revisión de lo eliminado

- [ ] 4.1 Comparar con `comm` el `filesystem.packages` de la ISO nueva con la referencia de 1.1 y revisar los paquetes eliminados que no son librerías; para cada uno con función visible, volver a declararlo o anotar aquí por qué se acepta su ausencia; verificar que no queda ninguno sin decidir

## 5. Aceptación en QEMU

- [ ] 5.1 Descargar la ISO de CI (según `docs/build.md`) y, en `scripts/test-qemu.sh bios`, verificar los escenarios previos de `live-session` y `os-identity` (llegada al escritorio, `mk`, `sudo`, `hostname`, `locale`, `latam`, `-05`, `os-release`)
- [ ] 5.2 En la misma sesión BIOS, verificar los escenarios nuevos de `live-session`: `pactl info`, indicadores de volumen y red en el panel, `nmcli -t -f STATE general` → `connected`, `nmcli general permissions` (network-control y enable-disable-wifi en `yes`), `gio trash` + `gio list trash://`, `udisksctl status`, `xdg-open https://www.debian.org` abre Firefox, menú en español y `aspell -l es list` → `kasa`
- [ ] 5.3 Repetir 5.1 y 5.2 con `scripts/test-qemu.sh uefi`

## Workflow follow-up

- Archivar el cambio (`openspec-archive-change`) cuando la aceptación en QEMU esté completa, para incorporar los requisitos nuevos a los specs principales.
