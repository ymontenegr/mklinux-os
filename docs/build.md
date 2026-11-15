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
   curl -# --fail -C - -o out/artifact.zip "$url"
   unzip -o out/artifact.zip -d out/ && rm out/artifact.zip
   (cd out && sha256sum -c mklinux-os-*-amd64.iso.sha256)
   ```

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

- GitHub Actions: 30–50 minutos.
- MacBook Air 2012 (2 núcleos, 3,2 GB de RAM): más de 1 hora, según la conexión.

## Probar la ISO en QEMU

### Requisitos del host

```bash
sudo apt install qemu-system-x86 ovmf
sudo usermod -aG kvm "$USER"   # luego cerrar sesión y volver a entrar
```

La virtualización (VT-x) debe estar activada en el firmware del equipo; `ls -l /dev/kvm` debe mostrar el dispositivo y el grupo `kvm`.

### Uso

Coloca la ISO en `out/` (construida en local o descargada de CI, ver arriba) y ejecuta:

```bash
scripts/test-qemu.sh bios                      # firmware BIOS, ISO más reciente de out/
scripts/test-qemu.sh uefi                      # firmware UEFI (OVMF)
scripts/test-qemu.sh uefi out/mklinux-os-20261115-amd64.iso   # ISO concreta
```

La VM usa KVM, 2 CPU y 1536 MB de RAM, sin disco (solo sesión live). En modo UEFI se usa una copia temporal de las variables OVMF, que se borra al cerrar la VM. Para usar otro firmware: `OVMF_CODE=/ruta/CODE.fd OVMF_VARS=/ruta/VARS.fd scripts/test-qemu.sh uefi`.

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
