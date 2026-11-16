# iso-build Specification

## Purpose

Producir la imagen ISO de MKLinux OS mediante un único script, de forma reproducible e independiente del host, igual en la máquina de desarrollo y en CI.

## Requirements

### Requirement: Build con un solo comando
El sistema SHALL proveer `scripts/build.sh`, que construye la ISO completa sin pasos manuales, ejecutando la herramienta de build dentro de un contenedor `debian:trixie`, de modo que el resultado no dependa de la distribución ni de los paquetes del host.

#### Scenario: Build exitoso en un host con Podman
- **GIVEN** un host con Podman y permisos de `sudo`
- **WHEN** el usuario ejecuta `scripts/build.sh` desde la raíz del repositorio
- **THEN** el script termina con código de salida 0
- **AND** existe un archivo ISO nuevo en `out/`

#### Scenario: Host sin Podman
- **WHEN** el usuario ejecuta `scripts/build.sh` en un host sin Podman
- **THEN** el script termina con código distinto de 0 antes de construir nada
- **AND** muestra un mensaje en español indicando que falta Podman

### Requirement: Nombre y ubicación de la ISO
La ISO resultante SHALL quedar en `out/mklinux-os-<AAAAMMDD>-amd64.iso`, donde `<AAAAMMDD>` es la fecha UTC del build.

#### Scenario: Nombre de la ISO
- **WHEN** un build termina correctamente el 14 de noviembre de 2026 (UTC)
- **THEN** la ISO está en `out/mklinux-os-20261114-amd64.iso`

#### Scenario: Rebuild el mismo día
- **GIVEN** ya existe `out/mklinux-os-<fecha>-amd64.iso` de un build anterior del mismo día
- **WHEN** se ejecuta un nuevo build exitoso
- **THEN** la ISO anterior se reemplaza por la nueva

### Requirement: Salida propiedad del usuario del host
El directorio `out/` y la ISO generada SHALL pertenecer al usuario del host que ejecutó `scripts/build.sh`, aunque el build use privilegios de root, de modo que pueda borrarlos o moverlos sin `sudo`.

#### Scenario: out/ pertenece al usuario del host tras el build
- **GIVEN** `out/` no existe antes del build
- **WHEN** un usuario sin privilegios ejecuta `scripts/build.sh` y el build termina
- **THEN** `out/` existe y su propietario es ese usuario

#### Scenario: La ISO pertenece al usuario del host
- **WHEN** un build termina correctamente
- **THEN** el propietario de `out/mklinux-os-<fecha>-amd64.iso` es el usuario que ejecutó el script
- **AND** el usuario puede borrarla con `rm` sin `sudo`

### Requirement: Build limpio en cada ejecución
Cada ejecución de `scripts/build.sh` SHALL partir de un estado de build limpio, sin reutilizar el chroot de builds anteriores, y SHALL NOT dejar archivos de trabajo del build dentro del repositorio fuera de `out/`.

#### Scenario: Repositorio intacto tras el build
- **WHEN** termina un build (exitoso o fallido)
- **THEN** `git status` solo muestra cambios en `out/` (que está ignorado por git)

### Requirement: Compresión de desarrollo y de release
Por defecto el build SHALL comprimir el sistema de archivos live con un algoritmo rápido (zstd). Cuando se pida un build de release, SHALL usar xz.

#### Scenario: Build de desarrollo
- **WHEN** se ejecuta `scripts/build.sh` sin opciones
- **THEN** el squashfs de la ISO está comprimido con zstd

#### Scenario: Build de release
- **WHEN** se ejecuta `scripts/build.sh --release`
- **THEN** el squashfs de la ISO está comprimido con xz

### Requirement: Fallo visible
Si cualquier etapa del build falla, `scripts/build.sh` SHALL terminar con código distinto de 0 y SHALL NOT dejar en `out/` una ISO incompleta con el nombre final.

#### Scenario: Fallo de descarga de paquetes
- **WHEN** el build falla porque no se puede descargar un paquete
- **THEN** el script termina con código distinto de 0
- **AND** no se crea ni se modifica `out/mklinux-os-<fecha>-amd64.iso`

### Requirement: Tamaño máximo de la ISO de desarrollo
La ISO de desarrollo (compresión zstd, sin `--release`) SHALL pesar como máximo 1 200 000 000 bytes.

#### Scenario: ISO dentro del límite
- **WHEN** termina correctamente un build de desarrollo
- **THEN** `stat -c %s out/mklinux-os-<fecha>-amd64.iso` devuelve un valor menor o igual a 1200000000

### Requirement: Contenido declarado explícitamente
La imagen SHALL instalar solo los paquetes declarados en las listas de paquetes del repositorio y sus dependencias obligatorias; los paquetes recomendados por Debian SHALL NOT instalarse de forma implícita.

#### Scenario: Recomendado no declarado
- **GIVEN** un paquete que en Debian solo llega como recomendado de otro (por ejemplo, `desktop-base`) y que no está en ninguna lista del repositorio
- **WHEN** termina un build
- **THEN** ese paquete no aparece en `live/filesystem.packages` de la ISO

#### Scenario: Recomendado declarado
- **GIVEN** un paquete que en Debian solo llega como recomendado (por ejemplo, `pulseaudio`) y que sí está en una lista del repositorio
- **WHEN** termina un build
- **THEN** ese paquete aparece en `live/filesystem.packages` de la ISO

### Requirement: Sin firmware de GPU NVIDIA
La imagen SHALL NOT incluir el paquete `firmware-nvidia-graphics`.

#### Scenario: Firmware NVIDIA ausente
- **WHEN** termina un build
- **THEN** `firmware-nvidia-graphics` no aparece en `live/filesystem.packages` de la ISO

### Requirement: Firmware Wi-Fi Broadcom
La imagen SHALL incluir el firmware que necesita el driver `brcmsmac` (paquete `firmware-brcm80211`) y SHALL impedir que el módulo `b43` se cargue automáticamente, porque su firmware no está en la imagen y bloquearía a `brcmsmac` en las tarjetas que ambos reclaman.

#### Scenario: Firmware incluido
- **WHEN** termina un build
- **THEN** `firmware-brcm80211` aparece en `live/filesystem.packages` de la ISO
- **AND** el sistema de archivos de la imagen contiene `usr/lib/firmware/brcm/bcm43xx-0.fw` y `usr/lib/firmware/brcm/bcm43xx_hdr-0.fw`

#### Scenario: b43 bloqueado
- **WHEN** se ejecuta `modprobe --showconfig | grep -w b43` en la sesión live
- **THEN** la salida incluye `blacklist b43`
