param(
    [Parameter(Mandatory = $true)]
    [string] $EvidenceDirectory
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$executable = Join-Path $env:LOCALAPPDATA 'Programs/Abacus/abacus.exe'
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
    throw "Installed executable is missing: $executable"
}
New-Item -ItemType Directory -Path $EvidenceDirectory -Force | Out-Null
$evidence = (Resolve-Path -LiteralPath $EvidenceDirectory).Path
$report = Join-Path $evidence 'smoke.txt'
"executable=$executable" | Set-Content -LiteralPath $report
$application = Start-Process -FilePath $executable -PassThru `
    -RedirectStandardOutput (Join-Path $evidence 'application-stdout.log') `
    -RedirectStandardError (Join-Path $evidence 'application-stderr.log')
try {
    "pid=$($application.Id)" | Add-Content -LiteralPath $report
    foreach ($second in 1..5) {
        Start-Sleep -Seconds 1
        $application.Refresh()
        if ($application.HasExited) {
            throw "Installed application exited during startup (exit $($application.ExitCode)); see application logs."
        }
    }
    "window_handle=$($application.MainWindowHandle)" | Add-Content -LiteralPath $report
    "alive_after_seconds=5`nresult=passed" | Add-Content -LiteralPath $report
    Write-Host "Installed application remained alive for five seconds: $executable"
} finally {
    $application.Refresh()
    if (-not $application.HasExited) {
        $application.Kill()
        $application.WaitForExit()
    }
    $application.Dispose()
}
