$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host -Object 'Setting up...' -ForegroundColor 'Cyan'

# Instalar Spicetify CLI si no está instalado
if (-not (Get-Command -Name 'spicetify' -ErrorAction 'SilentlyContinue')) {
  Write-Host -Object 'Spicetify not found.' -ForegroundColor 'Yellow'
  Write-Host -Object 'Installing it for you...' -ForegroundColor 'Cyan'
  $Parameters = @{
    Uri             = 'https://raw.githubusercontent.com/spicetify/cli/main/install.ps1'
    UseBasicParsing = $true
  }
  Invoke-WebRequest @Parameters | Invoke-Expression
}

# Obtener la ruta del directorio de datos del usuario de Spicetify
spicetify path userdata | Out-Null
$spiceUserDataPath = (spicetify path userdata)
if (-not (Test-Path -Path $spiceUserDataPath -PathType 'Container' -ErrorAction 'SilentlyContinue')) {
  $spiceUserDataPath = "$env:APPDATA\spicetify"
}
$marketAppPath = "$spiceUserDataPath\CustomApps\marketplace"
$marketThemePath = "$spiceUserDataPath\Themes\marketplace"

# Verificar si hay un tema instalado
$isThemeInstalled = $(
  spicetify path -s | Out-Null
  -not $LASTEXITCODE
)
$currentTheme = (spicetify config current_theme)
$setTheme = $true

# Eliminar y crear carpetas para Marketplace
Write-Host -Object 'Removing and creating Marketplace folders...' -ForegroundColor 'Cyan'
Remove-Item -Path $marketAppPath, $marketThemePath -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null
New-Item -Path $marketAppPath, $marketThemePath -ItemType 'Directory' -Force | Out-Null

# Descargar e instalar Marketplace
Write-Host -Object 'Downloading Marketplace...' -ForegroundColor 'Cyan'
$marketArchivePath = "$marketAppPath\marketplace.zip"
$unpackedFolderPath = "$marketAppPath\marketplace-dist"
$Parameters = @{
  Uri             = 'https://github.com/spicetify/marketplace/releases/latest/download/marketplace.zip'
  UseBasicParsing = $true
  OutFile         = $marketArchivePath
}
Invoke-WebRequest @Parameters

Write-Host -Object 'Unzipping and installing...' -ForegroundColor 'Cyan'
Expand-Archive -Path $marketArchivePath -DestinationPath $marketAppPath -Force
Move-Item -Path "$unpackedFolderPath\*" -Destination $marketAppPath -Force
Remove-Item -Path $marketArchivePath, $unpackedFolderPath -Force
spicetify config custom_apps spicetify-marketplace- -q
spicetify config custom_apps marketplace
spicetify config inject_css 1 replace_colors 1

# Descargar el archivo de configuración para el tema de marcador de posición
Write-Host -Object 'Downloading placeholder theme...' -ForegroundColor 'Cyan'
$Parameters = @{
  Uri             = 'https://raw.githubusercontent.com/spicetify/marketplace/main/resources/color.ini'
  UseBasicParsing = $true
  OutFile         = "$marketThemePath\color.ini"
}
Invoke-WebRequest @Parameters

# Aplicar los cambios
Write-Host -Object 'Applying...' -ForegroundColor 'Cyan'

# Verificar si hay un tema instalado y si el tema actual no es 'marketplace'
if ($isThemeInstalled -and ($currentTheme -ne 'marketplace')) {
  # Configurar directamente el tema de Marketplace sin preguntar
  spicetify config current_theme marketplace
}

spicetify backup
spicetify apply

Write-Host -Object 'Done!' -ForegroundColor 'Green'
Write-Host -Object 'If nothing has happened, check the messages above for errors'
