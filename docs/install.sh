#!/bin/sh
set -e

# Theia Client Installer
# Usage: curl -fsSL https://data-tamer.github.io/theia-client-releases/install.sh | sh

REPO="data-tamer/theia-client-releases"
BINARY="theia"

echo "=== Theia Client Installer ==="
echo ""

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  linux)  OS_NAME="linux" ;;
  darwin) OS_NAME="macos" ;;
  *)      echo "Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64|amd64)    ARCH_NAME="amd64" ;;
  aarch64|arm64)   ARCH_NAME="arm64" ;;
  armv7l|armhf)    ARCH_NAME="arm64" ;;
  *)               echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

ASSET="theia-client-${OS_NAME}-${ARCH_NAME}"
URL="https://github.com/${REPO}/releases/latest/download/${ASSET}"

echo "Platform: ${OS_NAME}/${ARCH_NAME}"
echo "Downloading: ${ASSET}"
echo ""

# Download binary
TMP=$(mktemp)
if command -v curl >/dev/null 2>&1; then
  curl -fsSL -o "$TMP" "$URL"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$TMP" "$URL"
else
  echo "Error: curl or wget required"
  exit 1
fi

chmod +x "$TMP"

# Verify it runs
if "$TMP" version >/dev/null 2>&1; then
  VERSION=$("$TMP" version 2>&1 | head -1)
  echo "Downloaded: $VERSION"
else
  # Older binary without cobra — still valid
  echo "Downloaded binary"
fi

# Determine install location
INSTALL_DIR="/usr/local/bin"
if [ "$OS_NAME" = "linux" ]; then
  INSTALL_DIR="/opt/theia"
  if [ "$(id -u)" = "0" ]; then
    mkdir -p "$INSTALL_DIR"
  else
    echo ""
    echo "Root access required for installation."
    echo "Re-run with: curl -fsSL https://data-tamer.github.io/theia-client-releases/install.sh | sudo sh"
    echo ""
    echo "Or install manually:"
    echo "  sudo mkdir -p /opt/theia"
    echo "  sudo cp $TMP /opt/theia/theia"
    echo "  sudo chmod +x /opt/theia/theia"
    echo "  sudo /opt/theia/theia install"
    rm -f "$TMP"
    exit 1
  fi
fi

# Install binary
if [ -w "$INSTALL_DIR" ] || [ "$(id -u)" = "0" ]; then
  mkdir -p "$INSTALL_DIR"
  mv "$TMP" "${INSTALL_DIR}/${BINARY}"
  chmod +x "${INSTALL_DIR}/${BINARY}"
else
  echo "Installing to ${INSTALL_DIR} (requires sudo)..."
  sudo mkdir -p "$INSTALL_DIR"
  sudo mv "$TMP" "${INSTALL_DIR}/${BINARY}"
  sudo chmod +x "${INSTALL_DIR}/${BINARY}"
fi

echo "Installed to: ${INSTALL_DIR}/${BINARY}"

# Add to PATH if needed
case "$INSTALL_DIR" in
  /usr/local/bin|/usr/bin) ;; # Already on PATH
  *)
    if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
      ln -sf "${INSTALL_DIR}/${BINARY}" /usr/local/bin/${BINARY} 2>/dev/null || true
    fi
    ;;
esac

echo ""

# Run the built-in installer (creates service, downloads go2rtc)
echo "Setting up system service..."
if [ "$(id -u)" = "0" ]; then
  "${INSTALL_DIR}/${BINARY}" install
elif command -v sudo >/dev/null 2>&1; then
  sudo "${INSTALL_DIR}/${BINARY}" install
else
  "${INSTALL_DIR}/${BINARY}" install
fi

echo ""
echo "Done! Open http://localhost:8080/setup to configure."
echo ""
echo "Commands:"
echo "  theia status          # check status"
echo "  theia cameras list    # list cameras"
echo "  theia logs -f         # follow logs"
echo "  theia debug           # run diagnostics"
