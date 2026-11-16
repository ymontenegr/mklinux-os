# Spec Delta

## MODIFIED Requirements

### Requirement: Control de tamaño en CI
El workflow de build SHALL informar el tamaño de la ISO en el resumen de cada ejecución y SHALL marcar la ejecución como fallida, sin publicar la ISO, si la ISO de desarrollo supera 1 200 000 000 bytes.

#### Scenario: ISO dentro del límite
- **WHEN** termina un build cuya ISO pesa 1 200 000 000 bytes o menos
- **THEN** el resumen de la ejecución muestra el tamaño de la ISO y el límite
- **AND** la ISO se publica como artifact

#### Scenario: ISO por encima del límite
- **WHEN** termina un build cuya ISO pesa más de 1 200 000 000 bytes
- **THEN** la ejecución del workflow aparece como fallida, indicando el tamaño y el límite
- **AND** no se publica ningún artifact de ISO
