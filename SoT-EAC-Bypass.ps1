# --- CONFIGURATION ---
# Change this path if your game is installed on a different drive
$exePath = "F:\XboxGames\Sea of Thieves\Content\SeaOfThieves.exe"
# ---------------------

$ruleName = "SoT_Executable_Bypass"

# Clean up any stuck rules from previous runs
Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

Write-Host "Isolating Sea of Thieves executable from the network..." -ForegroundColor Red

# Create strict outbound and inbound blocks specifically for the game .exe
New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -Program $exePath -Action Block | Out-Null
New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Program $exePath -Action Block | Out-Null

Write-Host "`nGAME IS BLOCKED. Main internet is still ACTIVE." -ForegroundColor White -BackgroundColor Blue
Write-Host "Launching Sea of Thieves..." -ForegroundColor Yellow

# Launch the game directly using the provided executable path
Start-Process -FilePath $exePath

# Wait 30 seconds while the game boots and bypasses the EAC kernel check
for ($i = 30; $i -gt 0; $i--) {
    Write-Progress -Activity "Waiting for game to reach main menu..." -Status "$i seconds remaining" -PercentComplete (($i / 30) * 100)
    Start-Sleep -Seconds 1
}

Write-Host "`nRestoring game connection..." -ForegroundColor Cyan

# Delete the rules to allow the game back online
Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

Write-Host "INTERNET RESTORED TO GAME! You can now play online." -ForegroundColor Green
Start-Sleep -Seconds 3
