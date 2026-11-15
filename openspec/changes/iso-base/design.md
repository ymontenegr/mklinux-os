# Design

## Context

El repositorio está vacío: existen `scripts/`, `live-build/`, `packages/` y `.github/` sin contenido, no hay specs previos y todavía no hay remote ni commits. El repositorio de GitHub será público. Ver `proposal.md` (Why) para la motivación y `specs/` para los requisitos.

Restricciones que dan forma al diseño:

- La máquina de desarrollo es limitada (2 núcleos, ~3,2 GB de RAM). Un build local es posible pero lento; el camino habitual es construir en GitHub Actions y probar en local con QEMU (máximo 1536 MB para la VM).
- live-build necesita root real: `debootstrap` crea nodos de dispositivo y monta `proc`, `sys` y `dev` dentro del chroot. Un contenedor Podman rootless, incluso `--privileged`, no puede hacerlo de forma fiable.
- Principio del proyecto: no se modifican paquetes de Debian; lo propio va en paquetes `mklinux-*`.

## Goals / Non-Goals

**Goals:**

- Un único punto de entrada (`scripts/build.sh`) idéntico en local y en CI.
- Configuración de live-build declarativa y versionada en `live-build/`, sin estado de build en el repo.
- Establecer desde ya el patrón de paquetes propios (`packages/mklinux-*`) que usarán los cambios siguientes.

**Non-Goals:**

- Instalador Calamares, branding visual (fondos, tema de GRUB, logo de Plymouth) y herramientas de IA: fases posteriores.
- Secure Boot (los cargadores firmados de Debian se pueden evaluar más adelante; no se prueba en este cambio).
- Prueba automática sin pantalla (por consola serie) del arranque hasta el escritorio: la aceptación de este cambio es manual en QEMU.
- Caché de paquetes entre builds locales: cada build descarga todo (ver Riesgos).
- Optimización del tamaño de la ISO: en v0.1 se instalan los paquetes recomendados; reducir el tamaño será un cambio posterior.
- Releases firmadas o publicadas en GitHub Releases.

## Decisions

### 1. Estructura del repositorio

```
scripts/build.sh                 # punto de entrada en el host
scripts/container-build.sh       # corre DENTRO del contenedor
scripts/test-qemu.sh
live-build/auto/config           # llamada a `lb config` con todas las opciones
live-build/config/package-lists/mklinux.list.chroot
live-build/config/includes.chroot/...   # archivos de configuración propios (LightDM, teclado)
packages/mklinux-identity/       # árbol fuente del .deb (DEBIAN/ + archivos)
.github/workflows/build-iso.yml
docs/build.md
```

Se usa `auto/config` (mecanismo estándar de live-build) para que toda la configuración quede en un único archivo legible y `lb config` regenere `config/` en cada build. Alternativa descartada: commitear el árbol `config/` generado por `lb config`, porque mezcla valores por defecto con decisiones propias y se desactualiza con cada versión de live-build.

### 2. Ejecución en contenedor: `build.sh` en el host y `container-build.sh` dentro

`build.sh`:

1. Comprueba que Podman existe.
2. Crea `out/` con `mkdir -p out` como el usuario del host, **antes** de cualquier uso de `sudo`. Si `out/` no existiera, Podman (ejecutado como root) lo crearía al montarlo y quedaría propiedad de root.
3. En modo rootless vuelve a lanzar Podman con `sudo` (live-build necesita root real; ver Context).
4. Ejecuta `podman run --rm --privileged` con `debian:trixie`, montando el repositorio en solo lectura en `/src` y `out/` en lectura y escritura en `/out`.
5. Le pasa `MKLINUX_RELEASE=1` cuando se usa `--release` y `BUILD_DATE` (fecha UTC calculada una sola vez en el host).

`container-build.sh`:

1. `apt-get install live-build` (`dpkg-deb` ya viene con `dpkg`).
2. Construye `packages/mklinux-identity` con `dpkg-deb --build` y deja el `.deb` en `config/packages.chroot/` del directorio de trabajo.
3. Copia `live-build/` a un directorio de trabajo dentro del contenedor (`/build`), ejecuta `lb config` y `lb build`.
4. Copia la ISO a `/out/.mklinux-os-<fecha>-amd64.iso.partial` y luego la renombra al nombre final con `mv` (operación atómica en el mismo sistema de archivos). Así se cumple el requisito de no dejar una ISO incompleta con el nombre final.
5. Ajusta el propietario del archivo a `HOST_UID:HOST_GID` (que pasa `build.sh`) para que el usuario no necesite `sudo` para borrar la ISO.

El build trabaja en el sistema de archivos del contenedor, que se destruye con `--rm`: cada build es limpio y el repositorio no recibe archivos de trabajo. Alternativa descartada: correr `lb build` sobre el repo montado, que deja el chroot (propiedad de root) dentro del working tree.

### 3. Opciones de live-build

En `auto/config` (valores principales):

