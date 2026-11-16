# Proposal: iso-size

## Why

La v0.1 instala los paquetes recomendados de Debian y pesa 1,2 GB (2,36 GB instalados). Unos 714 MB instalados entran solo como "recomendados", muchos sin uso en una estación de desarrollo, y el firmware de GPUs NVIDIA engorda también el initrd (104 MB). Cada descarga de CI tarda ~25 minutos con la conexión de desarrollo; una ISO más pequeña acelera las pruebas de este cambio y de los siguientes (instalador, herramientas de IA).

## What Changes

- El build deja de instalar paquetes recomendados: todo lo que va en la imagen se declara en listas de paquetes explícitas, agrupadas por función.
- Se vuelven a declarar explícitamente las piezas que hoy solo llegan como recomendadas y que la sesión live necesita: audio, agente y servicio polkit (gestión de red como usuario), montaje de memorias USB y papelera, energía, fuentes, iconos, corrector ortográfico en español, apertura de enlaces y directorios de usuario.
- Se quita el firmware de GPUs NVIDIA y otros paquetes sin uso en la sesión live (por ejemplo, tema `desktop-base`, escáneres SANE, módem, Plymouth).
- La ISO de desarrollo (zstd) debe pesar como máximo 1,0 GB (1 000 000 000 bytes).
- CI informa el tamaño de cada ISO y falla si supera el máximo.
- Se hace explícito, como requisito verificable, el conjunto mínimo de funciones de la sesión live que ninguna optimización puede quitar.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `iso-build`: nuevo requisito de tamaño máximo de la ISO de desarrollo y de construcción sin paquetes recomendados.
- `live-session`: nuevos requisitos con las funciones mínimas de la sesión live (audio, red y Wi-Fi gestionables por el usuario, archivos y medios extraíbles, navegador, español).
- `ci-iso-build`: nuevo requisito de control de tamaño en CI.

## Impact

- Archivos: `live-build/auto/config` (`--apt-recommends false`), `live-build/config/package-lists/` (lista única reemplazada por varias listas por función), `.github/workflows/build-iso.yml` (paso de control de tamaño), `docs/build.md` (tamaño y cómo agregar paquetes).
- Equipos con GPU NVIDIA reciente arrancan con gráficos básicos (sin firmware para nouveau); se puede instalar el firmware después.
- Paquetes que hoy aparecen en la sesión live pueden desaparecer si no están en las listas; la lista de comprobación en QEMU se amplía para detectarlo.
- Riesgo de regresiones invisibles en el build (algo que falta solo se nota al usarlo): se mitiga con los nuevos requisitos de `live-session` y su verificación en QEMU.
