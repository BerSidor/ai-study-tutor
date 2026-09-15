# Copies the canonical TUTOR.md into every active course folder.
# Run after any edit to TUTOR.md. Courses are plain copies (not hardlinks) because
# Cowork's file bridge refuses to read hardlinked files (observed 2026-09-14).
$root = $PSScriptRoot
$src  = Join-Path $root "TUTOR.md"
$courses = @("COP3540", "CEN5035", "CAP4770", "EXAMPLE101")

$stamp = (Select-String -Path $src -Pattern 'Version: (\S+?)\.\*\*' | Select-Object -First 1).Matches[0].Groups[1].Value
foreach ($c in $courses) {
    $dst = Join-Path $root "$c\TUTOR.md"
    Copy-Item -Path $src -Destination $dst -Force
    $ok = (Get-FileHash $src).Hash -eq (Get-FileHash $dst).Hash
    "{0,-8} {1}" -f $c, $(if ($ok) { "synced ($stamp)" } else { "MISMATCH" })
}