- `--distribution trixie --architectures amd64 --archive-areas "main contrib non-free non-free-firmware"` (el firmware no libre mejora el arranque en hardware real y es lo que Debian incluye en sus propias imágenes live).
- `--firmware-chroot false --firmware-binary false`: por defecto live-build instala *todos* los paquetes de `non-free-firmware`; se desactiva para que el firmware sea solo el de la lista explícita (Decisión 4).
- `--binary-images iso-hybrid --bootloaders "syslinux,grub-efi"` → ISO híbrida que arranca en BIOS (syslinux/isolinux) y UEFI (GRUB), desde CD o USB.
- `--iso-volume "MKLinux OS <fecha>" --iso-application "MKLinux OS" --iso-publisher "MKLinux OS"`.
- `--bootappend-live "boot=live components username=mk hostname=mklinux locales=es_CO.UTF-8 keyboard-layouts=latam timezone=America/Bogota"`.
- `--chroot-squashfs-compression-type zstd` por defecto y `xz` cuando `MKLINUX_RELEASE=1`.
- `--apt-recommends true` en v0.1: se instalan los paquetes recomendados para que XFCE, LightDM y las herramientas de red funcionen completos sin tener que descubrir a mano cada dependencia recomendada que falta. Alternativa descartada por ahora: `--apt-recommends false` con listas explícitas, que reduce el tamaño de la ISO pero exige depurar dependencias faltantes. Se retomará en el cambio posterior de optimización de tamaño.

Usuario, idioma, teclado, zona horaria y hostname se configuran en el arranque mediante `live-config` (parámetros `username=`, `locales=`, etc.). Es el mecanismo estándar de Debian Live: crea el usuario con `sudo` sin contraseña y configura el inicio automático en LightDM. Alternativa descartada: hooks que creen el usuario en el chroot, que duplican lo que live-config ya hace y obligarían a mantenerlo cuando llegue el instalador.

Como respaldo, `includes.chroot/etc/default/keyboard` fija `XKBLAYOUT="latam"` y `includes.chroot/etc/lightdm/lightdm.conf.d/` fija `user-session=xfce`, para que el teclado y la sesión sean correctos aunque cambien los valores por defecto de live-config.

### 4. Lista de paquetes

`mklinux.list.chroot`: `live-boot live-config live-config-systemd`, `xfce4 xfce4-terminal xfce4-goodies` (mínimo razonable), `lightdm lightdm-gtk-greeter`, `xserver-xorg-core xserver-xorg-input-all xserver-xorg-video-all` (incluye `qxl`/`modesetting` para QEMU), `network-manager-gnome`, `wpasupplicant`, firmware para hardware real (`firmware-linux-free`, `firmware-misc-nonfree`, `firmware-iwlwifi`, `firmware-realtek`; los tres últimos vienen del área `non-free-firmware`), `sudo`, `locales`, `keyboard-configuration console-setup`, `task-spanish` (traducciones), `firefox-esr` y `mklinux-identity` (desde `packages.chroot`).

La lista exacta se ajusta durante la implementación; el objetivo orientativo es < 2,5 GB (con recomendados incluidos).

### 5. Identidad: paquete `mklinux-identity` con `dpkg-divert`

En Debian, `/etc/os-release` es un enlace a `/usr/lib/os-release`, que pertenece a `base-files`. Sobrescribirlo directamente (por ejemplo con `includes.chroot`) se perdería en la siguiente actualización de `base-files`.

`mklinux-identity` desvía `/usr/lib/os-release` a `/usr/lib/os-release.debian` en `preinst` y lo revierte en `postrm`. Se usa `--no-rename` y se copia/restaura el archivo a mano, en lugar de `--rename`: `base-files` es Essential y con `--rename` el archivo desaparecería entre `preinst` y el desempaquetado (dpkg lo advierte explícitamente). Así `dpkg` instala las futuras versiones de Debian en `os-release.debian` y la de MKLinux OS se mantiene. Ambos scripts son idempotentes: se pueden ejecutar varias veces, o tras una instalación interrumpida, sin fallar ni duplicar la desviación.

- `preinst` (`install` y `upgrade`): copia el original a `os-release.debian` y añade la desviación (`--no-rename`) solo si `dpkg-divert --listpackage /usr/lib/os-release` no devuelve ya `mklinux-identity`. Con cualquier otro argumento no hace nada.
- `postrm`:
  - `remove`, `purge` y `abort-install`: quita la desviación (`--no-rename`) solo si existe y pertenece a `mklinux-identity`, y luego mueve `os-release.debian` de vuelta a `os-release` si quedó sin desviación; así se restaura el archivo de Debian. `abort-install` cubre el caso en que `preinst` ya añadió la desviación pero la instalación falló después; sin él, el sistema quedaría sin `/usr/lib/os-release`.
  - `upgrade`, `abort-upgrade`, `failed-upgrade` y demás argumentos: no hace nada, porque hay una versión del paquete instalada que sigue necesitando la desviación.
- Ambos scripts usan `set -e` y terminan con código 0 en los casos sin acción.

El paquete se construye con `dpkg-deb --build` desde un árbol versionado (sin `debhelper`), porque es un paquete de pocos archivos y no compila nada.

