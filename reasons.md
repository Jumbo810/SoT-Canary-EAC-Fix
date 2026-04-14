# Sea of Thieves - Windows 11 Insider Canary EAC Crash & Fix

A comprehensive technical breakdown and PowerShell automation script to bypass the Easy Anti-Cheat (EAC) kernel crash for *Sea of Thieves* on Windows 11 Insider Canary builds. This solution utilizes a temporary, automated firewall block to achieve a "fail-open" initialization, allowing the game to launch safely without dropping remote desktop connections.

## 🐛 The Issue: The Canary Kernel Mismatch
If you are running an experimental Windows 11 Insider build (specifically Canary Build 26200 or higher), *Sea of Thieves* will immediately hard crash upon launch with the following message:
> **"Game client encountered an application error."**

**The Technical Root Cause:**
Easy Anti-Cheat (EAC) operates as a Ring-0 kernel-mode driver (`EasyAntiCheat_EOS.sys`). Microsoft frequently alters the Windows kernel signature in Canary builds. Because these experimental signatures are not on Epic Games' cryptographic whitelist, EAC assumes the kernel is compromised. 

Instead of triggering a Blue Screen of Death (BSOD), EAC intentionally and safely unloads itself from the Filter Manager during the game's network initialization handshake. *Sea of Thieves* detects that the anti-cheat driver is missing and instantly terminates the process.

## 🔬 The Diagnostic Journey
To isolate this issue and prove it was a kernel mismatch rather than corrupted files, two critical diagnostic steps were taken:

1. **The Event Viewer Proof:** By checking `eventvwr.msc` immediately after a crash, the System logs showed Event ID 6 and Event ID 7045. These logs confirmed that the `EasyAntiCheat_EOSSys` driver was successfully injecting but then actively unloading itself right before the `.exe` crash.
2. **The Stable OS Control Test:** To rule out corrupted game files, a Native VHDX (Virtual Hard Disk) partition was built on the drive. A clean, stable, non-Insider release of Windows 11 was installed inside it. Booting into that stable OS and launching the same 128GB game files worked flawlessly. This definitively isolated the Canary kernel as the sole point of failure.

## 🚧 The Engineering Roadblocks
Creating an automated bypass required navigating several technical constraints:

* **The Remote Access Disconnect:** The initial workaround involved disabling the physical network adapter to force an offline launch. However, this instantly severed active remote streams (Moonlight, RustDesk, Tailscale). The solution was pivoting to a precise Windows Defender Firewall block.
* **The UWP Shell Routing Failure:** Attempting to launch the Microsoft Store (UWP) app programmatically via its Package Family Name (`shell:AppsFolder\...`) caused Windows to unpredictably open File Explorer instead. The solution was targeting the direct executable path (`SeaOfThieves.exe`) to bypass the restrictive Explorer shell.
* **The "Fail-Close" Anti-Cheat Trap:** Modern anti-cheats use a "fail-close" architecture. If EAC is permanently blocked from the Epic Online Services backend, it cannot generate a secure trust token, and Xbox Live matchmaking servers will instantly reject the connection. The solution required precision timing: allowing a temporary offline state to bypass the kernel check, then instantly restoring the connection for the server handshake.

## 🛠️ The Fix: "Fail-Open" Network Isolation
We cannot modify the Windows kernel or the EAC driver, but we can manipulate the initialization sequence. If EAC cannot reach the backend to verify the kernel signature, it "fails open" and allows the game engine to reach the main menu. 

**How the script works:**
1. Wraps a strict inbound/outbound Windows Defender Firewall block specifically around `SeaOfThieves.exe`.
2. Launches the game directly via the `.exe`.
3. Waits exactly 30 seconds for the game engine to initialize and bypass the local kernel signature check.
4. Removes the firewall rules, restoring internet access to the game just in time for Xbox Live authentication and multiplayer matchmaking.

## 🚀 Installation & Usage

### Step 1: Save the Script
1. Create a new file named `SoT-EAC-Bypass.ps1`.
2. Open the file in your preferred editor and paste the code below.
3. **Important:** Update the `$exePath` variable at the top of the script to match the exact location of your `SeaOfThieves.exe` file.

```powershell
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
```

### Step 2: Create a 1-Click Launch Shortcut
Because this script modifies the Windows Firewall, it requires Administrator privileges. 

1. Right-click your Desktop > **New** > **Shortcut**.
2. In the location box, paste the following command (Ensure you change `C:\Path\To\Script` to your actual file path):
   ```cmd
   powershell.exe -ExecutionPolicy Bypass -WindowStyle Normal -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File C:\Path\To\Script\SoT-EAC-Bypass.ps1' -Verb RunAs"
   ```
3. Click **Next**, name the shortcut `Launch Sea of Thieves`, and click **Finish**.

### Step 3: Play
Double-click your new shortcut. Click "Yes" on the Admin prompt. The script will block the connection, launch the game, and automatically reconnect you to the servers 30 seconds later without dropping any remote desktop streams.

## ⚠️ Disclaimer
This script does not disable or modify Easy Anti-Cheat; it only delays its network handshake. Use this at your own risk. Playing online multiplayer games on unsupported, experimental Windows Insider kernels may result in unexpected disconnects or account flags by automated anti-cheat systems.