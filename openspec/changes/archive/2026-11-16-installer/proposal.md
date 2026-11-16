# Proposal: installer

## Why

Hoy MKLinux OS solo funciona como sesión live: todo se pierde al apagar y no se puede usar como estación de trabajo. La ISO ya arranca bien en hardware real (MacBook Air 2012, cambio `wifi-broadcom`), así que el paso siguiente es poder instalarla en el disco. Además, las herramientas de desarrollo con IA, el diferencial del proyecto, solo tienen sentido en un sistema instalado.

## What Changes

- La sesión live trae el instalador gráfico **Calamares**. En el escritorio aparece un ícono "Instalar MKLinux OS", confiable y listo para abrir.
- El instalador está en español. Por defecto propone `es_CO.UTF-8`, teclado `latam` y zona `America/Bogota`, y lleva el nombre y la marca de MKLinux OS.
- Particionado: "Borrar disco" y "Particionado manual". No se ofrece "Instalar junto a" otro sistema.
- Cifrado de disco completo (LUKS) opcional, desactivado por defecto.
- Instala y arranca tanto en equipos BIOS como UEFI, sin conexión a internet. Los paquetes del cargador de arranque y del cifrado van en un repositorio local dentro de la ISO.
- El sistema instalado:
  - conserva la identidad de MKLinux OS;
  - tiene el usuario y la contraseña elegidos en el instalador, con `sudo`;
  - no conserva el usuario live `mk`, los paquetes de la sesión live ni el propio instalador.
- Toda la configuración propia va en un paquete nuevo `mklinux-calamares-settings`, sin modificar paquetes de Debian.
- **BREAKING (límite acordado en `iso-size`):** el tamaño máximo de la ISO de desarrollo sube de 1 000 000 000 a 1 200 000 000 bytes, para que quepan Calamares (Qt 6 y bibliotecas de KDE) y los cambios siguientes.
- `scripts/test-qemu.sh` puede crear y usar un disco virtual, para instalar desde la ISO y luego arrancar el sistema instalado sin ella, en BIOS y en UEFI.
- Se corrige el escenario de audio de `live-session`: en español, `pactl info` muestra "Nombre del servidor", no `Server Name`.

## Capabilities

### New Capabilities

- `installer`: instalación de MKLinux OS en disco desde la sesión live (lanzamiento, idioma y valores por defecto, particionado, cifrado, BIOS/UEFI sin red, resultado del sistema instalado).

### Modified Capabilities

- `iso-build`: el tamaño máximo de la ISO de desarrollo pasa a 1 200 000 000 bytes.
- `ci-iso-build`: el control de tamaño en CI usa el nuevo límite.
- `vm-testing`: `scripts/test-qemu.sh` gana un disco virtual persistente para probar la instalación y el arranque del sistema instalado.
- `os-identity`: la identidad de MKLinux OS también se mantiene en el sistema instalado.
- `live-session`: el escenario "Servidor de sonido activo" deja de depender del idioma de la salida de `pactl`.

## Impact

- Archivos nuevos:
  - `packages/mklinux-calamares-settings/`: configuración de Calamares, marca, scripts de ayuda, lanzador y autostart del ícono.
  - `live-build/config/package-lists/*.list.binary`: repositorio local con GRUB y cryptsetup.
- Archivos modificados: listas de paquetes (`calamares`, `mklinux-calamares-settings`), `.github/workflows/build-iso.yml` (`MAX_ISO_BYTES`), `scripts/test-qemu.sh` y `docs/build.md`.
- Tamaño: unos +90 MB estimados (ISO de ~890 MB a ~980 MB).
- Pruebas: en la máquina de desarrollo, cada instalación en QEMU con 1536 MB de RAM es lenta, y los discos virtuales (qcow2, se llenan solo con lo que se escribe) ocupan unos 3–4 GB cada uno. Hay 24 GB libres.
- Riesgo: el particionado manual y el cifrado tocan discos reales. En este cambio solo se prueban en QEMU; la instalación en hardware real queda a criterio del mantenedor.
