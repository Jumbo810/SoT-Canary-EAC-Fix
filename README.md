# Sea of Thieves - Windows 11 Insider EAC Bypass

A PowerShell automation script to fix the Easy Anti-Cheat (EAC) kernel crash for *Sea of Thieves* on Windows 11 Insider Canary builds. This script utilizes a temporary, automated firewall block to achieve a "fail-open" initialization, allowing the game to launch safely without dropping remote desktop connections.

## 🐛 The Issue: The Canary Kernel Mismatch

If you are running an experimental Windows 11 Insider build (specifically Canary Build 26200 or higher), *Sea of Thieves* will immediately hard crash upon launch with the following message:
> **"Game client encountered an application error."**

**The Technical Root Cause:**
Easy Anti-Cheat (EAC) operates as a Ring-0 kernel-mode driver (`EasyAntiCheat_EOS.sys`). Microsoft frequently alters the Windows kernel signature in Canary builds. Because these experimental signatures are not on Epic Games' cryptographic whitelist, EAC assumes the kernel is compromised. 

Instead of triggering a Blue Screen of Death (BSOD), EAC intentionally and safely unloads itself from the Filter Manager during the game's network initialization handshake. *Sea of Thieves* detects that the anti-cheat driver is missing and instantly terminates the process.

## 🛠️ The Fix: "Fail-Open" Network Isolation

We cannot modify the Windows kernel or the EAC driver. However, we can manipulate the initialization sequence. 

If EAC cannot reach the Epic Online Services backend to verify the kernel signature, it "fails open" and allows the game engine to reach the main menu. 

**How the script works:**
1. Wraps a strict inbound/outbound Windows Defender Firewall block specifically around `SeaOfThieves.exe`.
2. Launches the game.
3. Waits exactly 30 seconds for the game engine to initialize and bypass the kernel signature check.
4. Removes the firewall rules, restoring internet access to the game just in time for Xbox Live authentication and multiplayer matchmaking.

*Note: Because this targets the specific executable rather than the physical network adapter, this script is **100% safe to use over remote desktop connections** (Moonlight, RustDesk, RDP).*

## 🚀 Installation & Usage

### Step 1: Save the Script
1. Create a new file on your Desktop named `SoT-EAC-Bypass.ps1`.
2. Open the file in Notepad or your preferred IDE and paste the code below.
3. **Important:** Update the `$exePath` variable at the top of the script to match the exact location of your `SeaOfThieves.exe` file.

```powershell
# --- CONFIGURATION ---
# Change this path if your game is installed on a different drive
$exePath = "C:\XboxGames\Sea of Thieves\Content\SeaOfThieves.exe"
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
```

### Step 2: Create a 1-Click Launch Shortcut
Because this script modifies the Windows Firewall, it requires Administrator privileges to run. To avoid opening an Admin terminal every time you want to play, create a desktop shortcut.

1. Right-click your Desktop > **New** > **Shortcut**.
2. In the location box, paste the following command (Ensure you change `YOUR_USERNAME` to your actual Windows user folder name):
   ```cmd
   powershell.exe -ExecutionPolicy Bypass -WindowStyle Normal -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File C:\Users\YOUR_USERNAME\Desktop\SoT-EAC-Bypass.ps1' -Verb RunAs"
   ```
3. Click **Next**, name the shortcut `Launch Sea of Thieves`, and click **Finish**.

### Step 3: Play
Double-click your new shortcut. Click "Yes" on the Admin prompt. A terminal will appear, block the connection, launch the game, and automatically reconnect you to the servers 30 seconds later.

## ⚠️ Disclaimer
This script does not disable or modify Easy Anti-Cheat; it only delays its network handshake. However, use this at your own risk. Playing online multiplayer games on unsupported, experimental Windows Insider kernels may result in unexpected disconnects or account flags by automated anti-cheat systems. 
```