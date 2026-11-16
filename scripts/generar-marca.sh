#!/bin/bash
# Genera las imágenes provisionales de la marca de Calamares de MKLinux OS
# (logo, imagen de bienvenida y presentación) en
# packages/mklinux-calamares-settings/etc/calamares/branding/mklinux/.
#
# Requiere ImageMagick y fuentes DejaVu. Sin ellas en el host, se puede
# ejecutar en un contenedor:
#   podman run --rm -v "$PWD:/src" -w /src docker.io/library/debian:trixie \
#     bash -c 'apt-get update -qq && apt-get install -y -qq imagemagick fonts-dejavu-core >/dev/null && scripts/generar-marca.sh'
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="${repo}/packages/mklinux-calamares-settings/etc/calamares/branding/mklinux"
mkdir -p "${dest}"

command -v convert >/dev/null 2>&1 || { echo "Error: falta ImageMagick (convert)." >&2; exit 1; }
bold=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
regular=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
[ -f "${bold}" ] && [ -f "${regular}" ] || { echo "Error: faltan las fuentes DejaVu (fonts-dejavu-core)." >&2; exit 1; }

fondo="#1e3a5f"

# Logo: cuadrado redondeado con "MK".
convert -size 256x256 xc:none -fill "${fondo}" -draw "roundrectangle 8,8 247,247 40,40" \
    -font "${bold}" -pointsize 110 -fill white -gravity center -annotate +0+0 "MK" \
    -strip "${dest}/logo.png"

# Bienvenida: logo y nombre.
convert -size 600x260 xc:none \
    \( "${dest}/logo.png" -resize 140x140 \) -gravity north -geometry +0+10 -composite \
    -font "${bold}" -pointsize 40 -fill "${fondo}" -gravity south -annotate +0+40 "MKLinux OS" \
    -font "${regular}" -pointsize 18 -fill "#555555" -gravity south -annotate +0+10 "Estación de trabajo para desarrolladores con IA" \
    -strip "${dest}/bienvenida.png"

# Presentación durante la instalación.
diapositiva() {
    local salida="$1" titulo="$2" texto="$3"
    convert -size 800x440 xc:"${fondo}" \
        \( "${dest}/logo.png" -resize 96x96 \) -gravity northwest -geometry +40+40 -composite \
        -font "${bold}" -pointsize 34 -fill white -gravity northwest -annotate +160+60 "${titulo}" \
        -font "${regular}" -pointsize 22 -fill "#dfe8f0" -gravity northwest -interline-spacing 8 \
        -annotate +40+180 "${texto}" \
        -strip "${dest}/${salida}"
}
diapositiva diapositiva1.png "Bienvenido a MKLinux OS" \
    "Basado en Debian 13 «trixie», con escritorio XFCE.\nEn unos minutos tendrás tu estación de trabajo lista."
diapositiva diapositiva2.png "Tu sistema, actualizado" \
    "Usa los repositorios oficiales de Debian:\nmantén el sistema al día con «sudo apt update»\ny «sudo apt upgrade»."

ls -l "${dest}"/*.png
