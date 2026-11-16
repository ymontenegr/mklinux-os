#!/bin/bash
# Arranca una ISO de MKLinux OS en QEMU con KVM: sesión live o, con un disco
# virtual, instalación y arranque del sistema instalado.
#
# Uso: scripts/test-qemu.sh {bios|uefi} [--disco [--sin-iso]] [--sin-red] [ISO]
#   Sin ISO, usa la más reciente de out/.
#   --disco    conecta out/mklinux-disco-<modo>.qcow2 (20 GB, se crea vacío si
#              no existe); en uefi, sus variables UEFI se guardan junto a él.
#   --sin-iso  arranca solo desde el disco (requiere --disco).
#   --sin-red  sin tarjeta de red.
#   OVMF_CODE y OVMF_VARS permiten indicar otro firmware UEFI.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    echo "Uso: $0 {bios|uefi} [--disco [--sin-iso]] [--sin-red] [ISO]"
    echo "  Sin ISO, usa la más reciente de out/."
    echo "  --disco    conecta el disco virtual out/mklinux-disco-<modo>.qcow2 (20 GB)."
    echo "  --sin-iso  arranca solo desde el disco (requiere --disco)."
    echo "  --sin-red  arranca la VM sin tarjeta de red."
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

shift
disco=false
sin_iso=false
sin_red=false
iso=""
for arg in "$@"; do
    case "${arg}" in
        --disco) disco=true ;;
        --sin-iso) sin_iso=true ;;
        --sin-red) sin_red=true ;;
        -*) echo "Error: opción desconocida '${arg}'." >&2; usage >&2; exit 2 ;;
        *)
            [ -z "${iso}" ] || { echo "Error: indica una sola ISO." >&2; usage >&2; exit 2; }
            iso="${arg}"
            ;;
    esac
done
if "${sin_iso}" && ! "${disco}"; then
    echo "Error: --sin-iso solo tiene sentido con --disco (no habría nada que arrancar)." >&2
    usage >&2
    exit 2
fi
if "${sin_iso}" && [ -n "${iso}" ]; then
    echo "Error: --sin-iso no admite una ISO." >&2
    usage >&2
    exit 2
fi

if "${sin_iso}"; then
    :
elif [ -n "${iso}" ]; then
    [ -f "${iso}" ] || fail "no existe la ISO '${iso}'."
else
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
    -vga virtio -display gtk
    -name "MKLinux OS (${mode})"
)

if "${sin_red}"; then
    args+=(-nic none)
else
    args+=(-device "virtio-net-pci,netdev=n0" -netdev "user,id=n0")
fi

disco_img="${repo}/out/mklinux-disco-${mode}.qcow2"
if "${disco}"; then
    command -v qemu-img >/dev/null 2>&1 \
        || fail "no se encontró qemu-img. Instálalo con 'sudo apt install qemu-utils'."
    if [ ! -f "${disco_img}" ]; then
        mkdir -p "${repo}/out"
        echo "==> Creando el disco virtual ${disco_img} (20 GB, crece según se usa)"
        qemu-img create -q -f qcow2 "${disco_img}" 20G
    fi
    args+=(-drive "file=${disco_img},if=virtio,format=qcow2")
fi

if "${sin_iso}"; then
    args+=(-boot order=c)
elif "${disco}"; then
    # La ISO primero; si no arranca, el disco.
    args+=(-cdrom "${iso}" -boot order=dc)
else
    args+=(-cdrom "${iso}" -boot d)
fi

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

    # Copia propia de las variables UEFI: no se modifican los archivos del
    # sistema. Con --disco se conserva junto al disco, para que la entrada de
    # arranque del sistema instalado sobreviva entre ejecuciones.
    if "${disco}"; then
        vars_copia="${repo}/out/mklinux-disco-uefi.vars.fd"
        [ -f "${vars_copia}" ] || cp "${vars}" "${vars_copia}"
    else
        tmp="$(mktemp -d)"
        trap 'rm -rf "${tmp}"' EXIT
        vars_copia="${tmp}/OVMF_VARS.fd"
        cp "${vars}" "${vars_copia}"
    fi
    args+=(
        -drive "if=pflash,format=raw,readonly=on,file=${code}"
        -drive "if=pflash,format=raw,file=${vars_copia}"
    )
fi

# Si se lanza desde una app snap (p. ej. la terminal de VS Code), sus variables
# de GTK/GIO apuntan a /snap/... y hacen abortar la interfaz GTK de QEMU.
if [ -n "${SNAP:-}" ]; then
    unset GDK_PIXBUF_MODULEDIR GDK_PIXBUF_MODULE_FILE GIO_MODULE_DIR \
        GSETTINGS_SCHEMA_DIR GTK_EXE_PREFIX GTK_IM_MODULE_FILE GTK_PATH LOCPATH
    XDG_DATA_DIRS="$(printf '%s' "${XDG_DATA_DIRS:-}" | tr ':' '\n' | grep -v '/snap/' | paste -sd ':' -)"
    export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
fi

if "${sin_iso}"; then
    echo "==> Arrancando el disco ${disco_img} en modo ${mode} (1536 MB, KVM)"
elif "${disco}"; then
    echo "==> Arrancando ${iso} en modo ${mode} con el disco ${disco_img} (1536 MB, KVM)"
else
    echo "==> Arrancando ${iso} en modo ${mode} (1536 MB, KVM)"
fi
qemu-system-x86_64 "${args[@]}"
