# Ejecutar solo con una versión devuelta por /services/data de la organización P05 verificada.
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9]{2,3}\.0$')]
    [string]$ApiVersion
)
$ErrorActionPreference = 'Stop'
if ([decimal]$ApiVersion -lt 60) { throw 'Esta sonda requiere API 60.0 o superior (UUID).' }
$projectRoot = Split-Path $PSScriptRoot -Parent
$files = @{
    'sfdx-project.json' = 'sfdx-project.json.template'
    'force-app/main/default/classes/P05ConsultaTarifa.cls-meta.xml' = 'ApexClass.cls-meta.xml.template'
    'force-app/main/default/classes/P05ConsultaTarifaTest.cls-meta.xml' = 'ApexClass.cls-meta.xml.template'
}
foreach ($relative in $files.Keys) {
    if (Test-Path -LiteralPath (Join-Path $projectRoot $relative)) {
        throw ('No se sobrescribe el archivo existente: ' + $relative)
    }
}
foreach ($relative in $files.Keys) {
    $template = Join-Path $projectRoot ('templates/' + $files[$relative])
    $content = [System.IO.File]::ReadAllText($template).Replace('__API_VERSION__', $ApiVersion)
    [System.IO.File]::WriteAllText((Join-Path $projectRoot $relative), $content, (New-Object System.Text.UTF8Encoding($false)))
}
Write-Output 'Proyecto DX preparado localmente; no se ha desplegado.'
