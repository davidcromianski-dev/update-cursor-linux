# Cursor Updater Script

Bash script to update the Cursor AppImage on Linux, with automatic backup, FUSE detection, and desktop shortcut creation.

## 📋 Description

This script automates the process of updating Cursor (AI-powered code editor) on Linux systems. It downloads a specific version of the AppImage, creates backups of the previous installation, manages permissions, and configures desktop shortcuts with automatic fallback for systems without libfuse2.

## ✨ Features

- ✅ Download specific versions of Cursor
- ✅ Automatic backup of previous installation
- ✅ Automatic libfuse2 detection
- ✅ Fallback to `--appimage-extract-and-run` when FUSE is not available
- ✅ Create/update desktop shortcuts (.desktop)
- ✅ Check for running instances
- ✅ Support for execution as root or with sudo
- ✅ Download validation and permission management

## 🔧 Prerequisites

- **Operating System**: Linux
- **Permissions**: Write access to `/opt/cursor` (requires sudo or execution as root)
- **Tools**:
  - `curl` or `wget` (for downloading)
  - `sudo` (if not running as root)
  - `update-desktop-database` (optional, for updating shortcut database)

### Optional Dependencies

- **libfuse2**: For native AppImage execution (recommended)
  - Debian/Ubuntu/Mint: `sudo apt install libfuse2`
  - Arch/Manjaro: `sudo pacman -S fuse2`
  - Fedora: `sudo dnf install fuse`

## 📖 Usage

### Basic Execution

```bash
./atualizar-cursor.sh
```

The script will prompt for:
1. The desired Cursor version (e.g., `1.4.5`)
2. Confirmation to create `/opt/cursor` if it doesn't exist
3. Closing Cursor if it's currently running

### Execution Example

```bash
$ ./atualizar-cursor.sh
Informe a versão do Cursor desejada (ex: 1.4.5): 1.4.5
Baixando https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/1.4.5 ...
Criando backup: /opt/cursor/cursor.AppImage.20241201-143022.bak
Atualizando /opt/cursor/cursor.AppImage ...
✔ libfuse2 detectado — AppImage rodará normalmente.
Atualizando atalho existente (/home/user/.local/share/applications/cursor.desktop) ...

✅ Concluído. Cursor atualizado para a versão 1.4.5.
```

## 📁 File Structure

### Directories and Files

- **Installation**: `/opt/cursor/cursor.AppImage`
- **Backups**: `/opt/cursor/cursor.AppImage.YYYYMMDD-HHMMSS.bak`
- **Temporary downloads**: `/tmp/cursor-VERSION.AppImage`
- **Desktop shortcuts**:
  - Global: `/usr/share/applications/cursor.desktop` (when executed as root)
  - Local: `~/.local/share/applications/cursor.desktop` (when executed as user)

### Permissions

The script configures:
- Executable: `chmod +x` on the AppImage
- Permissions: `chmod 755` on the AppImage

## 🔍 FUSE Detection

The script automatically detects if `libfuse.so.2` is available:

- **With FUSE**: Executes normally: `cursor.AppImage --no-sandbox %U`
- **Without FUSE**: Uses fallback: `cursor.AppImage --appimage-extract-and-run --no-sandbox %U`

## 🛡️ Security

- Uses `set -euo pipefail` for strict error handling
- Validates downloads (checks if file is not empty)
- Creates backups before replacing existing installation
- Requests confirmation before creating directories

## ⚠️ Troubleshooting

### Error: "Este script precisa escrever em /opt/cursor"

**Solution**: Execute with `sudo` or as root:
```bash
sudo ./atualizar-cursor.sh
```

### Error: "Nem curl nem wget encontrados"

**Solution**: Install one of the tools:
```bash
# Debian/Ubuntu
sudo apt install curl

# or
sudo apt install wget
```

### Cursor won't start after update

1. Check if the AppImage has execution permission:
   ```bash
   ls -l /opt/cursor/cursor.AppImage
   ```

2. Try running manually:
   ```bash
   /opt/cursor/cursor.AppImage --appimage-extract-and-run
   ```

3. Check error logs in the terminal

### Restore previous version

Backups are saved in `/opt/cursor/` with `.bak` extension:
```bash
# List backups
ls -lh /opt/cursor/*.bak

# Restore specific backup
sudo cp /opt/cursor/cursor.AppImage.20241201-143022.bak /opt/cursor/cursor.AppImage
sudo chmod +x /opt/cursor/cursor.AppImage
```

## 📝 Notes

- The script detects if Cursor is running and requests closure before continuing
- Backups are created with timestamps to avoid overwriting
- The desktop shortcut is automatically updated with the correct execution command
- Custom icons in `/opt/cursor/cursor.png` are automatically detected

## 🔗 URLs and Resources

- **Download API**: `https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/{VERSION}`
- **Format**: AppImage for Linux x64

## 📄 License

This script is provided as-is, without warranties. Use at your own risk.

## 🤝 Contributions

Improvements and suggestions are welcome!
