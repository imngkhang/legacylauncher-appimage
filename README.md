# Legacy Launcher unofficial AppImage

## 📄 License

This project is for demonstration and testing purposes ONLY, to promote this packaging format to [turikhay](https://github.com/turikhay). Consider this package as "experimental" or "testing". I also invite you to request him to release an official AppImage, and if he agrees, you can show this repository as a proof of concept.

This project is licensed under the GPL-3.0-only license.

Legacy Launcher is created by turikhay, and is in no way affiliated with Mojang Studios, nor should it be considered a project endorsed by Mojang Studios. This project is community-maintained and is not affiliated with, supported, or endorsed by turikhay or Mojang Studios. 

## Description

This is an unofficial AppImage wrapper for Legacy Launcher (previously known as TL), that is built on top of [RunImage](https://github.com/VHSgunzo/runimage), the portable single-file Linux container in unprivileged user namespaces

Legacy Launcher is a Minecraft launcher that is stable, fast and simple. This includes the launcher's .jar file, and also, OpenJDK to run the launcher as well, **and it will also use the proprietary nvidia driver from the host**.

### So why did I build this f**king big sh\*t clanker, instead of just using the "Install Java manually" option on LL's site?

Because I want a fully portable AppImage that doesn't depend on your distro's Java (some distros don't have it pre-installed), unlike that option, which depends heavily on Java. So I built this on top of RunImage to get rid of the Java dependency problem on these distros.


## 📷 Screenshots:

Here is the screenshots of the launcher (it's comes from turikhay's official screenshot):

![screenshot1.png](https://raw.githubusercontent.com/imngkhang/legacylauncher-appimage/master/screenshots/1.png)
![screenshot2.png](https://raw.githubusercontent.com/imngkhang/legacylauncher-appimage/master/screenshots/2.png)
![screenshot3.png](https://raw.githubusercontent.com/imngkhang/legacylauncher-appimage/master/screenshots/3.png)

## 🚀 Quick Start

### Requirements

Before installing or building this package, ensure your system meets the following requirements:

- **Linux**: 2.6.14 or later
- **glibc**: ANY versions, because this is an Anylinux AppImage
- **Architecture**: `x86_64` **ONLY**
- **Tools**: `jq`, `sha256sum`, `stat`, `wget`, `grep`, `make`, `zsyncmake`, from your distro
- **Gear Lever** (*optional*): Lastest version from [Flathub](https://flathub.org/en/apps/it.mijorus.gearlever)
- **AM/AppMan** (*optional*): Lastest version from [iVAN's repo](https://github.com/ivan-hc/AM)

### Install the AppImage:
I recommend using [Gear Lever](https://github.com/mijorus/gearlever) or [AM](https://github.com/ivan-hc/AM) to integrate the AppImage into your system menu.

1.  Download the latest `.AppImage` file from the [**Releases**](https://github.com/imngkhang/legacylauncher-appimage/releases) page.
2.  Running the launcher by going to the [Running the launcher](#running-the-launcher) section.

If you are using [AM or AppMan](https://github.com/ivan-hc/AM), you can install using this command:
- For AM:
  ```bash
  # I will add to AM soon
  ```
- For AppMan:
  ```bash
  # I will add to AM soon
  ```

### Build from source

- **Debian / Ubuntu:**
  ```bash
  sudo apt update && sudo apt install build-essential jq wget coreutils zsync
  ```

- **Fedora / Red Hat:**
  ```bash
  sudo dnf groupinstall "Development Tools" && sudo dnf install jq wget coreutils zsync
  ```

- **Arch Linux / Manjaro:**
  ```bash
  sudo pacman -Syu --needed base-devel jq wget coreutils zsync
  ```

- **openSUSE (Leap / Tumbleweed):**
  ```bash
  sudo zypper in -t pattern devel_basis && sudo zypper in jq wget coreutils zsync
  ```

- **Gentoo:**
  ```bash
  sudo emerge --ask sys-devel/make sys-devel/binutils app-misc/jq net-misc/wget sys-apps/coreutils net-misc/zsync
  ```

- **Locally build an AppImage:**
  ```bash  
  make
  ```

Type `make help` for more info. Final AppImage will be in `dist/` directory.

*Note: You can remove the development tools if you don't need, but DO NOT REMOVE other packages that installed.*

### Running the launcher
Using [AM](https://github.com/ivan-hc/AM), recommended together with Gear Lever (it auto adds to your path):
```bash
legacylauncher
```

Using [Gear Lever](https://github.com/mijorus/gearlever), recommended together with AM/AppMan:
- Using GUI:
  1. Double-click to the AppImage, a window will appear
  2. Click "Move to the app menu"
  3. Than click "Launch", you are ready to go!
- Using CLI:
  ```bash
  flatpak run it.mijorus.gearlever --integrate LegacyLauncher-Bootstrap-*.AppImage
  ```

Or run it manually:
```bash
chmod a+x LegacyLauncher-Bootstrap-*.AppImage
./LegacyLauncher-Bootstrap-*.AppImage
```

This AppImage does NOT require libfuse2, being it a new generation one.

## 🤝 Contributing

Contributions are always welcome! You can help by:
- Reporting issues (crashes, problems, missing fonts/libs).
- Submitting PRs to update the project.
- Improving the autobuild (CI) code and other parts.

Want to become a **co-maintainer**? If you use this launcher regularly, or **you are turikhay**, you can join in and help maintain this package by opening an issue for me.

Feel free to open an issue or submit a PR anytime!

