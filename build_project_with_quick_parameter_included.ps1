# ==============================================
# 🎯 ColorSlash Build Script - Windows 11 (stable)
# Versione: 0.1 (BETA1)
# Autore: Luca Bixx
# ==============================================
param(
    [switch]$Quick
)

# === CONFIG ===
$projectPath = "C:\colorslash"
$keystorePath = "$projectPath\keystore.jks"
$keystoreAlias = "upload"
$keystorePassword = "140596"
$logFile = "$projectPath\build_log.txt"

# === FUNZIONI ===

# Mostra una progress bar animata
function Show-Progress {
    param (
        [int]$Percent,
        [string]$Message
    )
    $barLength = 25
    $filledLength = [math]::Round(($Percent / 100) * $barLength)
    $bar = ('=' * $filledLength).PadRight($barLength)
    Write-Host ("r[{0}] {1}% - {2}" -f $bar, $Percent, $Message) -NoNewline
}

# Esegue un comando e mostra la progress bar
function Run-Step {
    param (
        [string]$Message,
        [string]$Command,
        [int]$ProgressValue
    )

    Show-Progress -Percent $ProgressValue -Message $Message
    try {
        & cmd /c $Command 2>&1 | Out-File -Append -FilePath $logFile
        Write-Host "n✅ $Message completato."
    } catch {
        Write-Host "n❌ Errore in: $Message"
        $_ | Out-File -Append -FilePath $logFile
    }
}

# Verifica o crea keystore
function Ensure-Keystore {
    if (-not (Test-Path $keystorePath)) {
        Write-Host "🔐 Creazione keystore mancante..."
        keytool -genkeypair 
            -v 
            -keystore $keystorePath 
            -storepass $keystorePassword 
            -keypass $keystorePassword 
            -alias $keystoreAlias 
            -keyalg RSA 
            -keysize 2048 
            -validity 10000 
            -dname "CN=ColorSlash, OU=Dev, O=ColorSlash, L=Roma, S=RM, C=IT" 
            2>&1 | Out-File -Append -FilePath $logFile
        Write-Host "✅ Keystore creato correttamente."
    } else {
        Write-Host "🔑 Keystore già presente."
    }
}

# Esegue il workflow principale
function Full-Build {
    Run-Step "Pulizia progetto" "flutter clean" 10
    Run-Step "Aggiornamento pacchetti" "flutter pub get" 25
    Run-Step "Generazione icone" "flutter pub run flutter_launcher_icons:main" 40
    Run-Step "Build APK Debug" "flutter build apk --debug" 60
    Run-Step "Build APK Release" "flutter build apk --release" 80
    Run-Step "Build iOS Release" "flutter build ios --release" 95
    Show-Progress -Percent 100 -Message "Build completata!"
    Write-Host "n🎉 Tutto completato con successo!"
}

# Modalità QUICK (senza build)
function Quick-Build {
    Write-Host "⚡ Modalità QUICK attivata: verranno eseguiti solo clean, pub get e generazione icone!"
    Run-Step "Pulizia progetto" "flutter clean" 10
    Run-Step "Aggiornamento pacchetti" "flutter pub get" 30
    Run-Step "Generazione icone" "flutter pub run flutter_launcher_icons:main" 50
    Show-Progress -Percent 100 -Message "Operazione completata (Quick Mode)"
    Write-Host "`n✅ Quick mode completato! Nessuna build eseguita."
}

# === LOG SETUP ===
if (Test-Path $logFile) { Remove-Item $logFile }
Write-Host "🚀 Avvio script build - $(Get-Date)"
Ensure-Keystore
Set-Location $projectPath

# === QUICK MODE da parametro ===
if ($Quick) {
    Quick-Build
    exit
}

# === MENÙ INTERATTIVO ===
function Show-Menu {
    Write-Host ""
    Write-Host "==============================="
    Write-Host "     COLORSLASH BUILD TOOL     "
    Write-Host "==============================="
    Write-Host "1️⃣  Build completa (Android + iOS)"
    Write-Host "2️⃣  Solo build Android Release"
    Write-Host "3️⃣  Solo build iOS Release"
    Write-Host "4️⃣  Modalità Quick (senza build)"
    Write-Host "5️⃣  Esci"
    Write-Host "==============================="
    $choice = Read-Host "Seleziona un'opzione (1-5)"
    return $choice
}

# === LOOP MENU ===
do {
    $selection = Show-Menu
    switch ($selection) {
        "1" {
            Full-Build
        }
        "2" {
            Run-Step "Pulizia progetto" "flutter clean" 10
            Run-Step "Aggiornamento pacchetti" "flutter pub get" 25
Run-Step "Generazione icone" "flutter pub run flutter_launcher_icons:main" 40
            Run-Step "Build APK Release" "flutter build apk --release" 100
            Write-Host "n✅ Build Android Release completata!"
        }
        "3" {
            Run-Step "Pulizia progetto" "flutter clean" 10
            Run-Step "Aggiornamento pacchetti" "flutter pub get" 25
            Run-Step "Generazione icone" "flutter pub run flutter_launcher_icons:main" 40
            Run-Step "Build iOS Release" "flutter build ios --release" 100
            Write-Host "n✅ Build iOS Release completata!"
        }
        "4" {
            Quick-Build
        }
        "5" {
            Write-Host "👋 Uscita dallo script..."
            exit
        }
        Default {
            Write-Host "❗ Scelta non valida. Riprova."
        }
    }
} while ($selection -ne "5")