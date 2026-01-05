$sshDir = Join-Path $env:USERPROFILE ".ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}
$keyPath = Join-Path $sshDir "id_ed25519"
if (-not (Test-Path $keyPath)) {
    ssh-keygen -t ed25519 -f $keyPath -N "" -q
    Write-Host "SSH key generated at $keyPath"
} else {
    Write-Host "SSH key already exists at $keyPath"
}
Get-Content "$keyPath.pub"
