# Proposal: iso-base

## Why

MKLinux OS todavía no tiene una forma de producir una imagen arrancable. Antes de agregar el diferencial (herramientas de desarrollo con IA, instalador) hace falta una ISO mínima, construida 100 % por script y de forma reproducible en local y en CI, que sirva de base y de banco de pruebas para todos los cambios posteriores.

## What Changes

- Nuevo `scripts/build.sh`: ejecuta live-build dentro de un contenedor Podman `debian:trixie` (privilegiado) y deja la imagen en `out/mklinux-os-<AAAAMMDD>-amd64.iso`.
- Nueva configuración de live-build en `live-build/`: Debian 13 "trixie" amd64, escritorio XFCE con LightDM, sesión live con el usuario `mk`, idioma `es_CO.UTF-8`, teclado `latam` y zona horaria `America/Bogota`. Arranca en BIOS y en UEFI e incluye firmware y `wpasupplicant` para Wi-Fi y hardware común.
- Nuevo paquete propio `mklinux-identity` (en `packages/`): instala la identidad de MKLinux OS en `/etc/os-release` sin modificar los paquetes de Debian.
- Nuevo `scripts/test-qemu.sh`: arranca la ISO en QEMU con KVM y 1536 MB de RAM, en modo BIOS o UEFI (OVMF).
- Nuevo flujo `.github/workflows/build-iso.yml`: construye la ISO en cada push a `main` y la publica como artifact del workflow.
- Documentación en español de cómo construir y probar la ISO.

## Capabilities

### New Capabilities

- `iso-build`: construcción reproducible de la ISO por script dentro de un contenedor, con nombre y ubicación de salida definidos y compresión rápida o de release.
- `live-session`: comportamiento de la sesión live al arrancar la ISO: cargadores BIOS/UEFI, escritorio XFCE con LightDM, usuario `mk`, idioma, teclado y zona horaria.
- `os-identity`: identidad del sistema expuesta en `/etc/os-release` (`NAME="MKLinux OS"`, `ID=mklinux`, `ID_LIKE=debian`).
- `vm-testing`: arranque de la ISO en una máquina virtual local en modo BIOS y UEFI, dentro de los límites de la máquina de desarrollo.
- `ci-iso-build`: construcción automática de la ISO en GitHub Actions y publicación como artifact.

### Modified Capabilities

Ninguna (no existen specs previos).

## Impact

- Repositorio público en GitHub, conectado como remote `origin` del repo local; el código, los logs de CI y los artifacts quedan visibles públicamente.
- Archivos nuevos: `scripts/build.sh`, `scripts/test-qemu.sh`, `live-build/**`, `packages/mklinux-identity/**`, `.github/workflows/build-iso.yml`, `docs/build.md`, `.gitignore` (excluye `out/`).
- Dependencias del host de desarrollo: Podman (con `sudo`, porque live-build necesita un contenedor privilegiado con permisos de root reales), QEMU con KVM y OVMF.
- CI: usa runners `ubuntu-24.04` de GitHub y es donde se hace el primer build completo; la ISO (~2–2,5 GB, sin optimizar tamaño en v0.1) consume espacio de artifacts con retención limitada.
- Criterio de aceptación: la ISO arranca en QEMU hasta el escritorio XFCE (en BIOS y en UEFI) y `cat /etc/os-release` muestra `NAME="MKLinux OS"`.
