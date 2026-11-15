# Design

## Context

Ver `proposal.md` (Why). Estado medido en la ISO de v0.1 (`mklinux-os-20261115-amd64.iso`, 1 225 752 576 bytes):

- 981 paquetes en `filesystem.packages` (887 si se simula solo la lista sobre un `debian:trixie` mínimo), 2 357 MB instalados; `filesystem.squashfs` 1 095 MB (zstd), `initrd.img` 104 MB, `vmlinuz` 12 MB.
- En la simulación, con `--apt-recommends false` la misma lista resuelve 514 paquetes en lugar de 887: los 373 de diferencia (~714 MB instalados) entran solo como recomendados.
- Los mayores recomendados: `mesa-vulkan-drivers` (79 MB), `firmware-nvidia-graphics` (63), `firmware-mediatek` (45), `firmware-intel-graphics` (28), `desktop-base` (21), `intel-media-va-driver` (17), códecs de vídeo (`libx265`, `libavcodec`, `libcodec2`, ~49), GTK 4 (~37), `qttranslations5-l10n` (15), `gnome-icon-theme` (15), SANE (~13), Plymouth.
- Recomendados que la sesión live sí necesita: `pulseaudio`, `alsa-ucm-conf`, `alsa-topology-conf`, `polkitd`, `mate-polkit` (agente polkit), `gvfs`, `udisks2`, `thunar-volman`, `upower`, `xfce4-power-manager`, `at-spi2-core`, `xdg-utils`, `xdg-user-dirs`, `libnotify-bin`, `xfonts-base`, `tango-icon-theme`, `aspell-es`, firmware Intel/MediaTek.
- `firmware-misc-nonfree` solo *recomienda* los firmware de GPU NVIDIA, Intel y MediaTek: sin recomendados no llegan salvo que se declaren.
- `task-spanish` trae `tasksel`, `manpages-es`, `debian-reference-es`, diccionarios y `util-linux-locales`; casi nada se usa en la sesión live.

Los requisitos nuevos están en `specs/`.

## Goals / Non-Goals

**Goals:**

- ISO de desarrollo ≤ 1 000 000 000 bytes sin perder ninguna función listada en `live-session`.
- Que el contenido de la imagen sea legible y revisable: cada paquete está en una lista con su motivo.
- Que CI detecte regresiones de tamaño y de contenido sin pasos manuales.

**Non-Goals:**

- Quitar Firefox (294 MB) o cambiar de navegador.
- Cambiar PulseAudio por PipeWire u otras decisiones de pila (fuera de alcance: solo se declara lo que ya funciona).
- Reducir el tamaño de la ISO de release (xz); se beneficia igual, pero no tiene límite propio.
- Ajustes del kernel o del initramfs más allá de lo que cambia al quitar firmware.

## Decisions

### 1. `--apt-recommends false` + listas explícitas por función

En `auto/config` se cambia a `--apt-recommends false`. La lista única `mklinux.list.chroot` se reemplaza por varias, numeradas para que el orden de lectura sea estable:

| Archivo | Contenido |
|---|---|
| `10-base.list.chroot` | `live-boot`, `live-config`, `live-config-systemd`, `sudo`, `polkitd`, `locales`, `keyboard-configuration`, `console-setup` |
| `20-escritorio.list.chroot` | `xfce4`, `xfce4-terminal`, `lightdm`, `lightdm-gtk-greeter`, `xserver-xorg-core`, `xserver-xorg-input-all`, `xserver-xorg-video-all`, `mate-polkit`, `gvfs`, `udisks2`, `thunar-volman`, `upower`, `xfce4-power-manager`, `xfce4-notifyd`, `libnotify-bin`, `at-spi2-core`, `xdg-utils`, `xdg-user-dirs`, `xfonts-base`, `tango-icon-theme` y una selección de `xfce4-goodies` (decisión 2) |
| `30-red-firmware.list.chroot` | `network-manager-gnome`, `wpasupplicant`, `firmware-linux-free`, `firmware-misc-nonfree`, `firmware-intel-graphics`, `firmware-intel-misc`, `firmware-mediatek`, `firmware-iwlwifi`, `firmware-realtek` |
| `40-audio.list.chroot` | `pulseaudio`, `alsa-ucm-conf`, `alsa-topology-conf`, `pavucontrol`, `xfce4-pulseaudio-plugin` |
| `50-idioma.list.chroot` | `aspell-es`, `hunspell-es`, `firefox-esr-l10n-es-mx` (Firefox en español latinoamericano) |
| `60-aplicaciones.list.chroot` | `firefox-esr` |
| `90-mklinux.list.chroot` | `mklinux-identity` |

Cada lista lleva un comentario de una línea por grupo explicando por qué está ahí. Alternativa descartada: mantener los recomendados y excluir paquetes concretos. live-build no tiene un mecanismo limpio de exclusión (habría que purgar en un hook), y la lista de lo que *no* se quiere crece con cada versión de Debian.

