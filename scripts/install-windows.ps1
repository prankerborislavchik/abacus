[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PackagePath
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $IsWindows) { throw 'Install the Windows package on Windows with PowerShell 7.' }
$package = (Resolve-Path $PackagePath).Path
$destination = Join-Path $env:LOCALAPPDATA 'Programs/Abacus'
if (Test-Path $destination) { throw "Refusing to replace existing $destination; uninstall it first." }
$registration = 'HKCU:/Software/Microsoft/Windows/CurrentVersion/Uninstall/io.github.prankerborislavchik.abacus_is1'
if (Test-Path $registration) { throw 'Abacus is already registered; uninstall it first.' }
$log = Join-Path ([IO.Path]::GetTempPath()) ('abacus-install-' + [guid]::NewGuid().ToString('N') + '.log')
try {
    $process = Start-Process -FilePath $package -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-', "/DIR=`"$destination`"", "/LOG=`"$log`"") -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "Installer exited with code $($process.ExitCode). Log: $log" }
    foreach ($relative in @('abacus.exe', 'flutter_windows.dll', 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll', 'data/app.so', 'data/icudtl.dat', 'data/flutter_assets', 'unins000.exe', 'abacus-package-manifest.json')) {
        if (-not (Test-Path (Join-Path $destination $relative))) { throw "Installed app is incomplete: $relative" }
    }
    $manifest = Get-Content (Join-Path $destination 'abacus-package-manifest.json') -Raw | ConvertFrom-Json
    foreach ($file in $manifest.files) {
        $installedFile = Join-Path $destination $file.path
        if ((Get-FileHash $installedFile -Algorithm SHA256).Hash.ToLowerInvariant() -ne $file.sha256) { throw "Installed file differs from packaged file: $($file.path)" }
    }
    $entry = Get-ItemProperty $registration
    if ($entry.DisplayVersion -ne $manifest.version) { throw 'Installed registration version does not match packaged version.' }
    $shortcut = Join-Path ([Environment]::GetFolderPath('Programs')) 'Abacus.lnk'
    if (-not (Test-Path $shortcut)) { throw 'Abacus Start Menu shortcut is missing.' }
    Write-Output "Installed version: $($entry.DisplayVersion)"
    Write-Output "Installed executable: $(Join-Path $destination 'abacus.exe')"
} finally {
    if (Test-Path $log) { Get-Content $log | Write-Output }
}
