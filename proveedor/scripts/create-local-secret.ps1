# Generación local del secreto. No imprime ni copia el valor al portapapeles.
$ErrorActionPreference = 'Stop'
$providerRoot = Split-Path $PSScriptRoot -Parent
$target = Join-Path $providerRoot '.env'
if (Test-Path -LiteralPath $target) { throw '.env ya existe; no se sobrescribe.' }
$bytes = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try {
    $rng.GetBytes($bytes)
    $secret = ([System.BitConverter]::ToString($bytes)).Replace('-', '').ToLowerInvariant()
    $stream = [System.IO.File]::Open($target, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        $writer = New-Object System.IO.StreamWriter($stream, (New-Object System.Text.UTF8Encoding($false)))
        try { $writer.WriteLine('P05_API_KEY=' + $secret) } finally { $writer.Dispose() }
    } finally { $stream.Dispose() }
    Write-Output 'Secreto generado en proveedor/.env (ignorado por Git). No compartir ni registrar su contenido.'
} finally {
    $rng.Dispose()
    [Array]::Clear($bytes, 0, $bytes.Length)
    $secret = $null
}
