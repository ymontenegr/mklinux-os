#!/bin/bash
# Arranca una ISO de MKLinux OS en QEMU con KVM (sesión live, sin disco).
#
# Uso: scripts/test-qemu.sh {bios|uefi} [ISO]
#   Sin ISO, usa la más reciente de out/.
#   OVMF_CODE y OVMF_VARS permiten indicar otro firmware UEFI.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    echo "Uso: $0 {bios|uefi} [ISO]"
    echo "  Sin ISO, usa la más reciente de out/."
}

fail() {
    echo "Error: $*" >&2
    exit 1
}

mode="${1:-}"
case "${mode}" in
    bios|uefi) ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Error: modo inválido '${mode}' (debe ser bios o uefi)." >&2; usage >&2; exit 2 ;;
esac

if [ -n "${2:-}" ]; then
    iso="$2"
    [ -f "${iso}" ] || fail "no existe la ISO '${iso}'."
else
    iso=""
    for f in "${repo}"/out/*.iso; do
        if [ -f "${f}" ] && { [ -z "${iso}" ] || [ "${f}" -nt "${iso}" ]; }; then
            iso="${f}"
        fi
    done
    [ -n "${iso}" ] || fail "no hay ninguna ISO en out/. Ejecuta primero scripts/build.sh o descarga la ISO de CI (ver docs/build.md)."
fi

command -v qemu-system-x86_64 >/dev/null 2>&1 \
    || fail "no se encontró QEMU. Instálalo con 'sudo apt install qemu-system-x86'."

if [ ! -e /dev/kvm ]; then
    fail "/dev/kvm no existe. Activa la virtualización (VT-x) en el firmware del equipo y carga el módulo con 'sudo modprobe kvm_intel'."
fi
if [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; then
    fail "tu usuario no tiene acceso a /dev/kvm. Ejecuta 'sudo usermod -aG kvm $USER' y vuelve a iniciar sesión."
fi

args=(
    -enable-kvm -cpu host -smp 2 -m 1536
    -cdrom "${iso}" -boot d
    -vga virtio -display gtk
    -device "virtio-net-pci,netdev=n0" -netdev "user,id=n0"
    -name "MKLinux OS (${mode})"
)

if [ "${mode}" = "uefi" ]; then
    code="${OVMF_CODE:-}"
    vars="${OVMF_VARS:-}"
    if [ -z "${code}" ]; then
        for c in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd; do
            if [ -f "${c}" ]; then code="${c}"; break; fi
        done
    fi
    if [ -z "${vars}" ]; then
        for v in /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd; do
            if [ -f "${v}" ]; then vars="${v}"; break; fi
        done
    fi
    [ -n "${code}" ] && [ -f "${code}" ] && [ -n "${vars}" ] && [ -f "${vars}" ] \
        || fail "no se encontró el firmware OVMF. Instálalo con 'sudo apt install ovmf' o indica OVMF_CODE y OVMF_VARS."

    # Copia propia de las variables UEFI: no se modifican los archivos del sistema.
    tmp="$(mktemp -d)"
    trap 'rm -rf "${tmp}"' EXIT
    cp "${vars}" "${tmp}/OVMF_VARS.fd"
    args+=(
        -drive "if=pflash,format=raw,readonly=on,file=${code}"
        -drive "if=pflash,format=raw,file=${tmp}/OVMF_VARS.fd"
    )
fi

echo "==> Arrancando ${iso} en modo ${mode} (1536 MB, KVM)"
qemu-system-x86_64 "${args[@]}"
