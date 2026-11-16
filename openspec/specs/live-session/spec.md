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

### Requirement: Audio
La sesión live SHALL tener un servidor de sonido en ejecución para el usuario `mk` y un control de volumen en el panel de XFCE.

#### Scenario: Servidor de sonido activo
- **WHEN** el usuario ejecuta `pactl info` en una terminal de la sesión live
- **THEN** el comando termina con código 0 y muestra un `Server Name`

#### Scenario: Control de volumen
- **WHEN** termina el arranque y aparece el escritorio
- **THEN** el panel de XFCE muestra un indicador de volumen

### Requirement: Red gestionable por el usuario
La sesión live SHALL permitir al usuario `mk` ver y gestionar conexiones de red, incluidas redes Wi-Fi, desde el panel de XFCE sin usar la terminal ni `sudo`.

#### Scenario: Conexión cableada en la VM
- **WHEN** la sesión live arranca en QEMU con la red de usuario por defecto
- **THEN** `nmcli -t -f STATE general` muestra `connected`
- **AND** el panel muestra el indicador de red

#### Scenario: Permisos de gestión de red
- **WHEN** el usuario ejecuta `nmcli general permissions` en la sesión live
- **THEN** `org.freedesktop.NetworkManager.network-control` y `org.freedesktop.NetworkManager.enable-disable-wifi` aparecen como `yes`

### Requirement: Archivos y medios extraíbles
El gestor de archivos de la sesión live SHALL ofrecer papelera y montar medios extraíbles sin `sudo`.

#### Scenario: Papelera disponible
- **WHEN** el usuario ejecuta `gio trash ~/prueba` sobre un archivo creado por él
- **THEN** el comando termina con código 0 y el archivo aparece en `gio list trash://`

#### Scenario: Servicio de discos
- **WHEN** el usuario ejecuta `udisksctl status` en la sesión live
- **THEN** el comando termina con código 0 y lista los dispositivos de bloque

### Requirement: Navegador y enlaces
La sesión live SHALL incluir Firefox ESR y abrir los enlaces web con él desde otras aplicaciones.

#### Scenario: Apertura de un enlace
- **WHEN** el usuario ejecuta `xdg-open https://www.debian.org` en la sesión live
- **THEN** se abre la página en Firefox ESR

### Requirement: Español en las aplicaciones
Las aplicaciones de la sesión live SHALL mostrarse en español y SHALL tener corrector ortográfico en español.

#### Scenario: Interfaz en español
- **WHEN** el usuario abre el menú de aplicaciones de XFCE
- **THEN** los nombres y categorías aparecen en español

#### Scenario: Corrector ortográfico
- **WHEN** el usuario ejecuta `echo "casa caza kasa" | aspell -l es list`
- **THEN** la salida es solo `kasa`
