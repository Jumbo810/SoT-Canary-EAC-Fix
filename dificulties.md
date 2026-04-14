### **1. The Canary Kernel Mismatch (The Root Cause)**
The foundational issue was the operating system itself. Windows 11 Build 26200 is an experimental Insider Canary build. 
* **The Roadblock:** Easy Anti-Cheat (EAC) operates as a Ring-0 kernel driver (`EasyAntiCheat_EOS.sys`). It scans the Windows kernel signature upon boot. Because the Canary kernel is experimental, Epic Games has not whitelisted its cryptographic signature. 
* **The Result:** Instead of triggering a Blue Screen of Death, EAC safely unloaded itself to avoid a critical system failure. *Sea of Thieves* instantly detected the missing driver and threw a hard crash.

### **2. The Remote Access Disconnect**
Once you discovered that launching the game offline bypassed the kernel check, the first script disabled the physical network adapter to automate that process.
* **The Roadblock:** Killing the physical Wi-Fi or Ethernet adapter worked perfectly for a local user, but it instantly severed the active Tailscale, RustDesk, and Moonlight streams. It locked out all remote control capabilities.
* **The Solution:** We had to pivot from a hardware-level network kill switch to a software-level Windows Defender Firewall block.

### **3. The UWP Shell Routing Failure**
To automate the firewall block, the script needed to launch the game programmatically while the network was down. 
* **The Roadblock:** Microsoft Store (UWP) apps are heavily encrypted and sandboxed. Attempting to launch the game using its standard Package Family Name and App ID (`shell:AppsFolder\...`) caused Windows to unpredictably open File Explorer instead of the game engine. 
* **The Solution:** You provided the direct executable path (`F:\XboxGames\Sea of Thieves\Content\SeaOfThieves.exe`). This allowed us to bypass the restrictive Windows Explorer shell entirely and execute the binary directly.

### **4. The "Fail-Close" Anti-Cheat Trap**
We considered simply blocking EAC's internet access permanently so it could never verify the kernel.
* **The Roadblock:** Modern anti-cheat systems use a "fail-close" architecture. If EAC is permanently blocked from reaching the Epic Online Services backend, it cannot generate a secure trust token. Without that token, the Xbox Live matchmaking servers will instantly reject the multiplayer connection. 
* **The Solution:** The final architecture relied on precision timing. By wrapping a temporary, 30-second firewall block exclusively around `SeaOfThieves.exe`, we allowed the game to "fail open" past the initial local kernel scan. Removing the block exactly 30 seconds later restored the connection just in time for the game to successfully ping the matchmaking servers, all without dropping a single frame of the remote desktop stream.