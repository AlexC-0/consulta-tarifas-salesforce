# Materializa solo metadata sin secreto; la URL temporal queda en .local ignorado.
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^https://[a-z0-9-]+\.trycloudflare\.com/?$')]
    [string]$Endpoint
)
$ErrorActionPreference = 'Stop'
$salesforceRoot = Split-Path $PSScriptRoot -Parent
$repoRoot = Split-Path $salesforceRoot -Parent
$config = Get-Content -LiteralPath (Join-Path $salesforceRoot 'sfdx-project.json') -Raw | ConvertFrom-Json
$stage = Join-Path $repoRoot '.local/connection-metadata'
if (Test-Path -LiteralPath $stage) { throw 'Ya existe .local/connection-metadata; revisar antes de recrear.' }
foreach ($folder in @('externalCredentials','permissionsets','namedCredentials')) {
    [System.IO.Directory]::CreateDirectory((Join-Path $stage $folder)) | Out-Null
}
Copy-Item -LiteralPath (Join-Path $salesforceRoot 'force-app/main/default/externalCredentials/P05_Proveedor_Externo.externalCredential-meta.xml') -Destination (Join-Path $stage 'externalCredentials/P05_Proveedor_Externo.externalCredential')
Copy-Item -LiteralPath (Join-Path $salesforceRoot 'force-app/main/default/permissionsets/P05_Conexion_Proveedor.permissionset-meta.xml') -Destination (Join-Path $stage 'permissionsets/P05_Conexion_Proveedor.permissionset')
$template = [System.IO.File]::ReadAllText((Join-Path $salesforceRoot 'templates/P05_Proveedor.namedCredential.template'))
[System.IO.File]::WriteAllText((Join-Path $stage 'namedCredentials/P05_Proveedor.namedCredential'), $template.Replace('__HTTPS_ENDPOINT__', $Endpoint.TrimEnd('/')), (New-Object System.Text.UTF8Encoding($false)))
$manifest = @"
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types><members>P05_Proveedor_Externo</members><name>ExternalCredential</name></types>
    <types><members>P05_Conexion_Proveedor</members><name>PermissionSet</name></types>
    <types><members>P05_Proveedor</members><name>NamedCredential</name></types>
    <version>$($config.sourceApiVersion)</version>
</Package>
"@
[System.IO.File]::WriteAllText((Join-Path $stage 'package.xml'), $manifest, (New-Object System.Text.UTF8Encoding($false)))
Write-Output 'Paquete de conexion preparado en .local/connection-metadata, sin secreto.'
