# Spec Delta

## Purpose

Construir automáticamente la ISO de MKLinux OS en GitHub Actions con el mismo script que en local, para no depender de la máquina de desarrollo y tener siempre una imagen descargable de `main`.

## ADDED Requirements

### Requirement: Build automático en main
El repositorio SHALL tener el workflow `.github/workflows/build-iso.yml`, que construye la ISO en cada push a la rama `main` ejecutando `scripts/build.sh`, y que también puede lanzarse manualmente.

#### Scenario: Push a main
- **WHEN** se hace push de un commit a `main`
- **THEN** se ejecuta el workflow de build de la ISO para ese commit

#### Scenario: Ejecución manual
- **WHEN** un mantenedor lanza el workflow desde la pestaña Actions
- **THEN** se construye la ISO del commit seleccionado

### Requirement: Publicación como artifact
Cuando el build termina correctamente, el workflow SHALL publicar la ISO como artifact del workflow, con el mismo nombre de archivo que genera `scripts/build.sh`, junto con su suma SHA-256.

#### Scenario: Descarga de la ISO
- **WHEN** termina con éxito el workflow de un push a `main`
- **THEN** la ejecución tiene un artifact que contiene `mklinux-os-<AAAAMMDD>-amd64.iso` y su archivo `.sha256`

#### Scenario: Verificación de la suma
- **WHEN** se descarga el artifact y se ejecuta `sha256sum -c` sobre el archivo `.sha256`
- **THEN** la verificación es correcta

### Requirement: Fallo visible en CI
Si el build falla, el workflow SHALL marcarse como fallido y SHALL NOT publicar ninguna ISO.

#### Scenario: Build roto
- **WHEN** `scripts/build.sh` termina con código distinto de 0 en CI
- **THEN** la ejecución del workflow aparece como fallida y no tiene artifact de ISO
