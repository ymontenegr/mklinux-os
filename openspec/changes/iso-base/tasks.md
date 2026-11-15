# Tasks

## 1. Repositorio y estructura

- [ ] 1.1 Crear el repositorio público `mklinux-os` en GitHub, conectarlo como remote `origin` y hacer el primer push de `main` con el contenido actual (`gh repo create mklinux-os --public --source . --remote origin` + commit inicial + `git push -u origin main`); verificar que `gh repo view --json visibility -q .visibility` devuelve `PUBLIC` y que `git ls-remote origin main` coincide con `git rev-parse HEAD`
- [ ] 1.2 Crear `.gitignore` con `out/` y verificar con `git check-ignore out/x.iso` que el directorio queda ignorado
- [ ] 1.3 Crear la estructura `scripts/`, `live-build/auto/`, `live-build/config/package-lists/`, `live-build/config/includes.chroot/`, `packages/mklinux-identity/`, `docs/` y verificar con `find` que existen los directorios esperados

## 2. Paquete mklinux-identity

- [ ] 2.1 Crear `packages/mklinux-identity/DEBIAN/control` (Architecture: all, Depends: base-files) y `usr/lib/os-release` con NAME, PRETTY_NAME, ID, ID_LIKE, VERSION, VERSION_ID y VERSION_CODENAME (Decisión 5); verificar con `dpkg-deb --build` en un contenedor `debian:trixie` que el `.deb` se genera sin errores
- [ ] 2.2 Agregar `preinst` y `postrm` idempotentes según la Decisión 5 (`preinst` añade la desviación de `/usr/lib/os-release` solo si no existe; `postrm` la quita en `remove`, `purge` y `abort-install` solo si existe, y no hace nada en los demás casos); verificar en un contenedor `debian:trixie`: tras `dpkg -i`, `cat /etc/os-release` muestra `NAME="MKLinux OS"`; un segundo `dpkg -i` del mismo `.deb` termina sin error y `dpkg-divert --list /usr/lib/os-release` muestra una sola desviación; tras `apt install --reinstall base-files` sigue mostrando MKLinux OS; ejecutar `preinst install` y luego `postrm abort-install` deja el sistema sin desviación y con el `os-release` de Debian; y `dpkg -r mklinux-identity` restaura el `os-release` de Debian

## 3. Configuración de live-build

- [ ] 3.1 Escribir `live-build/auto/config` con las opciones de la Decisión 3 (trixie, amd64, áreas, iso-hybrid, syslinux+grub-efi, `--apt-recommends true`, bootappend-live con `username=mk hostname=mklinux locales=es_CO.UTF-8 keyboard-layouts=latam timezone=America/Bogota`, compresión zstd/xz según `MKLINUX_RELEASE`, nombre de volumen); verificar que `lb config` corre sin errores dentro de un contenedor `debian:trixie`
- [ ] 3.2 Escribir `live-build/config/package-lists/mklinux.list.chroot` con los paquetes de la Decisión 4, incluidos `firmware-linux-free`, `firmware-misc-nonfree`, `firmware-iwlwifi`, `firmware-realtek` y `wpasupplicant`; verificar con `apt-get install --simulate` en un contenedor `debian:trixie` (con `non-free-firmware` habilitado) que todos los nombres se resuelven
- [ ] 3.3 Agregar los archivos de respaldo `includes.chroot/etc/default/keyboard` (`XKBLAYOUT="latam"`) y `includes.chroot/etc/lightdm/lightdm.conf.d/50-mklinux.conf` (`user-session=xfce`); verificar que, tras `lb config`, aparecen en `config/includes.chroot/` del directorio de trabajo

## 4. Scripts de build

