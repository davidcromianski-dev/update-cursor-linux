#!/usr/bin/env bash
set -euo pipefail

# Atualiza o Cursor AppImage em /opt/cursor/cursor.AppImage
# Cria backup, garante permissões, e adiciona atalho com fallback caso FUSE esteja ausente.

CURSOR_DIR="/opt/cursor"
APPIMAGE_PATH="${CURSOR_DIR}/cursor.AppImage"
DOWNLOAD_DIR="/tmp"
DESKTOP_GLOBAL="/usr/share/applications/cursor.desktop"
DESKTOP_LOCAL="${HOME}/.local/share/applications/cursor.desktop"

# Verifica se sudo está disponível quando não root
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Este script precisa escrever em ${CURSOR_DIR}. Instale 'sudo' ou execute como root." >&2
    exit 1
  fi
fi

read -rp "Informe a versão do Cursor desejada (ex: 1.4.5): " VERSION
if [[ -z "${VERSION}" ]]; then
  echo "Versão não informada. Abortando." >&2
  exit 1
fi

URL="https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/${VERSION}"
TMP_FILE="${DOWNLOAD_DIR}/cursor-${VERSION}.AppImage"

# Garante diretório de instalação
if [[ ! -d "${CURSOR_DIR}" ]]; then
  echo "Diretório ${CURSOR_DIR} não encontrado. Deseja criar? (s/N)"
  read -r ans
  if [[ "${ans:-N}" =~ ^[sS]$ ]]; then
    sudo mkdir -p "${CURSOR_DIR}"
  else
    echo "Abortado."
    exit 1
  fi
fi

# Solicita fechamento do Cursor se estiver em execução
if pgrep -a -f "cursor.AppImage" >/dev/null 2>&1 || pgrep -a -f "/tmp/.mount_cursor" >/dev/null 2>&1; then
  echo "Detectado Cursor em execução. Por favor, feche o Cursor antes de continuar e pressione Enter."
  read -r _
fi

# Baixa AppImage
echo "Baixando ${URL} ..."
if command -v curl >/dev/null 2>&1; then
  curl -fL "${URL}" -o "${TMP_FILE}"
elif command -v wget >/dev/null 2>&1; then
  wget -O "${TMP_FILE}" "${URL}"
else
  echo "Nem curl nem wget encontrados. Instale um deles para prosseguir." >&2
  exit 1
fi

# Valida download
if [[ ! -s "${TMP_FILE}" ]]; then
  echo "Falha no download ou arquivo vazio: ${TMP_FILE}" >&2
  exit 1
fi
chmod +x "${TMP_FILE}"

# Backup do atual, se existir
if [[ -f "${APPIMAGE_PATH}" ]]; then
  TS="$(date +%Y%m%d-%H%M%S)"
  BKP="${APPIMAGE_PATH}.${TS}.bak"
  echo "Criando backup: ${BKP}"
  sudo cp -f "${APPIMAGE_PATH}" "${BKP}"
fi

# Substitui o AppImage atual
echo "Atualizando ${APPIMAGE_PATH} ..."
sudo cp -f "${TMP_FILE}" "${APPIMAGE_PATH}"
sudo chmod +x "${APPIMAGE_PATH}"
sudo chmod 755 "${APPIMAGE_PATH}"

# Detecta se libfuse.so.2 está disponível
FUSE_OK=true
if ! ldconfig -p 2>/dev/null | grep -q "libfuse.so.2"; then
  if [[ ! -f /usr/lib/libfuse.so.2 && ! -f /lib/libfuse.so.2 && ! -f /usr/lib64/libfuse.so.2 ]]; then
    FUSE_OK=false
  fi
fi

# Determina Exec correto
if [[ "${FUSE_OK}" == true ]]; then
  EXEC_CMD="${APPIMAGE_PATH} --no-sandbox %U"
  echo "✔ libfuse2 detectado — AppImage rodará normalmente."
else
  echo "⚠ libfuse2 NÃO encontrado. O Cursor AppImage usará fallback:"
  echo "   --appimage-extract-and-run"
  EXEC_CMD="${APPIMAGE_PATH} --appimage-extract-and-run --no-sandbox %U"
fi

# Define caminho de ícone se existir
ICON_PATH=""
if [[ -f "${CURSOR_DIR}/cursor.png" ]]; then
  ICON_PATH="${CURSOR_DIR}/cursor.png"
fi

# Caminho de destino do atalho
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  DESKTOP_PATH="${DESKTOP_GLOBAL}"
else
  mkdir -p "$(dirname "${DESKTOP_LOCAL}")"
  DESKTOP_PATH="${DESKTOP_LOCAL}"
fi

# Cria/atualiza .desktop com Exec dinâmico
if [[ ! -f "${DESKTOP_PATH}" ]]; then
  echo "Criando atalho do Cursor em ${DESKTOP_PATH} ..."
  cat <<EOF | sudo tee "${DESKTOP_PATH}" >/dev/null
[Desktop Entry]
Name=Cursor
Comment=AI-powered code editor
Exec=${EXEC_CMD}
Icon=${ICON_PATH:-cursor}
Terminal=false
Type=Application
Categories=Development;IDE;Programming;
StartupNotify=true
EOF
else
  echo "Atualizando atalho existente (${DESKTOP_PATH}) ..."
  sudo sed -i "s|^Exec=.*|Exec=${EXEC_CMD}|" "${DESKTOP_PATH}"
  if [[ -n "${ICON_PATH}" ]]; then
    sudo sed -i "s|^Icon=.*|Icon=${ICON_PATH}|" "${DESKTOP_PATH}"
  fi
fi

# Atualiza banco de atalhos
if command -v update-desktop-database >/dev/null 2>&1; then
  echo "Atualizando banco de atalhos..."
  sudo update-desktop-database "$(dirname "${DESKTOP_PATH}")" || true
fi

# Limpa download temporário
rm -f "${TMP_FILE}"

echo
echo "✅ Concluído. Cursor atualizado para a versão ${VERSION}."
echo "🔗 Atalho criado/atualizado em: ${DESKTOP_PATH}"
echo "🚀 Execução configurada como:"
echo "   ${EXEC_CMD}"
echo
if [[ "${FUSE_OK}" == false ]]; then
  echo "⚠ Para executar sem fallback, instale libfuse2:"
  echo "   Debian/Ubuntu/Mint → sudo apt install libfuse2"
  echo "   Arch/Manjaro → sudo pacman -S fuse2"
  echo "   Fedora → sudo dnf install fuse"
fi
