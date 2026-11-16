# os-identity Specification

## Purpose

Hacer que el sistema se identifique como MKLinux OS ante usuarios y programas, sin dejar de declararse compatible con Debian.

## Requirements

### Requirement: Identidad en os-release
El sistema SHALL exponer en `/etc/os-release` los campos `NAME="MKLinux OS"`, `ID=mklinux`, `ID_LIKE=debian`, `PRETTY_NAME` con el nombre y la versión de MKLinux OS, y `VERSION_CODENAME=trixie`.

#### Scenario: Consulta de os-release
- **WHEN** el usuario ejecuta `cat /etc/os-release` en la sesión live
- **THEN** la salida contiene `NAME="MKLinux OS"`
- **AND** contiene `ID=mklinux`
- **AND** contiene `ID_LIKE=debian`
- **AND** contiene `VERSION_CODENAME=trixie`

#### Scenario: Consulta por herramientas estándar
- **WHEN** el usuario ejecuta `hostnamectl` en la sesión live
- **THEN** la línea `Operating System` muestra el `PRETTY_NAME` de MKLinux OS

### Requirement: Identidad entregada como paquete propio
La identidad SHALL instalarse mediante un paquete `.deb` propio `mklinux-identity`, sin modificar ningún paquete de Debian, y SHALL mantenerse aunque se actualice el paquete `base-files` de Debian.

#### Scenario: Paquete instalado
- **WHEN** el usuario ejecuta `dpkg -s mklinux-identity` en la sesión live
- **THEN** el paquete aparece como instalado

#### Scenario: Actualización de base-files
- **GIVEN** la sesión live con `mklinux-identity` instalado
- **WHEN** se reinstala el paquete `base-files` con `sudo apt install --reinstall base-files`
- **THEN** `/etc/os-release` sigue mostrando `NAME="MKLinux OS"`

### Requirement: Nombre del equipo
El sistema live SHALL usar `mklinux` como nombre de equipo.

#### Scenario: Hostname
- **WHEN** el usuario ejecuta `hostname` en la sesión live
- **THEN** la salida es `mklinux`

### Requirement: Identidad en el sistema instalado
El sistema instalado desde la ISO SHALL conservar la identidad de MKLinux OS: `/etc/os-release` con los mismos campos que la sesión live y el paquete `mklinux-identity` instalado. El instalador SHALL proponer `mklinux` como nombre de equipo por defecto.

#### Scenario: os-release instalado
- **WHEN** el usuario ejecuta `cat /etc/os-release` en el sistema instalado
- **THEN** la salida contiene `NAME="MKLinux OS"`, `ID=mklinux` e `ID_LIKE=debian`
- **AND** `dpkg -s mklinux-identity` muestra el paquete como instalado

#### Scenario: Nombre de equipo propuesto
- **WHEN** el usuario llega a la página de usuarios del instalador
- **THEN** el campo del nombre del equipo propone `mklinux`