- [ ] 4.1 Escribir `scripts/container-build.sh` (instala live-build y dpkg-dev, construye `mklinux-identity` en `config/packages.chroot/`, copia `live-build/` a `/build`, ejecuta `lb config` y `lb build`, copia la ISO como `.partial` y la renombra al nombre final, ajusta el propietario a `HOST_UID:HOST_GID`); verificar con `bash -n` y `shellcheck`
- [ ] 4.2 Escribir `scripts/build.sh` (comprueba Podman con mensaje en español si falta, crea `out/` con `mkdir -p out` como el usuario del host **antes** de relanzar con `sudo`, relanza Podman con `sudo` en modo rootless, calcula `BUILD_DATE` en UTC, opción `--release`, monta el repo en solo lectura y `out/`, propaga el código de salida); verificar con `shellcheck`, comprobar que en un `PATH` sin `podman` termina con código distinto de 0 y el mensaje esperado, y que, partiendo de un repo sin `out/`, el script crea `out/` con el usuario actual (`stat -c %U out`) antes de invocar `sudo`
- [ ] 4.3 Documentar en `docs/build.md` (en español) requisitos del host, uso de `scripts/build.sh` y `--release`, duración y espacio aproximados, que el camino recomendado es descargar la ISO de CI y cómo hacerlo; verificar que los comandos documentados coinciden con las opciones reales del script

## 5. GitHub Actions y primer build completo

- [ ] 5.1 Escribir `.github/workflows/build-iso.yml` según la Decisión 7 (push a `main` + `workflow_dispatch`, `ubuntu-24.04`, `permissions: contents: read`, limpieza de disco, `scripts/build.sh`, `sha256sum`, `upload-artifact` con retención de 14 días, `concurrency`, `timeout-minutes: 90`); verificar la sintaxis con `actionlint`
- [ ] 5.2 Hacer push a `main` para lanzar el primer build completo en CI y verificar que el workflow termina en verde, que el artifact contiene `mklinux-os-<AAAAMMDD>-amd64.iso` y su `.sha256`, y que `sha256sum -c` es correcto tras descargarlo
- [ ] 5.3 Sobre la ISO descargada de CI, verificar que `unsquashfs -s` de `live/filesystem.squashfs` indica compresión zstd y que el tamaño de la ISO es menor de 2,5 GB (`du -h`)
- [ ] 5.4 (Opcional, no bloquea la aceptación) Ejecutar un build completo en local con `scripts/build.sh` y verificar que existe `out/mklinux-os-<AAAAMMDD>-amd64.iso`, que `out/` y la ISO pertenecen al usuario del host (`stat -c %U`), que se pueden borrar sin `sudo` y que `git status` no muestra archivos nuevos fuera de `out/`

## 6. Prueba en QEMU

- [ ] 6.1 Escribir `scripts/test-qemu.sh {bios|uefi} [ISO]` según la Decisión 6 (ISO más reciente de `out/` por defecto, comprobación de QEMU, `/dev/kvm`, OVMF e ISO con mensajes en español, copia temporal de `OVMF_VARS`, 1536 MB, `-smp 2`); verificar con `shellcheck` y comprobar que un modo inválido y un `out/` vacío terminan con código distinto de 0 y el mensaje esperado
- [ ] 6.2 Documentar en `docs/build.md` la sección de pruebas en QEMU (paquetes del host: `qemu-system-x86`, `ovmf`; permisos de `/dev/kvm`; cómo colocar en `out/` la ISO descargada de CI; uso del script) y la lista de comprobación de aceptación; verificar que los comandos documentados funcionan tal como están escritos

## 7. Aceptación en QEMU

- [ ] 7.1 Arrancar la ISO de CI con `scripts/test-qemu.sh bios` y verificar que llega sin intervención al escritorio XFCE del usuario `mk`, y que en una terminal `cat /etc/os-release` muestra `NAME="MKLinux OS"`, `ID=mklinux`, `ID_LIKE=debian` y `VERSION_CODENAME=trixie`
- [ ] 7.2 Arrancar la ISO con `scripts/test-qemu.sh uefi` y verificar lo mismo que en 7.1
- [ ] 7.3 En la sesión live, verificar los escenarios restantes de los specs: `whoami` → `mk`, `sudo true` → código 0, `hostname` → `mklinux`, `locale` → `LANG=es_CO.UTF-8`, `setxkbmap -query` → `layout: latam`, `date +%Z` → `-05`, `hostnamectl` muestra MKLinux OS y `dpkg -s mklinux-identity` lo muestra instalado

## Workflow follow-up

- Archivar el cambio (`openspec-archive-change`) cuando la aceptación en QEMU esté completa, para crear los specs principales en `openspec/specs/`.
