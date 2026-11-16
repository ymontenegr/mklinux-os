# Construir y probar la ISO de MKLinux OS

## Camino recomendado: descargar la ISO de CI

Cada push a `main` construye la ISO en GitHub Actions (workflow `build-iso`). Es el camino recomendado, sobre todo en máquinas con pocos recursos.

1. Abre <https://github.com/ymontenegr/mklinux-os/actions/workflows/build-iso.yml> y entra en la última ejecución en verde.
2. En **Artifacts**, descarga `mklinux-os-<AAAAMMDD>-amd64` (hay que iniciar sesión en GitHub).
3. Descomprime el zip en `out/` y verifica la suma:

   ```bash
   mkdir -p out
   unzip ~/Descargas/mklinux-os-*-amd64.zip -d out/
   (cd out && sha256sum -c mklinux-os-*-amd64.iso.sha256)
   ```

   Desde la terminal, con [GitHub CLI](https://cli.github.com/) autenticado y `curl` (muestra el progreso y, si se corta, se puede reanudar repitiendo los pasos):

   ```bash
   repo=ymontenegr/mklinux-os
   run=$(gh run list --repo "$repo" --workflow build-iso.yml --branch main \
       --status success --limit 1 --json databaseId -q '.[0].databaseId')
   id=$(gh api "repos/$repo/actions/runs/$run/artifacts" -q '.artifacts[0].id')
   url=$(curl -sS -o /dev/null -w '%{redirect_url}' \
       -H "Authorization: Bearer $(gh auth token)" \
       "https://api.github.com/repos/$repo/actions/artifacts/$id/zip")
   mkdir -p out
   curl -# --fail -C - -o out/artifact.zip "$url" \
       && unzip -o out/artifact.zip -d out/ && rm out/artifact.zip \
       && (cd out && sha256sum -c mklinux-os-*-amd64.iso.sha256)
   ```

   Si la descarga se corta, `out/artifact.zip` queda a medias: repite todos los pasos y `curl -C -` continúa desde donde quedó (la URL de descarga caduca, por eso hay que volver a pedirla).

   No se recomienda `gh run download`: con una ISO de más de 1 GB puede quedarse detenido sin mostrar progreso.

Los artifacts se conservan 14 días.

## Build local (opcional)

### Requisitos del host

- Linux con Podman (`sudo apt install podman`).
- Permisos de `sudo`: live-build necesita root real, así que el script ejecuta `sudo podman`.
- Unos 15 GB libres de disco (chroot + imagen + capas del contenedor) y conexión a internet (se descarga ~1 GB de paquetes en cada build; no hay caché).

### Uso

```bash
scripts/build.sh            # build de desarrollo (squashfs con zstd)
scripts/build.sh --release  # build de release (squashfs con xz, más lento)
```

El resultado queda en `out/mklinux-os-<AAAAMMDD>-amd64.iso` (fecha UTC). Un segundo build el mismo día reemplaza la ISO anterior. `out/` y la ISO pertenecen a tu usuario: se pueden borrar sin `sudo`.

Cada build parte de cero dentro de un contenedor `debian:trixie` desechable y no deja archivos de trabajo en el repositorio. Si el build falla, el script termina con código distinto de 0 y no deja una ISO a medias en `out/`.

### Duración aproximada

- GitHub Actions: 10–15 minutos.
- MacBook Air 2012 (2 núcleos, 3,2 GB de RAM): más de 1 hora, según la conexión.

## Qué incluye la ISO y cómo agregar paquetes

La ISO se construye **sin paquetes recomendados** (`--apt-recommends false` en `live-build/auto/config`): solo entra lo declarado en las listas de `live-build/config/package-lists/` y sus dependencias obligatorias. Cada lista agrupa paquetes por función:

| Lista | Contenido |
|---|---|
| `10-base.list.chroot` | sesión live, `sudo`, polkit, idioma y teclado de consola |
| `20-escritorio.list.chroot` | XFCE, LightDM, Xorg, servicios de escritorio (discos, papelera, energía, notificaciones), fuentes, iconos y herramientas de XFCE |
| `30-red-firmware.list.chroot` | NetworkManager, Wi-Fi y firmware (Intel, MediaTek, Realtek, Broadcom y varios) |
| `40-audio.list.chroot` | PulseAudio, perfiles ALSA y control de volumen |
| `50-idioma.list.chroot` | correctores ortográficos en español y Firefox en español |
| `60-aplicaciones.list.chroot` | Firefox ESR |
| `70-instalador.list.chroot` | instalador Calamares |
| `70-instalador-{bios,uefi,luks}.list.binary` | repositorio local en la ISO con GRUB para BIOS y UEFI y `cryptsetup-initramfs`, que el instalador usa sin red (una lista por paquete: live-build resuelve cada una por separado y `grub-pc` y `grub-efi-amd64` están en conflicto) |
| `90-mklinux.list.chroot` | paquetes propios de `packages/` (`mklinux-identity`, `mklinux-calamares-settings`) |

Además de las listas, `live-build/config/includes.chroot/` copia archivos de configuración a la imagen; entre ellos, el panel de XFCE (`etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml`), que es el de Debian con el indicador de volumen agregado.

Para agregar un paquete, ponlo en la lista de su función con un comentario si el motivo no es obvio. Como los recomendados no se instalan, revisa con `apt-cache depends <paquete>` qué recomienda y declara también lo que haga falta para que funcione.

La ISO de desarrollo debe pesar como máximo **1 200 000 000 bytes**: el workflow `build-iso` muestra el tamaño en el resumen de cada ejecución y falla si se supera.

**GPU NVIDIA:** la ISO no incluye `firmware-nvidia-graphics`, así que en equipos con GPU NVIDIA reciente el driver libre `nouveau` funciona solo con gráficos básicos. En un sistema persistente o instalado se puede agregar con:

```bash
sudo apt update && sudo apt install firmware-nvidia-graphics
```

y reiniciando.

**Wi-Fi Broadcom:** la ISO trae `firmware-brcm80211` para el driver libre `brcmsmac` (BCM4313, BCM43224 y BCM43225, por ejemplo, la de la MacBook Air 2012) y bloquea la carga automática de `b43` en `/etc/modprobe.d/mklinux-broadcom.conf`. Los dos drivers reclaman las mismas tarjetas, y `b43` no funciona sin su firmware, que no está en la ISO. En un sistema persistente o instalado con una tarjeta que solo soporta `b43`:

```bash
sudo apt install firmware-b43-installer
sudo rm /etc/modprobe.d/mklinux-broadcom.conf
sudo update-initramfs -u
```

y reiniciando.

## Usar la ISO en una memoria USB

La ISO es híbrida: se puede grabar tal cual en una memoria USB (de 2 GB o más) y arrancar un equipo real con ella. Es una sesión live: el disco del equipo no se toca y lo que se haga en la sesión se pierde al apagar. **Todo el contenido de la memoria se borra.**

### Grabar la memoria

Conecta la memoria y busca su nombre de dispositivo:

```bash
lsblk -o NAME,SIZE,MODEL,TRAN
```

Es la fila con `TRAN` = `usb` y el tamaño de la memoria (por ejemplo, `sdb`). Comprueba que no sea el disco interno. Luego, cambiando `sdX` por ese nombre:

```bash
sudo dd if=out/mklinux-os-<AAAAMMDD>-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Alternativa gráfica en Ubuntu: la aplicación **Discos** (`gnome-disks`). Elige la memoria y, en el menú ⋮, usa "Restaurar imagen de disco…" con la ISO.

### Arrancar desde la memoria

- **PC:** al encender, pulsa la tecla del menú de arranque del fabricante (suele ser F12, F10, F9 o Esc) y elige la memoria USB. En UEFI, Secure Boot debe estar desactivado.
- **Mac con procesador Intel:** apaga el equipo, conecta la memoria, enciéndelo manteniendo pulsada la tecla **Option (⌥ / Alt)** y elige **"EFI Boot"**.

## Probar la ISO en QEMU

### Requisitos del host

```bash
sudo apt install qemu-system-x86 qemu-utils ovmf
sudo usermod -aG kvm "$USER"   # luego cerrar sesión y volver a entrar
```

La virtualización (VT-x) debe estar activada en el firmware del equipo; `ls -l /dev/kvm` debe mostrar el dispositivo y el grupo `kvm`.

### Uso

Coloca la ISO en `out/` (construida en local o descargada de CI, ver arriba) y ejecuta:

```bash
scripts/test-qemu.sh bios                      # firmware BIOS, ISO más reciente de out/
scripts/test-qemu.sh uefi                      # firmware UEFI (OVMF)
scripts/test-qemu.sh uefi out/mklinux-os-20261116-amd64.iso   # ISO concreta
```

La VM usa KVM, 2 CPU y 1536 MB de RAM, sin disco (solo sesión live). En modo UEFI se usa una copia temporal de las variables OVMF, que se borra al cerrar la VM.

Opciones para probar la instalación (van después del modo):

| Opción | Efecto |
|---|---|
| `--disco` | conecta el disco virtual `out/mklinux-disco-<modo>.qcow2` (20 GB; se crea vacío si no existe y crece según se usa). En `uefi`, las variables UEFI se guardan en `out/mklinux-disco-uefi.vars.fd` y se conservan entre ejecuciones. Arranca primero la ISO y, si no hay, el disco. |
| `--sin-iso` | con `--disco`: arranca solo desde el disco, para probar el sistema instalado. |
| `--sin-red` | arranca la VM sin tarjeta de red. |

```bash
scripts/test-qemu.sh bios --disco --sin-red    # instalar sin red desde la ISO
scripts/test-qemu.sh bios --disco --sin-iso    # arrancar el sistema instalado
rm out/mklinux-disco-bios.qcow2                # empezar de cero (en uefi, borrar también out/mklinux-disco-uefi.vars.fd)
```
 Para usar otro firmware: `OVMF_CODE=/ruta/CODE.fd OVMF_VARS=/ruta/VARS.fd scripts/test-qemu.sh uefi`.

### Lista de comprobación de aceptación

Repetir en modo `bios` y en modo `uefi`:

1. El menú de arranque aparece y la entrada por defecto llega, sin intervención, al escritorio XFCE del usuario `mk`.
2. En una terminal (`xfce4-terminal`):

   | Comando | Resultado esperado |
   |---|---|
   | `cat /etc/os-release` | contiene `NAME="MKLinux OS"`, `ID=mklinux`, `ID_LIKE=debian`, `VERSION_CODENAME=trixie` |
   | `whoami` | `mk` |
   | `sudo true; echo $?` | `0` |
   | `hostname` | `mklinux` |
   | `locale \| grep LANG=` | `LANG=es_CO.UTF-8` |
   | `setxkbmap -query \| grep layout` | `layout:     latam` |
   | `date +%Z` | `-05` |
   | `hostnamectl \| grep 'Operating System'` | `MKLinux OS 0.1 (trixie)` |
   | `dpkg -s mklinux-identity \| grep Status` | `install ok installed` |

## Instalar MKLinux OS

En la sesión live, el ícono **Instalar MKLinux OS** del escritorio (o Menú → Sistema) abre el instalador Calamares. Funciona sin conexión a internet: el cargador de arranque y las herramientas de cifrado se instalan desde un repositorio que va dentro de la ISO.

- **Particionado:** "Borrar disco" (borra **todo** el disco elegido; opcionalmente cifra el sistema con LUKS) o "Particionado manual". No se ofrece instalar junto a otro sistema.
- **Disco mínimo:** 20 GB. El instalador no avisa si el disco es más pequeño: la instalación fallaría a mitad, con el disco ya borrado.
- **Valores por defecto:** idioma `es_CO.UTF-8`, teclado `latam`, zona `America/Bogota` y equipo `mklinux`. Todos se pueden cambiar.
- **Sistema instalado:** el usuario y la contraseña elegidos (con `sudo`), XFCE con LightDM y la identidad de MKLinux OS. No conserva el usuario live `mk`, los paquetes de la sesión live ni el instalador. Las actualizaciones vienen de los repositorios oficiales de Debian (`/etc/apt/sources.list.d/debian.sources`).

### Lista de comprobación de la instalación (QEMU)

1. **BIOS sin red:** `scripts/test-qemu.sh bios --disco --sin-red`. En la sesión live, el ícono abre el instalador sin pedir contraseña, en español, con la marca de MKLinux OS y los valores por defecto de arriba. Instala con "Borrar disco", sin cifrado y con el usuario `prueba`.
2. **Sistema instalado (BIOS):** `scripts/test-qemu.sh bios --disco --sin-iso`. Arranca hasta LightDM y `prueba` entra a XFCE. En una terminal:

   | Comando | Resultado esperado |
   |---|---|
   | `sudo true; echo $?` | `0` (con la contraseña de `prueba`) |
   | `grep -E '^(NAME\|ID)=' /etc/os-release` | `NAME="MKLinux OS"` e `ID=mklinux` |
   | `dpkg -s mklinux-identity \| grep Status` | `install ok installed` |
   | `dpkg -l live-boot live-config live-config-systemd live-tools calamares mklinux-calamares-settings \| grep ^ii` | sin salida |
   | `getent passwd mk` | sin salida |
   | `sudo apt-get update` (con red) | termina sin errores |

3. **Opciones de particionado:** `scripts/test-qemu.sh bios --disco` con el disco del paso 1. En el instalador, la página de particionado solo ofrece "Borrar disco" y "Particionado manual".
4. **UEFI con cifrado:** `scripts/test-qemu.sh uefi --disco`. Instala con "Borrar disco" y la casilla de cifrado. Después, `scripts/test-qemu.sh uefi --disco --sin-iso`: pide la contraseña de cifrado, llega a LightDM, `[ -d /sys/firmware/efi ] && echo UEFI` muestra `UEFI` y `lsblk -o NAME,TYPE` muestra un dispositivo `crypt`.
5. Al terminar, borra los discos virtuales: `rm out/mklinux-disco-*`.
