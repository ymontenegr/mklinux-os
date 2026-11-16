# Design

## Context

Ver `proposal.md` (Why). Medido en `debian:trixie` el 2026-11-16:

- `calamares` `3.3.14-1` (Qt 6 y KDE Frameworks 6) agrega 103 paquetes y unos 177 MB instalados a la lista actual de la ISO, que hoy pesa 890 241 024 bytes. Comprimido, se estima en unos +80 MB.
- `calamares-settings-debian` `13.0.13-1` es la configuración de Debian:
  - `settings.conf` con la secuencia de módulos;
  - `modules/*.conf`;
  - la marca `debian`;
  - cuatro scripts de ayuda, que usan como repositorio el medio live (`deb [trusted=yes] file:/run/live/medium trixie main`):
    - `bootloader-config`: instala `grub-pc` o `grub-efi` según el firmware y, con LUKS, `cryptsetup-initramfs`;
    - `sources-media`;
    - `sources-final`;
    - `dpkg-unsafe-io`;
  - un lanzador "Install Debian";
  - un autostart que copia el lanzador al escritorio y lo marca como confiable en XFCE.

  El autostart marca `~/Desktop/...` sin usar `xdg-user-dir`, así que en español (`~/Escritorio`) el lanzador queda "no confiable".
- live-build publica en la ISO un repositorio (`pool/` y `dists/trixie/main/binary-amd64/Packages`) con los paquetes de `config/package-lists/*.list.binary`.
- El backend `apt` del módulo `packages` ejecuta `apt-get --purge remove` y luego `apt-get --purge autoremove`. En el chroot de live-build, las dependencias de `calamares` quedan marcadas como automáticas.
- `partition.conf` de Calamares 3.3 no tiene ninguna opción para ocultar "Instalar junto a" ni "Reemplazar una partición". Según su documentación, esas dos opciones no se ofrecen si no hay ningún tamaño mínimo de almacenamiento configurado (`requiredStorage`).
- `users.conf` permite proponer el nombre de equipo con `hostname.template`.

## Goals / Non-Goals

**Goals:**

- Instalar sin conexión a internet, en BIOS y en UEFI, con o sin LUKS, y que el sistema arranque solo.
- Que toda la configuración propia sea un paquete `mklinux-*` legible y que se pueda probar en QEMU.

**Non-Goals:**

- Secure Boot: no se incluyen `shim-signed` ni `grub-efi-amd64-signed` (el spec de `live-session` ya excluye Secure Boot).
- Instalación OEM, actualizaciones del sistema instalado o una marca gráfica definitiva: el logo de este cambio es provisional.
- Instalar en hardware real: queda a criterio del mantenedor, fuera de la aceptación de este cambio.
- Pantalla de arranque gráfica: la ISO no trae Plymouth y se quita `plymouthcfg` de la secuencia.

## Decisions

### 1. Paquete propio `mklinux-calamares-settings`, partiendo de `calamares-settings-debian`

En `packages/mklinux-calamares-settings/`, construido igual que `mklinux-identity` por `scripts/container-build.sh`. Declara `Depends: calamares, rsync, cryptsetup, keyutils, pkexec, libglib2.0-bin` y `Conflicts/Replaces: calamares-settings-debian`. Contiene:

- `etc/calamares/settings.conf`: la secuencia de Debian sin `plymouthcfg` y con `branding: mklinux`.
- `etc/calamares/modules/*.conf`: ver decisiones 3 a 6.
- `etc/calamares/branding/mklinux/`:
  - `branding.desc` con los textos de MKLinux OS y las URL del repositorio;
  - un logo provisional en PNG;
  - una presentación de imágenes (`slideshow` como lista de imágenes). Se usa en lugar de `show.qml` para no depender de módulos QML.
- `usr/lib/calamares/modules/` y `usr/share/calamares/helpers/`: los cuatro scripts de ayuda de Debian, adaptados (decisión 4).
- `usr/bin/mklinux-instalar`: el envoltorio de `calamares-install-debian`. Aparta `/etc/fstab` de live-build durante la instalación y ejecuta `pkexec calamares`.
- `usr/share/applications/mklinux-instalar.desktop`: "Instalar MKLinux OS", categoría `System`.
- `etc/xdg/autostart/` y `usr/bin/mklinux-icono-instalador`: copian el lanzador a `$(xdg-user-dir DESKTOP)` y lo marcan como confiable con `gio set` (`metadata::trusted` y `metadata::xfce-exe-checksum`) sobre esa misma ruta.

