# Spec Delta

## Purpose

Instalar MKLinux OS en un disco desde la sesión live, en español y sin conexión a internet, de modo que el sistema instalado arranque por sí solo y conserve la identidad de MKLinux OS.

## ADDED Requirements

### Requirement: Lanzamiento desde la sesión live
La sesión live SHALL mostrar en el escritorio de XFCE un lanzador "Instalar MKLinux OS" que abre el instalador gráfico con privilegios de administrador, sin pedir contraseña al usuario `mk` y sin diálogos de "lanzador no confiable". El lanzador SHALL estar también en el menú de aplicaciones, en la categoría Sistema.

#### Scenario: Ícono en el escritorio
- **WHEN** termina el arranque de la sesión live y aparece el escritorio
- **THEN** el escritorio muestra el ícono "Instalar MKLinux OS"

#### Scenario: Abrir el instalador
- **WHEN** el usuario hace doble clic en el ícono "Instalar MKLinux OS"
- **THEN** se abre el instalador, sin pedir contraseña ni confirmar que el lanzador es de confianza

### Requirement: Idioma y valores por defecto
El instalador SHALL mostrarse en español y SHALL proponer por defecto el idioma `es_CO.UTF-8`, la distribución de teclado `latam` y la zona horaria `America/Bogota`. Todos los valores SHALL poder cambiarse. Los textos y la marca SHALL nombrar a MKLinux OS, no a Debian.

#### Scenario: Valores propuestos
- **WHEN** el usuario abre el instalador y avanza por las páginas de bienvenida, ubicación y teclado sin cambiar nada
- **THEN** la interfaz está en español
- **AND** la ubicación propuesta es `America/Bogota` con idioma `es_CO.UTF-8`
- **AND** el teclado propuesto es `latam`

#### Scenario: Marca
- **WHEN** el usuario abre el instalador
- **THEN** la página de bienvenida y el título de la ventana muestran "MKLinux OS" y no muestran "Debian"

### Requirement: Opciones de particionado
La página de particionado SHALL ofrecer "Borrar disco" y "Particionado manual", y SHALL NOT ofrecer instalar junto a otro sistema ni reemplazar una partición.

#### Scenario: Opciones disponibles
- **GIVEN** un disco que ya contiene particiones
- **WHEN** el usuario llega a la página de particionado
- **THEN** solo se ofrecen las opciones "Borrar disco" y "Particionado manual"

### Requirement: Cifrado opcional
En la opción "Borrar disco", el instalador SHALL ofrecer cifrar el sistema con LUKS, desactivado por defecto. Si el usuario lo activa, el sistema instalado SHALL pedir la contraseña de cifrado al arrancar y SHALL arrancar con ella.

#### Scenario: Instalación cifrada
- **GIVEN** una instalación con "Borrar disco" y la casilla de cifrado activada con una contraseña
- **WHEN** el sistema instalado arranca
- **THEN** pide la contraseña de cifrado antes de montar el sistema
- **AND** con la contraseña correcta llega a la pantalla de inicio de sesión
- **AND** `lsblk -o NAME,TYPE` muestra un dispositivo de tipo `crypt`

### Requirement: Instalación en BIOS y UEFI sin red
El instalador SHALL instalar un sistema que arranque desde el disco tanto en firmware BIOS como UEFI, sin conexión a internet durante la instalación.

#### Scenario: Instalación BIOS sin red
- **GIVEN** una VM BIOS sin red, con la ISO y un disco vacío
- **WHEN** el usuario instala con "Borrar disco" y reinicia sin la ISO
- **THEN** el sistema arranca desde el disco hasta la pantalla de inicio de sesión de LightDM

#### Scenario: Instalación UEFI
- **GIVEN** una VM UEFI con la ISO y un disco vacío
- **WHEN** el usuario instala con "Borrar disco" y reinicia sin la ISO
- **THEN** el sistema arranca desde el disco hasta la pantalla de inicio de sesión de LightDM
- **AND** `[ -d /sys/firmware/efi ]` es verdadero en el sistema instalado

### Requirement: Cuenta y escritorio del sistema instalado
El sistema instalado SHALL tener la cuenta de usuario creada en el instalador, con su contraseña y permisos de `sudo`, y SHALL iniciar sesión en el escritorio XFCE desde LightDM.

#### Scenario: Inicio de sesión
- **GIVEN** un sistema instalado con el usuario `prueba`
- **WHEN** el usuario inicia sesión en LightDM como `prueba` con su contraseña
- **THEN** llega al escritorio XFCE
- **AND** `sudo true` con la contraseña de `prueba` termina con código 0

### Requirement: Sin restos de la sesión live
El sistema instalado SHALL NOT contener el usuario live `mk`, los paquetes de la sesión live (`live-boot`, `live-config`, `live-config-systemd`, `live-tools`) ni el instalador (`calamares`, `mklinux-calamares-settings`).

#### Scenario: Paquetes y usuario live ausentes
- **WHEN** se ejecuta `dpkg -l live-boot live-config live-config-systemd live-tools calamares mklinux-calamares-settings` en el sistema instalado
- **THEN** ninguno aparece como instalado (`ii`)
- **AND** `getent passwd mk` no devuelve nada

### Requirement: Fuentes de APT del sistema instalado
Las fuentes de APT del sistema instalado SHALL apuntar a los repositorios de Debian `trixie`, `trixie-updates` y `trixie-security`, con los componentes `main`, `contrib`, `non-free` y `non-free-firmware`, y SHALL NOT referirse al medio de instalación.

#### Scenario: Actualización de índices
- **WHEN** se ejecuta `sudo apt-get update` en el sistema instalado con conexión a internet
- **THEN** termina con código 0, sin errores, usando los repositorios de Debian `trixie`, `trixie-updates` y `trixie-security`
