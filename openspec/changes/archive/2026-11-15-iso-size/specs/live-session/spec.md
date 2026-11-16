# Spec Delta

## ADDED Requirements

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