Alternativa descartada: depender de `calamares-settings-debian` y desviar sus archivos con `dpkg-divert`. Son 15 archivos y la marca y los textos cambian casi todos; un paquete propio con `Conflicts` es más simple y más fácil de leer. Los scripts de Debian se copian con su licencia (ISC), como indica su `copyright`; el paquete incluye ese aviso.

### 2. Repositorio local en la ISO para el cargador de arranque y LUKS

Tres listas `live-build/config/package-lists/70-instalador-{bios,uefi,luks}.list.binary` declaran `grub-pc`, `grub-efi-amd64` y `cryptsetup-initramfs`, una por paquete: live-build resuelve cada lista `.binary` con una orden `apt-get --download-only install` propia (con `Dir::State::status=/dev/null`, así que descarga también sus dependencias), y `grub-pc` y `grub-efi-amd64` están en conflicto entre sí. `bootloader-config` los instala en el sistema destino desde `file:/run/live/medium`, igual que en Debian.

Se sigue el método de Debian en lugar de instalar `grub-pc-bin` y `grub-efi-amd64-bin` en el chroot: así el sistema instalado tiene el paquete `grub-*` correcto para su firmware y se actualiza con `apt`.

### 3. Particionado: "Borrar disco" y "Manual", sin tamaño mínimo

`partition.conf`:

- `allowManualPartitioning: true`, `initialPartitioningChoice: erase`.
- `enableLuksAutomatedPartitioning: true` (casilla desmarcada por defecto).
- `userSwapChoices: [none, file]`, `initialSwapChoice: file`.
- `defaultFileSystemType: ext4`, `availableFileSystemTypes: [ext4, btrfs]`.

Como la ISO se construye sin recomendados, `70-instalador.list.chroot` declara los recomendados de `calamares` que la instalación necesita: `squashfs-tools` (`unsquashfs` para `unpackfs`) y `btrfs-progs` (btrfs en el particionado manual). Se detectó en la tarea 4.2: `unpackfs` falló porque no había `unsquashfs`. xfs no se ofrece para no sumar `xfsprogs`.

Para que no se ofrezcan "Instalar junto a" ni "Reemplazar" (decisión del mantenedor), no se configura `requiredStorage` ni en `welcome.conf` ni en `partition.conf`. La bienvenida solo comprueba `ram` (1 GiB) y `root`. A cambio se pierde el aviso de disco pequeño. `docs/build.md` indica el mínimo (20 GB), y la tarea 4.3 verifica en QEMU que esas opciones no aparecen con un disco que ya tiene particiones.

Alternativa descartada: parchear Calamares (va contra la regla de no modificar paquetes de Debian).

### 4. Scripts de ayuda adaptados

- `sources-media`: igual que el de Debian (medio en `/run/live/medium`, `RELEASE=trixie`).
- `sources-final`: escribe `/etc/apt/sources.list.d/debian.sources` (formato deb822), con `trixie`, `trixie-updates` y `trixie-security` y los componentes `main contrib non-free non-free-firmware`, en lugar del `sources.list` de Debian. Así cumple el spec de fuentes de APT, incluido `non-free-firmware`.
- `bootloader-config`: el de Debian sin cambios de lógica. Instala `grub-pc` en BIOS, `grub-efi` en UEFI y `cryptsetup-initramfs` y `keyutils` si la raíz está en `/dev/mapper/luks*`.
- `dpkg-unsafe-io` y `dpkg-unsafe-io-undo`: sin cambios.

### 5. Idioma, teclado, usuarios y equipo

- `locale.conf`: `region: America`, `zone: Bogota`, sin GeoIP (la instalación no requiere red). El idioma propuesto es el de la sesión live (`es_CO.UTF-8`).
- `keyboard.conf`: `guessLayout: false`. Sin esa opción, Calamares adivina la distribución a partir del idioma (`es_CO` → `es`) al entrar en la página de teclado; con ella conserva la activa (`latam`) y la escribe en `/etc/default/keyboard` del destino. Se detectó en la tarea 4.2.
- `users.conf`:
  - grupos por defecto de Debian;
  - `sudoersGroup: sudo` y `setRootPassword: false`;
  - `hostname.location: EtcFile` y `hostname.template: "mklinux"`;
  - `doAutologin: false`.

  La contraseña solo tiene que no estar vacía (`nonempty: true`), sin `libpwquality`. Calamares exige con `libpwquality` una puntuación mínima de 40, fija en su código, y sin el diccionario de cracklib en la ISO rechaza cualquier contraseña. Se detectó en la tarea 4.2.
- `displaymanager.conf`: solo `lightdm`, con `basicSetup: false`. La configuración de LightDM que trae la imagen (`50-mklinux.conf`, `user-session=xfce`) ya vale para el sistema instalado.
- `finished.conf`: igual que en Debian (reiniciar al terminar, marcado por defecto).

