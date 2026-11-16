# Spec Delta

## ADDED Requirements

### Requirement: Identidad en el sistema instalado
El sistema instalado desde la ISO SHALL conservar la identidad de MKLinux OS: `/etc/os-release` con los mismos campos que la sesión live y el paquete `mklinux-identity` instalado. El instalador SHALL proponer `mklinux` como nombre de equipo por defecto.

#### Scenario: os-release instalado
- **WHEN** el usuario ejecuta `cat /etc/os-release` en el sistema instalado
- **THEN** la salida contiene `NAME="MKLinux OS"`, `ID=mklinux` e `ID_LIKE=debian`
- **AND** `dpkg -s mklinux-identity` muestra el paquete como instalado

#### Scenario: Nombre de equipo propuesto
- **WHEN** el usuario llega a la página de usuarios del instalador
- **THEN** el campo del nombre del equipo propone `mklinux`
