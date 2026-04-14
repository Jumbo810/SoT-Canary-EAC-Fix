### **1. The Diagnostic Proof (Event Viewer)**
Before writing any scripts, we had to stop guessing and find the exact faulting module.
* **The Roadblock:** The game only provided a generic "Game client encountered an application error" message, which could have meant corrupted game files, bad graphics drivers, or network failure.
* **The Solution:** We utilized the Windows Event Viewer (`eventvwr.msc`). By cross-referencing the exact timestamp of the game crash in the System logs, we found the smoking gun: Event ID 6 and Event ID 7045. These logs proved that the `EasyAntiCheat_EOSSys` kernel driver was successfully injecting, but immediately unloading itself right before the crash.

### **2. The Stable OS Control Test**
We had to prove whether the 128GB game files were corrupted or if the operating system itself was the problem.
* **The Roadblock:** Downloading a 128GB game takes hours, and deleting it to reinstall would wipe out your custom config files. We needed to test the core game files in a clean environment without destroying your existing setup.
* **The Solution:** We built a Native VHDX (Virtual Hard Disk) partition on your drive and installed a clean, stable, non-Insider release of Windows 11. By booting into that stable OS and pointing it at your existing game files, the game launched flawlessly. This definitively proved the 128GB installation was perfect, and the Canary kernel was the sole cause of the crash.

### **3. The Canary Kernel Mismatch (The Root Cause)**
The foundational issue was the operating system itself. Windows 11 Build 26200 is an experimental Insider Canary build. 
* **The Roadblock:** Easy Anti-Cheat (EAC) operates as a Ring-0 kernel driver. Because the Canary kernel is experimental, Epic Games has not whitelisted its cryptographic signature. 
* **The Result:** Instead of triggering a Blue Screen of Death, EAC safely unloaded itself to avoid a critical system failure. *Sea of Thieves* instantly detected the missing driver and threw the hard crash.

### **4. The Remote Access Disconnect**
Once you discovered that launching the game offline bypassed the kernel check, the first script disabled the physical network adapter to automate that process.
* **The Roadblock:** Killing the physical Wi-Fi or Ethernet adapter worked perfectly for a local user, but it instantly severed the active Tailscale, RustDesk, and Moonlight streams. It locked out all remote control capabilities.
* **The Solution:** We had to pivot from a hardware-level network kill switch to a software-level Windows Defender Firewall block.

### **5. The UWP Shell Routing Failure**
To automate the firewall block, the script needed to launch the game programmatically while the network was down. 
* **The Roadblock:** Microsoft Store (UWP) apps are heavily encrypted and sandboxed. Attempting to launch the game using its standard Package Family Name and App ID (`shell:AppsFolder\...`) caused Windows to unpredictably open File Explorer instead of the game engine. 
* **The Solution:** You utilized the direct executable path (`F:\XboxGames\Sea of Thieves\Content\SeaOfThieves.exe`). This allowed us to bypass the restrictive Windows Explorer shell entirely and execute the binary directly.

### **6. The "Fail-Close" Anti-Cheat Trap**
We considered simply blocking EAC's internet access permanently so it could never verify the kernel.
* **The Roadblock:** Modern anti-cheat systems use a "fail-close" architecture. If EAC is permanently blocked from reaching the Epic Online Services backend, it cannot generate a secure trust token. Without that token, the Xbox Live matchmaking servers will instantly reject the multiplayer connection. 
* **The Solution:** The final architecture relied on precision timing. By wrapping a temporary, 30-second firewall block exclusively around `SeaOfThieves.exe`, we allowed the game to "fail open" past the initial local kernel scan. Removing the block exactly 30 seconds later restored the connection just in time for the game to successfully ping the matchmaking servers, all without dropping a single frame of the remote desktop stream.