# Spec Delta

## MODIFIED Requirements

### Requirement: Audio
La sesión live SHALL tener un servidor de sonido en ejecución para el usuario `mk` y un control de volumen en el panel de XFCE.

#### Scenario: Servidor de sonido activo
- **WHEN** el usuario ejecuta `LC_ALL=C pactl info` en una terminal de la sesión live
- **THEN** el comando termina con código 0 y muestra un `Server Name`

#### Scenario: Control de volumen
- **WHEN** termina el arranque y aparece el escritorio
- **THEN** el panel de XFCE muestra un indicador de volumen
