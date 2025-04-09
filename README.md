
```markdown
# Java and Maven, Node.js, Appium, Appium Inspector (Run as Admin)

## Script

```powershell
# run-java-setup.ps1
Set-ExecutionPolicy RemoteSigned -Scope Process -Force
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/testervippro/java-mvn/main/java-base-setup.ps1" -UseBasicParsing).Content
```

# Install Command Line Tools Only (Without Android Studio) (Run as Admin)

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/testervippro/java-mvn/main/android-cmd-tools.ps1" -UseBasicParsing).Content
```

---

# ADB (Android Debug Bridge)
| Command | Description |
|--------|-------------|
| `adb devices` | List connected Android devices or emulators |
| `adb install app.apk` | Install APK to device |
| `adb uninstall <package>` | Uninstall an app |
| `adb shell` | Start remote shell on device |
| `adb logcat` | View device log output |
| `adb push <local> <remote>` | Push file to device |
| `adb pull <remote> <local>` | Pull file from device |
| `adb reboot` | Reboot the device |
| `adb root` | Restart adb daemon with root permissions (if allowed) |
| `adb tcpip 5555` | Enable ADB over Wi-Fi |
| `adb connect <ip>:5555` | Connect to device over Wi-Fi |

---

# Emulator
| Command | Description |
|--------|-------------|
| `emulator -list-avds` | List all available AVDs |
| `emulator -avd <name>` | Start emulator with AVD |
| `emulator -avd <name> -no-audio -no-boot-anim` | Start emulator faster without audio/boot animation |
| `emulator -avd <name> -wipe-data` | Reset emulator to factory state |
| `emulator -avd <name> -gpu off` | Disable GPU emulation |
| `emulator -help` | Show emulator help |

---

# AVD Manager (`avdmanager`)
| Command | Description |
|--------|-------------|
| `avdmanager list avd` | List all AVDs |
| `avdmanager list device` | List available device definitions |
| `avdmanager list target` | List available Android targets (API levels) |
| `avdmanager create avd -n <name> -k <system-image> --device <device-name>` | Create new AVD |
| `avdmanager delete avd -n <name>` | Delete an AVD |

**Example:**
```bash
avdmanager create avd -n pixel6a -k "system-images;android-30;google_apis;x86_64" --device "pixel_6a"
```

---

# AAPT2 (Android Asset Packaging Tool v2)
| Command | Description |
|--------|-------------|
| `aapt2 compile file.xml -o output/` | Compile a resource file |
| `aapt2 link -o output.apk -I android.jar -R compiled/*.flat` | Link compiled resources and generate APK |
| `aapt2 dump badging app.apk` | Show APK manifest & metadata |
| `aapt2 dump xmltree app.apk AndroidManifest.xml` | Show structure of the manifest |
| `aapt2 version` | Show the AAPT2 version |

---

# Notes
- Use `sdkmanager --list` to view available packages.
- Make sure environment variables like `ANDROID_HOME` and `PATH` are properly set.
```

Let me know if you'd like me to save this into a `.md` file for upload to GitHub.
