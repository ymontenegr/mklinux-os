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
