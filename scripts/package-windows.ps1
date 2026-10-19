[CmdletBinding()]
param(
    [string]$VcRedistDirectory
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $IsWindows) { throw 'Build the Windows installer on Windows with PowerShell 7.' }
$root = Split-Path $PSScriptRoot -Parent
$pubspec = Get-Content (Join-Path $root 'pubspec.yaml') -Raw
if ($pubspec -notmatch '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$') {
    throw 'pubspec.yaml must contain version: MAJOR.MINOR.PATCH+BUILD'
}
$release = $Matches[1]
$build = $Matches[2]
$version = "$release+$build"
$bundle = Join-Path $root 'build/windows/x64/runner/Release'
foreach ($relative in @('abacus.exe', 'flutter_windows.dll', 'data/app.so', 'data/icudtl.dat', 'data/flutter_assets')) {
    if (-not (Test-Path (Join-Path $bundle $relative))) { throw 'Run fvm flutter build windows --release first.' }
}
$binaryVersion = (Get-Item (Join-Path $bundle 'abacus.exe')).VersionInfo
if ($binaryVersion.ProductVersion -ne $version) { throw 'Release build version does not match pubspec.yaml; rebuild.' }
$compiler = Get-Command ISCC.exe -ErrorAction SilentlyContinue
$iscc = if ($compiler) { $compiler.Source } else { Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe' }
if (-not (Test-Path $iscc)) { throw 'Install Inno Setup 6 (ISCC.exe) before packaging.' }

# Copy only redistributable CRT libraries shipped with Visual Studio, never DLLs
# from Windows/System32. App-local runtime keeps this installer per-user.
if (-not $VcRedistDirectory) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (-not (Test-Path $vswhere)) { throw 'vswhere.exe not found; pass -VcRedistDirectory with a VS x64 CRT redist directory.' }
    $visualStudio = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($LASTEXITCODE -ne 0 -or -not $visualStudio) { throw 'Visual Studio C++ tools were not found.' }
    $redistRoot = Join-Path $visualStudio.Trim() 'VC/Redist/MSVC'
    $redistVersions = Get-ChildItem $redistRoot -Directory | Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } | Sort-Object { [version]$_.Name } -Descending
    foreach ($candidate in $redistVersions) {
        $crt = Get-ChildItem (Join-Path $candidate.FullName 'x64/Microsoft.VC*.CRT') -Directory | Select-Object -First 1
        if ($crt) { $VcRedistDirectory = $crt.FullName; break }
    }
}
if (-not $VcRedistDirectory) { throw 'No x64 Visual C++ CRT redistributables were found.' }
foreach ($dll in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
    if (-not (Test-Path (Join-Path $VcRedistDirectory $dll))) { throw "Missing redistributable: $dll" }
}
$dist = Join-Path $root 'dist'
New-Item $dist -ItemType Directory -Force | Out-Null
$work = Join-Path ([IO.Path]::GetTempPath()) ('abacus-package-' + [guid]::NewGuid().ToString('N'))
$stage = Join-Path $work 'payload'
New-Item $stage -ItemType Directory -Force | Out-Null
try {
    Copy-Item (Join-Path $bundle '*') $stage -Recurse
    Copy-Item (Join-Path $VcRedistDirectory '*.dll') $stage -Force
    $files = @(Get-ChildItem $stage -File -Recurse | Sort-Object FullName | ForEach-Object {
        [ordered]@{ path = [IO.Path]::GetRelativePath($stage, $_.FullName); sha256 = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
    })
    [ordered]@{ version = $version; files = $files } | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $stage 'abacus-package-manifest.json') -Encoding utf8
    & $iscc "/DAppVersion=$version" "/DFileVersion=$release.$build" "/DSourceDir=$stage" "/DOutputDir=$work" (Join-Path $root 'packaging/windows/abacus.iss')
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed with exit code $LASTEXITCODE" }
    $package = Join-Path $dist 'abacus-windows-setup.exe'
    Move-Item (Join-Path $work 'abacus-windows-setup.exe') $package -Force
    $hash = (Get-FileHash $package -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  abacus-windows-setup.exe" | Set-Content "$package.sha256" -Encoding ascii
    $files.path | Set-Content (Join-Path $dist 'abacus-windows-files.txt') -Encoding utf8
    Write-Output "Package complete: $package"
    Write-Output "Visual C++ runtime source: $VcRedistDirectory"
} finally {
    Remove-Item $work -Recurse -Force
}
