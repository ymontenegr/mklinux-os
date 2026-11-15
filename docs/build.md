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

   Con [GitHub CLI](https://cli.github.com/) se puede hacer desde la terminal:

   ```bash
   gh run download --repo ymontenegr/mklinux-os --dir out/ \
       "$(gh run list --repo ymontenegr/mklinux-os --workflow build-iso.yml \
           --branch main --status success --limit 1 --json databaseId -q '.[0].databaseId')"
   mv out/mklinux-os-*-amd64/* out/ && rmdir out/mklinux-os-*-amd64
   (cd out && sha256sum -c mklinux-os-*-amd64.iso.sha256)
   ```

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
