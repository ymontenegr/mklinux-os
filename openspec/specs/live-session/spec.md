# live-session Specification

## Purpose

Definir lo que ve y obtiene quien arranca la ISO de MKLinux OS: un escritorio XFCE listo para usar, en español de Colombia, en equipos BIOS y UEFI.

## Requirements

### Requirement: Arranque BIOS y UEFI
La ISO SHALL ser híbrida y arrancar tanto en firmware BIOS (legacy) como en UEFI x86_64, desde medio óptico o desde una memoria USB.

#### Scenario: Arranque en BIOS
- **WHEN** se arranca la ISO en una máquina con firmware BIOS
- **THEN** aparece el menú de arranque de MKLinux OS y la entrada por defecto inicia la sesión live

#### Scenario: Arranque en UEFI
- **WHEN** se arranca la ISO en una máquina con firmware UEFI (sin Secure Boot)
- **THEN** aparece el menú de arranque de MKLinux OS y la entrada por defecto inicia la sesión live

### Requirement: Escritorio XFCE con inicio automático
La sesión live SHALL usar LightDM como gestor de inicio de sesión e iniciar automáticamente, sin pedir contraseña, una sesión XFCE del usuario `mk`.

#### Scenario: Llegada al escritorio
- **WHEN** termina el arranque de la entrada por defecto
- **THEN** se muestra el escritorio XFCE con la sesión del usuario `mk` iniciada, sin intervención del usuario

### Requirement: Usuario live
La sesión live SHALL tener un usuario `mk` con capacidad de administración mediante `sudo`.

#### Scenario: Identidad del usuario
- **WHEN** el usuario ejecuta `whoami` en una terminal de la sesión live
- **THEN** la salida es `mk`

#### Scenario: Administración
- **WHEN** el usuario ejecuta `sudo true` en la sesión live
- **THEN** el comando termina con código 0

### Requirement: Idioma, teclado y zona horaria
La sesión live SHALL usar el idioma `es_CO.UTF-8`, la distribución de teclado `latam` (en consola y en el escritorio) y la zona horaria `America/Bogota`.

#### Scenario: Configuración regional
- **WHEN** el usuario ejecuta `locale` en una terminal de la sesión live
- **THEN** `LANG` es `es_CO.UTF-8`

#### Scenario: Teclado
- **WHEN** el usuario ejecuta `setxkbmap -query` en la sesión XFCE
- **THEN** `layout` es `latam`

#### Scenario: Zona horaria
- **WHEN** el usuario ejecuta `date +%Z` en la sesión live
- **THEN** la salida es `-05`
