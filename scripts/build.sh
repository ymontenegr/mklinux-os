#!/bin/bash
# Construye la ISO de MKLinux OS dentro de un contenedor Podman debian:trixie.
# Resultado: out/mklinux-os-<AAAAMMDD>-amd64.iso
#
# Uso: scripts/build.sh [--release]
#   --release  comprime el sistema live con xz (por defecto: zstd)
set -euo pipefail

image=docker.io/library/debian:trixie
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    echo "Uso: $0 [--release]"
    echo "  --release  comprime el sistema live con xz (por defecto: zstd)"
}

release=0
for arg in "$@"; do
    case "${arg}" in
        --release) release=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Error: opción desconocida: ${arg}" >&2; usage >&2; exit 2 ;;
    esac
done

if ! command -v podman >/dev/null 2>&1; then
    echo "Error: no se encontró Podman. Instálalo con 'sudo apt install podman' y vuelve a intentarlo." >&2
    exit 1
fi

# out/ se crea como el usuario del host ANTES de usar sudo; si lo creara
# Podman al montarlo, quedaría propiedad de root.
mkdir -p "${repo}/out"

# live-build necesita root real (debootstrap crea nodos de dispositivo y
# monta proc/sys/dev); Podman rootless no basta.
podman_cmd=(podman)
if [ "$(id -u)" -ne 0 ]; then
    echo "==> live-build necesita root real: se usará 'sudo podman'"
    podman_cmd=(sudo podman)
fi

build_date="$(date -u +%Y%m%d)"
echo "==> Construyendo out/mklinux-os-${build_date}-amd64.iso (release=${release})"

"${podman_cmd[@]}" run --rm --privileged \
    -v "${repo}:/src:ro" \
    -v "${repo}/out:/out" \
    -e BUILD_DATE="${build_date}" \
    -e MKLINUX_RELEASE="${release}" \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    "${image}" \
    bash /src/scripts/container-build.sh
