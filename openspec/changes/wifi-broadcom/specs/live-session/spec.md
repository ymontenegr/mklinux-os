# Spec Delta

## ADDED Requirements

### Requirement: Wi-Fi Broadcom con brcmsmac
En equipos con una tarjeta Wi-Fi Broadcom que soporta el driver `brcmsmac` (BCM4313, BCM43224, BCM43225), la sesión live SHALL cargar ese driver y SHALL permitir al usuario `mk` conectarse a una red Wi-Fi desde el panel de XFCE.

#### Scenario: Driver en uso
- **GIVEN** la ISO arrancada desde una memoria USB en una MacBook Air 2012 (`MacBookAir5,2`, Broadcom BCM43224 `14e4:4353`)
- **WHEN** el usuario ejecuta `lspci -nnk -d 14e4:4353` en una terminal de la sesión live
- **THEN** la salida muestra `Kernel driver in use: bcma-pci-bridge`
- **AND** `lsmod` muestra `brcmsmac` y no muestra `b43`

#### Scenario: Redes Wi-Fi visibles
- **GIVEN** la misma máquina, en un lugar con al menos una red Wi-Fi
- **WHEN** el usuario ejecuta `nmcli device wifi list`
- **THEN** la salida muestra al menos una red

#### Scenario: Conexión desde el panel
- **GIVEN** la misma máquina y una red Wi-Fi con contraseña conocida
- **WHEN** el usuario elige esa red en el indicador de red del panel y escribe la contraseña
- **THEN** `nmcli -t -f TYPE,STATE device` muestra `wifi:connected`