Contenido de `os-release`: `NAME="MKLinux OS"`, `PRETTY_NAME="MKLinux OS 0.1 (trixie)"`, `ID=mklinux`, `ID_LIKE=debian`, `VERSION_ID="0.1"`, `VERSION="0.1 (trixie)"`, `VERSION_CODENAME=trixie`, más `HOME_URL` cuando exista una página del proyecto.

`ID_LIKE=debian` mantiene la compatibilidad con scripts de instalación de terceros que detectan la familia Debian. `VERSION_CODENAME=trixie` hace que las herramientas que construyen URLs de repositorios APT (Docker, Node, etc.) sigan funcionando.

Alternativa descartada: un hook de chroot que reescriba el archivo. Es más simple, pero va contra el principio de no modificar paquetes de Debian y se rompe al actualizar `base-files`.

### 6. `test-qemu.sh`

Uso: `scripts/test-qemu.sh {bios|uefi} [ISO]`. Comando base:

```
qemu-system-x86_64 -enable-kvm -cpu host -smp 2 -m 1536 \
  -cdrom "$ISO" -boot d -vga virtio -display gtk \
  -device virtio-net-pci,netdev=n0 -netdev user,id=n0
```

En modo `uefi` añade `-drive if=pflash,format=raw,readonly=on,file=<OVMF_CODE>` y un segundo `pflash` con una copia de `OVMF_VARS` en un directorio temporal (`mktemp -d`, que se borra al salir). Busca OVMF en las rutas de Ubuntu y Debian (`/usr/share/OVMF/OVMF_CODE_4M.fd`, `/usr/share/OVMF/OVMF_CODE.fd` y sus `VARS`) y permite sobrescribirlas con `OVMF_CODE=` y `OVMF_VARS=`. La VM no tiene disco: es una sesión live.

Se usa `-smp 2` y no 4, para dejar margen al host con 2 núcleos físicos.

### 7. GitHub Actions

- El primer build completo de la ISO se hace aquí, no en la máquina de desarrollo; el build local queda como verificación opcional.
- `on: push: branches: [main]` + `workflow_dispatch`.
- Repositorio público: los runners estándar no consumen minutos de pago, pero los logs y artifacts son visibles. El workflow no usa secretos y declara `permissions: contents: read`.
- Runner `ubuntu-24.04`, que trae Podman. El build usa `sudo podman` (sin contraseña en el runner) porque `build.sh` relanza con `sudo` en modo rootless.
- Paso previo para liberar espacio (borrar `/usr/share/dotnet`, `/usr/local/lib/android`, `/opt/ghc`): el runner tiene ~14 GB libres y un build de XFCE ocupa varios GB entre chroot y binarios.
- Tras el build: `sha256sum` de la ISO y `actions/upload-artifact` con `name: mklinux-os-<fecha>-amd64`, `retention-days: 14`, `compression-level: 0` (la ISO ya está comprimida).
- `concurrency` agrupado por rama con `cancel-in-progress: true`, para no acumular builds largos.
- `timeout-minutes: 90`.

## Risks / Trade-offs

- [El build local en la MacBook Air es lento (decenas de minutos) y exige varios GB de disco] → Se documenta que el camino recomendado es descargar el artifact de CI; el build local sigue siendo posible y es el mismo script.
- [Podman rootful requiere `sudo`] → `build.sh` lo explica en su mensaje y solo usa `sudo` para Podman; el archivo final se entrega al usuario del host (ver Decisión 2).
- [Sin caché de APT, cada build descarga ~1 GB] → Aceptable para CI. Si en local resulta molesto, un cambio posterior puede montar un volumen de caché.
- [Los valores por defecto de live-build o live-config cambian entre versiones] → Las opciones críticas son explícitas en `auto/config` y hay archivos de respaldo en `includes.chroot` (Decisión 3).
- [Con `--apt-recommends true` la ISO es más grande (~2–2,5 GB) y tarda más en construirse y en descargarse] → Aceptado para v0.1; el objetivo orientativo es < 2,5 GB y la reducción de tamaño queda para un cambio posterior.
- [Repositorio público: cualquier secreto o dato personal que llegue al repo, a los logs o a los artifacts queda expuesto] → El workflow no usa secretos, tiene permisos mínimos y la ISO no contiene credenciales (el usuario live no tiene contraseña).
- [Espacio insuficiente en el runner de GitHub] → Paso de limpieza de disco y `df -h` en el log para diagnosticar.
- [La aceptación es manual (visual)] → Los escenarios de los specs son comandos concretos que se ejecutan en la terminal de la VM; la automatización por consola serie queda como mejora futura.
- [`dpkg-divert` mal revertido deja el sistema sin `os-release` de Debian al desinstalar] → `postrm` elimina la desviación en `remove`/`purge`/`abort-install` de forma idempotente (Decisión 5), y se prueba la reinstalación de `base-files` (escenario del spec `os-identity`).

## Migration Plan

No aplica: es el primer build. Para revertir basta con quitar los archivos nuevos; no hay sistemas desplegados.
