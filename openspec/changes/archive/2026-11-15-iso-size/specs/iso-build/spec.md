# Spec Delta

## ADDED Requirements

### Requirement: Tamaño máximo de la ISO de desarrollo
La ISO de desarrollo (compresión zstd, sin `--release`) SHALL pesar como máximo 1 000 000 000 bytes.

#### Scenario: ISO dentro del límite
- **WHEN** termina correctamente un build de desarrollo
- **THEN** `stat -c %s out/mklinux-os-<fecha>-amd64.iso` devuelve un valor menor o igual a 1000000000

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
