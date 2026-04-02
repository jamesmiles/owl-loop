$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportDir = Join-Path $ScriptDir "report"
$Header = Join-Path $ScriptDir "header.md"
$FooterTemplate = Join-Path $ScriptDir "footer.md"

if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir | Out-Null
}

# Collect owl test files in natural sort order
$OwlFiles = Get-ChildItem -Path $ScriptDir -Filter "owl-*.md" | Sort-Object Name

if ($OwlFiles.Count -eq 0) {
    Write-Host "No owl-*.md test files found in $ScriptDir"
    exit 1
}

Write-Host "=== Owl Loop Test Runner ==="
Write-Host "Found $($OwlFiles.Count) test(s)"
Write-Host ""

foreach ($OwlFile in $OwlFiles) {
    $TestName = $OwlFile.BaseName
    $OutputFile = Join-Path $ReportDir "$TestName-output.json"

    Write-Host "--- Running: $TestName ---"

    # Build the prompt: header + test file + footer (with output path substituted)
    $HeaderContent = Get-Content $Header -Raw
    $TestContent = Get-Content $OwlFile.FullName -Raw
    $FooterContent = (Get-Content $FooterTemplate -Raw) -replace '\{\{OUTPUT_PATH\}\}', $OutputFile

    $Prompt = "$HeaderContent`n`n$TestContent`n`n$FooterContent"

    # Launch Claude in non-interactive mode
    claude --dangerously-skip-permissions -p $Prompt --output-format text

    # Check if output was produced
    if (Test-Path $OutputFile) {
        Write-Host "[OK] $TestName - result written to $OutputFile"
    } else {
        Write-Host "[FAIL] $TestName - no output file produced, creating failure record"
        @{
            test         = $TestName
            score        = 0
            errors       = @("Agent did not produce an output file")
            difficulties = @()
        } | ConvertTo-Json | Set-Content $OutputFile
    }

    Write-Host ""
}

# --- Aggregate Report ---
Write-Host "=== Aggregate Report ==="
Write-Host ""

$TotalScore = 0
$TestCount = 0
$AllErrors = @()
$AllDifficulties = @()

foreach ($OwlFile in $OwlFiles) {
    $TestName = $OwlFile.BaseName
    $OutputFile = Join-Path $ReportDir "$TestName-output.json"

    if (-not (Test-Path $OutputFile)) {
        continue
    }

    $Result = Get-Content $OutputFile -Raw | ConvertFrom-Json
    $Score = if ($Result.score) { $Result.score } else { 0 }
    $TotalScore += $Score
    $TestCount++

    # Collect errors with test name prefix
    if ($Result.errors) {
        foreach ($Err in $Result.errors) {
            if ($Err) { $AllErrors += "[$TestName] $Err" }
        }
    }

    # Collect difficulties with test name prefix
    if ($Result.difficulties) {
        foreach ($Diff in $Result.difficulties) {
            if ($Diff) { $AllDifficulties += "[$TestName] $Diff" }
        }
    }

    Write-Host "  ${TestName}: score=$Score/10"
}

Write-Host ""

if ($TestCount -gt 0) {
    $Avg = [math]::Round($TotalScore / $TestCount, 1)
    Write-Host "Average score: $Avg / 10  ($TestCount test(s))"
} else {
    Write-Host "No test results to aggregate."
}

if ($AllErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors:"
    foreach ($E in $AllErrors) {
        Write-Host "  - $E"
    }
}

if ($AllDifficulties.Count -gt 0) {
    Write-Host ""
    Write-Host "Difficulties:"
    foreach ($D in $AllDifficulties) {
        Write-Host "  - $D"
    }
}

Write-Host ""
Write-Host "=== Done ==="
