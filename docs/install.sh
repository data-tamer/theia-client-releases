#!/bin/sh
set -e

# Theia Client Installer
# Usage: curl -fsSL https://data-tamer.github.io/theia-client-releases/install.sh | sh

REPO="data-tamer/theia-client-releases"
INSTALL_DIR="/usr/local/bin"
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
  armv7l|armhf)    ARCH_NAME="arm64" ;;  # Best effort for 32-bit ARM
  *)               echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

ASSET="${BINARY}-${OS_NAME}-${ARCH_NAME}"
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
if ! "$TMP" version >/dev/null 2>&1; then
  echo "Error: downloaded binary is not valid"
  rm -f "$TMP"
  exit 1
fi

VERSION=$("$TMP" version 2>&1 | head -1)
echo "Downloaded: $VERSION"

# Install to PATH
if [ -w "$INSTALL_DIR" ]; then
  mv "$TMP" "${INSTALL_DIR}/${BINARY}"
else
  echo "Installing to ${INSTALL_DIR} (requires sudo)..."
  sudo mv "$TMP" "${INSTALL_DIR}/${BINARY}"
  sudo chmod +x "${INSTALL_DIR}/${BINARY}"
fi

echo "Installed to: ${INSTALL_DIR}/${BINARY}"
echo ""

# Run the built-in installer (creates service, downloads go2rtc)
echo "Setting up system service..."
if [ "$(id -u)" = "0" ]; then
  "${INSTALL_DIR}/${BINARY}" install
else
  sudo "${INSTALL_DIR}/${BINARY}" install
fi

echo ""
echo "Done! Open http://localhost:8080/setup to configure."
