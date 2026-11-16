# Spec Delta

## MODIFIED Requirements

### Requirement: Tamaño máximo de la ISO de desarrollo
La ISO de desarrollo (compresión zstd, sin `--release`) SHALL pesar como máximo 1 200 000 000 bytes.

#### Scenario: ISO dentro del límite
- **WHEN** termina correctamente un build de desarrollo
- **THEN** `stat -c %s out/mklinux-os-<fecha>-amd64.iso` devuelve un valor menor o igual a 1200000000
