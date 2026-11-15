#!/bin/bash
# Construye la ISO de MKLinux OS. Se ejecuta DENTRO del contenedor
# debian:trixie que lanza scripts/build.sh; no ejecutar directamente en el host.
#
# Entradas (variables de entorno):
#   BUILD_DATE        fecha UTC AAAAMMDD para el nombre de la ISO (obligatoria)
#   HOST_UID/HOST_GID propietario final de la ISO en el host (obligatorias)
#   MKLINUX_RELEASE   1 para compresión xz (opcional)
# Montajes: /src (repositorio, solo lectura) y /out (salida).
set -euo pipefail

: "${BUILD_DATE:?falta BUILD_DATE}"
: "${HOST_UID:?falta HOST_UID}"
: "${HOST_GID:?falta HOST_GID}"
export BUILD_DATE MKLINUX_RELEASE="${MKLINUX_RELEASE:-0}"

src=/src
out=/out
work=/build
iso_name="mklinux-os-${BUILD_DATE}-amd64.iso"
partial="${out}/.${iso_name}.partial"

trap 'rm -f "${partial}"' EXIT

echo "==> Instalando live-build"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y live-build ca-certificates

echo "==> Preparando el directorio de trabajo ${work}"
rm -rf "${work}"
cp -a "${src}/live-build" "${work}"
mkdir -p "${work}/config/packages.chroot"

echo "==> Construyendo paquetes propios"
for pkg in "${src}"/packages/mklinux-*/; do
    tmp="$(mktemp -d)"
    cp -a "${pkg}." "${tmp}/"
    # Permisos normalizados: el umask del host no debe llegar a la imagen.
    chmod -R u=rwX,go=rX "${tmp}"
    find "${tmp}/DEBIAN" -type f \( -name preinst -o -name postinst -o -name prerm -o -name postrm \) -exec chmod 0755 {} +
    # Destino = directorio: dpkg-deb usa el nombre <paquete>_<versión>_<arq>.deb,
    # el único patrón que live-build reconoce en packages.chroot.
    dpkg-deb --root-owner-group --build "${tmp}" "${work}/config/packages.chroot/"
    rm -rf "${tmp}"
done

echo "==> lb config"
cd "${work}"
lb config

echo "==> lb build"
lb build

iso="${work}/mklinux-os-amd64.hybrid.iso"
if [ ! -f "${iso}" ]; then
    echo "Error: lb build terminó sin generar ${iso}" >&2
    exit 1
fi

echo "==> Copiando la ISO a out/"
cp "${iso}" "${partial}"
chown "${HOST_UID}:${HOST_GID}" "${partial}"
mv -f "${partial}" "${out}/${iso_name}"

echo "==> ISO lista: out/${iso_name}"