La lista anterior es el punto de partida; la tabla es la propuesta inicial y se ajusta durante la implementación solo cuando una verificación de `live-session` lo exija (cada ajuste se anota en `tasks.md`).

### 2. Selección de `xfce4-goodies`

El metapaquete trae 30 componentes. Se mantienen los que un desarrollador usa en el día a día y que hoy están en el panel o el menú: `mousepad`, `ristretto`, `thunar-archive-plugin`, `xfce4-screenshooter`, `xfce4-taskmanager`, `xfce4-whiskermenu-plugin`, `xfce4-xkb-plugin`, `xfce4-clipman-plugin`, `xfce4-systemload-plugin`. Se quitan `xfburn`, `xfce4-dict`, `xfce4-mailwatch-plugin`, `xfce4-weather-plugin`, `xfce4-notes-plugin`, `thunar-media-tags-plugin`, sensores y monitores de batería/red redundantes con `xfce4-power-manager` y `network-manager-gnome`.

### 3. `task-spanish` fuera

Se reemplaza por lo que la sesión live usa: diccionarios (`aspell-es`, `hunspell-es`) y la traducción de Firefox. Las traducciones de XFCE y GTK vienen dentro de sus propios paquetes, así que la interfaz sigue en español. `manpages-es`, `debian-reference-es` y `tasksel` no se incluyen.

### 4. Firmware

`firmware-misc-nonfree` se mantiene (firmware variado de uso común) y, sin recomendados, ya no arrastra los de GPU. Se declaran explícitamente `firmware-intel-graphics` y `firmware-intel-misc` (GPU y audio SOF de portátiles Intel recientes) y `firmware-mediatek` (Wi-Fi MT7921/MT7922, común en portátiles AMD). `firmware-nvidia-graphics` no se declara (decisión del mantenedor). Al salir del initramfs el firmware NVIDIA, el `initrd.img` también se reduce.

### 5. Comprobaciones en CI

En `build-iso.yml`, entre "Verificar la identidad en la ISO" y la suma SHA-256, un paso "Verificar tamaño y contenido":

- Monta la ISO por su cuenta (independiente del paso de identidad, para que el orden de los pasos no importe) y lee `live/filesystem.packages`.
- Falla si `firmware-nvidia-graphics` o `desktop-base` aparecen, o si falta `pulseaudio` (escenarios de `iso-build`).
- Escribe en `$GITHUB_STEP_SUMMARY` una tabla con tamaño de la ISO, límite, número de paquetes y tamaño de `filesystem.squashfs` e `initrd.img`.
- Falla si `stat -c %s` de la ISO supera `MAX_ISO_BYTES` (variable `env` del workflow, `1000000000`).

Como el paso falla antes de "Publicar la ISO como artifact", una ISO que no cumple no se publica. Alternativa descartada: comparar con el tamaño del build anterior. Requiere guardar estado entre ejecuciones y no expresa la meta acordada.

### 6. Revisión de lo que se quita

Antes de cambiar nada se guarda `filesystem.packages` de la ISO v0.1 como referencia (fuera del repo). Con la primera ISO nueva se compara (`comm`) y se revisa la lista de paquetes que desaparecen. Cualquier paquete con función visible (no librerías) que se haya ido se decide explícitamente: se vuelve a declarar o se acepta su ausencia anotándolo en `tasks.md`.

## Risks / Trade-offs

- [Falta algo que solo se nota al usar el sistema (iconos genéricos, un applet que no aparece, sonido mudo)] → Requisitos nuevos de `live-session` con escenarios concretos, revisión de la lista de paquetes eliminados (Decisión 6) y verificación en QEMU en BIOS y UEFI.
- [QEMU no prueba hardware real: Wi-Fi, audio SOF, GPU Intel reciente] → El firmware de esas familias se declara explícitamente; la prueba en hardware real queda fuera de este cambio.
- [La estimación (~0,93–0,95 GB) no se cumple] → Candidatos siguientes, en orden: `xfce4-goodies` restantes, `tango-icon-theme` (si el tema por defecto basta), `xserver-xorg-video-all` → solo `-video-intel`/`-amdgpu`/`-qxl`/`-vesa`/`-fbdev`, `firmware-mediatek`. Cada uno requiere confirmación del mantenedor porque reduce funciones o soporte de hardware.
- [Sin firmware NVIDIA, equipos con GPU NVIDIA reciente arrancan solo con gráficos básicos] → Aceptado por el mantenedor; se documenta en `docs/build.md` cómo instalar el firmware.
- [Una dependencia nueva de Debian vuelve a inflar la ISO] → El control de tamaño en CI lo detecta en el siguiente push.

## Migration Plan

Sin migración: la ISO se regenera en cada build. Para revertir basta con volver a `--apt-recommends true` y la lista única.
