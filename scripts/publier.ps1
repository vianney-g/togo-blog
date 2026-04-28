# publier.ps1 — Script de publication pour Tiphaine
# Double-clic → fenêtre GUI → git add/commit/push → MessageBox résultat

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$contentDir = Join-Path $env:USERPROFILE "togo-blog-content"

# Vérifier que le répertoire existe
if (-not (Test-Path $contentDir)) {
    [Windows.Forms.MessageBox]::Show(
        "Le dossier togo-blog-content n'a pas été trouvé.`n`nChemin attendu : $contentDir",
        "❌ Erreur de configuration",
        'OK', 'Error'
    )
    exit 1
}

Set-Location $contentDir

# --- Création de la fenêtre ---
$form = New-Object Windows.Forms.Form
$form.Text = "📝 Publier un article"
$form.Size = New-Object Drawing.Size(420, 220)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$label = New-Object Windows.Forms.Label
$label.Text = "Message (optionnel) :"
$label.Location = New-Object Drawing.Point(20, 20)
$label.Size = New-Object Drawing.Size(360, 20)
$form.Controls.Add($label)

$txt = New-Object Windows.Forms.TextBox
$txt.Location = New-Object Drawing.Point(20, 45)
$txt.Size = New-Object Drawing.Size(360, 25)
$txt.PlaceholderText = "nouvel article"
$form.Controls.Add($txt)

$btn = New-Object Windows.Forms.Button
$btn.Text = "📝 Publier"
$btn.Location = New-Object Drawing.Point(130, 90)
$btn.Size = New-Object Drawing.Size(140, 45)
$btn.Font = New-Object Drawing.Font("Segoe UI", 12)
$form.Controls.Add($btn)

$btn.Add_Click({
    $btn.Enabled = $false
    $btn.Text = "Publication..."

    try {
        # Vérifier s'il y a des modifications
        $status = & git status --porcelain 2>&1
        if (-not $status) {
            [Windows.Forms.MessageBox]::Show(
                "Rien à publier — aucune modification détectée.",
                "ℹ️ Information", 'OK', 'Information'
            )
            $btn.Enabled = $true
            $btn.Text = "📝 Publier"
            return
        }

        # git add
        & git add . 2>&1 | Out-Null

        # git commit
        $msg = if ($txt.Text.Trim()) { $txt.Text.Trim() } else { "nouvel article" }
        $commitOutput = & git commit -m $msg 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            [Windows.Forms.MessageBox]::Show(
                "Publication refusée :`n`n$commitOutput",
                "❌ Erreur", 'OK', 'Error'
            )
            $btn.Enabled = $true
            $btn.Text = "📝 Publier"
            return
        }

        # git push
        $pushOutput = & git push 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            [Windows.Forms.MessageBox]::Show(
                "Article publié !`nLe site sera à jour dans ~2 minutes.",
                "✅ Succès", 'OK', 'Information'
            )
        } else {
            [Windows.Forms.MessageBox]::Show(
                "L'article est sauvegardé localement, mais le push a échoué.`n`nRéessayez plus tard quand la connexion sera revenue.`n`nDétails : $pushOutput",
                "⚠️ Pas de connexion ?", 'OK', 'Warning'
            )
        }
    } catch {
        [Windows.Forms.MessageBox]::Show(
            "Erreur inattendue :`n`n$($_.Exception.Message)",
            "❌ Erreur", 'OK', 'Error'
        )
    }

    $btn.Enabled = $true
    $btn.Text = "📝 Publier"
})

[void]$form.ShowDialog()