### 6. Limpieza del sistema instalado

`packages.conf` con `backend: apt` y la operación `remove` de `live-boot`, `live-config`, `live-config-systemd`, `live-tools`, `calamares` y `mklinux-calamares-settings`. El `autoremove` posterior quita Qt 6 y KDE Frameworks si nada más los usa. El usuario `mk` no existe en el squashfs (lo crea `live-config` al arrancar la sesión live), así que no llega al disco.

`mklinux-identity` no se toca: el enlace `/etc/os-release` y `/usr/lib/os-release` llegan al disco con `unpackfs`, y el spec de `os-identity` lo verifica en el sistema instalado.

### 7. Lanzador sin contraseña

`pkexec calamares` no debe pedir contraseña al usuario live. Se cuenta con la regla de polkit que `live-config` crea para el usuario live (componente `policykit`). La tarea 4.1 lo verifica. Si no basta, el paquete agrega una regla en `/usr/share/polkit-1/rules.d/` limitada a `calamares` y al grupo `sudo`, activa solo en la sesión live: el paquete se quita del sistema instalado, así que la regla no llega a él.

### 8. `scripts/test-qemu.sh` con disco

Opciones nuevas, combinables después del modo: `--disco`, `--sin-iso` (solo con `--disco`) y `--sin-red`.

- El disco es `out/mklinux-disco-<modo>.qcow2` (20 GB, `qemu-img create -f qcow2`), creado si no existe. Se conecta como `virtio-blk`.
- En `uefi` con `--disco`, las variables van en `out/mklinux-disco-uefi.vars.fd`, copiadas de OVMF la primera vez. Así la entrada de arranque de GRUB sobrevive entre la instalación y el arranque sin ISO. Sin `--disco` se sigue usando la copia temporal actual.
- Orden de arranque: con ISO, `-boot order=d` (la ISO primero, el disco después); con `--sin-iso`, solo el disco.
- Se requiere `qemu-img`: si falta, falla con un mensaje en español, como el resto de las comprobaciones.

### 9. Límite de tamaño

`MAX_ISO_BYTES` en `build-iso.yml` pasa a `1200000000` (decisión del mantenedor). También se actualizan `docs/build.md` y la variable de los specs.

## Risks / Trade-offs

- [Instalar en QEMU con 1536 MB de RAM y 2 CPU es lento y puede quedarse sin memoria] → La VM no tiene swap; si Calamares falla por memoria, se prueba con `--sin-red` y sin otras aplicaciones abiertas en el host. Si aun así no alcanza, se discute subir la RAM solo para `--disco`, lo que cambia el spec `vm-testing`.
- [El aviso de disco pequeño desaparece (decisión 3)] → El mínimo se documenta. Un disco demasiado pequeño falla durante `unpackfs`, después de borrarse; el riesgo se acepta porque solo afecta a discos de menos de ~10 GB.
- [Que no haya `requiredStorage` deja de ocultar "Junto a" y "Reemplazar" en una versión futura de Calamares] → La tarea 4.3 lo comprueba en cada aceptación; el escenario de `installer` lo detecta.
- [`bootloader-config` no encuentra `grub-*` en el medio] → Se verifica `dists/trixie/main/binary-amd64/Packages` en la ISO (tarea 3.1) y se instala sin red (tarea 4.2).
- [El `autoremove` quita algo que el sistema instalado necesita] → El escenario de inicio de sesión y una revisión de `dpkg -l` en el sistema instalado (tarea 4.2) lo detectan.
- [Con cifrado, `/boot` queda dentro de LUKS y es GRUB quien pide la frase al encender, siempre con teclado US: una frase con ñ, tildes o símbolos escrita en latam durante la instalación puede no poder escribirse al arrancar] → Se documenta en `docs/build.md` (usar letras sin tilde, números y espacios). Una alternativa sería una partición `/boot` sin cifrar (`partitionLayout`), que deja el kernel visible; se puede evaluar en un cambio posterior. Se detectó en la tarea 4.4.
- [Discos virtuales en un host con 24 GB libres] → qcow2 crece solo con lo escrito (~3–4 GB por instalación). Se reutiliza un disco por modo y se borra al terminar la aceptación.

## Migration Plan

Sin migración: la ISO se regenera en cada build y el sistema instalado es nuevo. Para revertir, se quitan `calamares`, `mklinux-calamares-settings` y la lista `.list.binary` y se restaura el límite.

## Open Questions

- Logo y presentación definitivos de MKLinux OS: el diseño gráfico se deja para más adelante. Este cambio usa un logo provisional generado por script.
