# install-hooks.ps1 — Configuration du repo content + raccourci bureau
# Usage : powershell -ExecutionPolicy Bypass -File install-hooks.ps1

# --- 1. Configurer git hooks sur le repo content ---
$contentDir = Join-Path $env:USERPROFILE "togo-blog-content"

if (Test-Path $contentDir) {
    Push-Location $contentDir
    git config core.hooksPath .githooks
    Write-Host "✅ Git hooks configurés (core.hooksPath → .githooks)"
    Pop-Location
} else {
    Write-Host "⚠️ Dossier $contentDir introuvable — hooks non configurés."
}

# --- 2. Créer le raccourci bureau "📝 Publier" ---
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "📝 Publier.lnk"
$scriptPath = Join-Path $env:USERPROFILE "togo-blog\scripts\publier.ps1"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$shortcut.WorkingDirectory = Join-Path $env:USERPROFILE "togo-blog-content"
$shortcut.Description = "Publier un article sur le blog"
$shortcut.IconLocation = "shell32.dll,21"
$shortcut.Save()

Write-Host "✅ Raccourci '📝 Publier' créé sur le bureau."
