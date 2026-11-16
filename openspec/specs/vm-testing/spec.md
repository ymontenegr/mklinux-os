# vm-testing Specification

## Purpose

Permitir probar cualquier ISO de MKLinux OS en una máquina virtual local con un solo comando, en BIOS y en UEFI, sin exceder los recursos de la máquina de desarrollo.

## Requirements

### Requirement: Arranque en VM con un comando
El sistema SHALL proveer `scripts/test-qemu.sh`, que arranca una ISO en QEMU con aceleración KVM, 1536 MB de RAM y una ventana gráfica. Si no se indica una ISO, SHALL usar la más reciente de `out/`.

#### Scenario: ISO por defecto
- **GIVEN** existen varias ISO en `out/`
- **WHEN** el usuario ejecuta `scripts/test-qemu.sh bios`
- **THEN** se abre una VM que arranca la ISO más reciente de `out/`

#### Scenario: ISO explícita
- **WHEN** el usuario ejecuta `scripts/test-qemu.sh uefi ruta/a/imagen.iso`
- **THEN** se abre una VM que arranca `ruta/a/imagen.iso`

#### Scenario: Límite de memoria
- **WHEN** se arranca cualquier VM con el script
- **THEN** la VM tiene 1536 MB de RAM

### Requirement: Modos BIOS y UEFI
`scripts/test-qemu.sh` SHALL aceptar el modo `bios` o `uefi` como primer argumento. En modo `uefi` SHALL usar firmware OVMF con una copia propia de las variables UEFI, sin modificar los archivos de OVMF del sistema.

#### Scenario: Modo UEFI
- **WHEN** el usuario ejecuta `scripts/test-qemu.sh uefi`
- **THEN** la VM arranca con firmware OVMF

#### Scenario: Modo inválido
- **WHEN** el usuario ejecuta `scripts/test-qemu.sh otro`
- **THEN** el script termina con código distinto de 0 y muestra el uso correcto en español

### Requirement: Comprobación de requisitos
Antes de arrancar la VM, `scripts/test-qemu.sh` SHALL comprobar que existen QEMU, KVM (`/dev/kvm` accesible), OVMF (en modo `uefi`) y la ISO, y SHALL fallar con un mensaje en español que indique qué falta.

#### Scenario: Sin KVM
- **WHEN** `/dev/kvm` no existe o no es accesible por el usuario
- **THEN** el script termina con código distinto de 0 e indica cómo habilitar KVM

#### Scenario: Sin ISO
- **WHEN** no se indica ISO y `out/` no contiene ninguna
- **THEN** el script termina con código distinto de 0 e indica que se ejecute primero `scripts/build.sh`

### Requirement: Disco virtual para probar la instalación
`scripts/test-qemu.sh` SHALL aceptar la opción `--disco`, que conecta a la VM un disco virtual persistente de 20 GB en `out/`, propio de cada modo (`bios` o `uefi`) y creado vacío si no existe. Con `--disco`, la VM SHALL arrancar desde la ISO si se indica o hay una en `out/`. Con `--disco --sin-iso`, SHALL arrancar solo desde el disco. En modo `uefi`, las variables UEFI del disco SHALL conservarse entre ejecuciones, junto al disco. La opción `--sin-red` SHALL arrancar la VM sin tarjeta de red.

#### Scenario: Disco nuevo
- **GIVEN** no existe el disco virtual del modo `bios` en `out/`
- **WHEN** el usuario ejecuta `scripts/test-qemu.sh bios --disco`
- **THEN** se crea el disco vacío en `out/` y la VM arranca la ISO con ese disco conectado

#### Scenario: Arranque del sistema instalado
- **GIVEN** un disco del modo `uefi` en el que ya se instaló MKLinux OS
- **WHEN** el usuario ejecuta `scripts/test-qemu.sh uefi --disco --sin-iso`
- **THEN** la VM arranca desde el disco, sin ISO conectada

#### Scenario: Sin red
- **WHEN** el usuario ejecuta `scripts/test-qemu.sh bios --disco --sin-red`
- **THEN** la VM no tiene ninguna interfaz de red

#### Scenario: Empezar de cero
- **WHEN** el usuario borra el disco virtual de un modo (y sus variables UEFI) de `out/`
- **THEN** la siguiente ejecución con `--disco` en ese modo usa un disco vacío nuevo
