param(
    [string]$folder,
    [string[]]$patterns = @("*.cs", "*.vb", "*.aspx")
)

$scriptName = [System.IO.Path]::GetFileName($PSCommandPath)
if ([string]::IsNullOrWhiteSpace($folder)) {
    Write-Host "Usage: .\$scriptName -folder <directory> [-patterns <pattern1,pattern2,...>]"
    Write-Host "Example 1: .\$scriptName -folder ."
    Write-Host "Example 2: .\$scriptName -folder d:\path\to\your\project\App_Code"
    Write-Host "Example 3: .\$scriptName -folder . -patterns *.cs,*.vb,*.aspx"
    exit 1
}

$files = @(Get-ChildItem -Path (Join-Path $folder "*") -Include $patterns -File -Recurse)
if ($files.Count -eq 0) {
    Write-Host "No matching files found under: $folder ; patterns: $($patterns -join ', ')"
    exit 0
}
[System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
$ansiEncoding = [System.Text.Encoding]::GetEncoding([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage)
$utf8BomEncoding = New-Object System.Text.UTF8Encoding($true)
$utf8StrictEncoding = New-Object System.Text.UTF8Encoding($false, $true)

foreach ($file in $files) {
    $path = $file.FullName
    
    # Read first 3 bytes to check for BOM
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $isBom = $bytes.Length -ge 3 -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
    
    if ($isBom) {
        Write-Host "[SKIP] $path (Already UTF-8 BOM)" -ForegroundColor Yellow
    } else {
        $isValidUtf8 = $false
        try {
            [void]$utf8StrictEncoding.GetString($bytes)
            $isValidUtf8 = $true
        } catch [System.Text.DecoderFallbackException] {
            $isValidUtf8 = $false
        }

        if ($isValidUtf8) {
            $content = [System.Text.Encoding]::UTF8.GetString($bytes)
            [System.IO.File]::WriteAllText($path, $content, $utf8BomEncoding)
            Write-Host "[NORMALIZED] $path (UTF-8 no BOM -> UTF-8 BOM)" -ForegroundColor Cyan
        } else {
            $content = $ansiEncoding.GetString($bytes)
            [System.IO.File]::WriteAllText($path, $content, $utf8BomEncoding)
            Write-Host "[CONVERTED] $path (ANSI/GBK -> UTF-8 BOM)" -ForegroundColor Green
        }
    }
}
