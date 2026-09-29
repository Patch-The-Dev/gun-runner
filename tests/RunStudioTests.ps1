param(
    [string]$StudioPath
)

$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot
$place = Join-Path $env:TEMP 'GunRunnerTests.rbxlx'
$output = Join-Path $env:TEMP 'GunRunnerTests.log'
$runner = Join-Path $PSScriptRoot 'RunInStudio.luau'
$rojo = (Get-Command rojo -ErrorAction SilentlyContinue).Source
if (-not $rojo) {
    $rojo = Join-Path $env:USERPROFILE '.rokit\bin\rojo.exe'
}
if (-not (Test-Path -LiteralPath $rojo)) {
    throw 'Rojo was not found. Install the pinned tools with rokit install.'
}

if (-not $StudioPath) {
    $StudioPath = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Roblox\Versions\*\RobloxStudioBeta.exe') -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $StudioPath -or -not (Test-Path -LiteralPath $StudioPath)) {
    throw 'Roblox Studio was not found. Pass -StudioPath with the installed executable.'
}

Push-Location $repository
try {
    & $rojo build test.project.json --output $place
    if ($LASTEXITCODE -ne 0) {
        throw 'The Rojo test place build failed.'
    }
} finally {
    Pop-Location
}

Remove-Item -LiteralPath $output -ErrorAction SilentlyContinue
$arguments = '--task RunScript --localPlaceFile "{0}" --runScriptFile "{1}" --outputFile "{2}" --quitAfterExecution' -f $place, $runner, $output
$process = Start-Process -FilePath $StudioPath -ArgumentList $arguments -WindowStyle Hidden -PassThru
try {
    Wait-Process -Id $process.Id -Timeout 180 -ErrorAction Stop
} catch {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    throw 'Studio did not finish the test run within three minutes.'
}
$process.Refresh()

if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $output)) {
    throw "Studio did not produce a passing test report. Exit code: $($process.ExitCode)"
}
$report = Get-Content -LiteralPath $output -Raw
if ($report -notmatch '(?m)^\s*GUN_RUNNER_TESTS_PASS\s*$' -or $report -notmatch '(?m)^\s*\d+ passed, 0 failed, 0 skipped\s*$') {
    Write-Output $report
    throw 'Gun Runner Studio tests failed.'
}
$report -split '\r?\n' | Where-Object { $_ -match '^\d+ passed, 0 failed, 0 skipped$|^GUN_RUNNER_TESTS_PASS$' }
