# Spec Delta

## ADDED Requirements

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
