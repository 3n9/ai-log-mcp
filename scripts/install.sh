#!/usr/bin/env sh
# One-stop install: ai-log + ai-log-report + ai-log-mcp.
# Downloads all three binaries from GitHub Releases, initialises the database,
# and registers the MCP server with every detected AI agent CLI.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/3n9/ai-log-mcp/main/scripts/install.sh | sh
#
# Environment variables:
#   INSTALL_DIR    — binary destination (default: ~/.local/bin)
#   CORE_VERSION   — ai-agent-telemetry release tag (default: latest)
#   MCP_VERSION    — ai-log-mcp release tag (default: latest)

set -e

CORE_REPO="3n9/ai-agent-telemetry"
MCP_REPO="3n9/ai-log-mcp"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
CORE_VERSION="${CORE_VERSION:-}"
MCP_VERSION="${MCP_VERSION:-}"

# ── Detect OS and architecture ───────────────────────────────────────────────

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  darwin) PLAT="darwin" ;;
  linux)  PLAT="linux"  ;;
  *)
    echo "❌ Unsupported OS: $OS"
    echo "   Download manually: https://github.com/$MCP_REPO/releases"
    exit 1
    ;;
esac

case "$ARCH" in
  arm64|aarch64) PLAT="${PLAT}-arm64" ;;
  x86_64|amd64)  PLAT="${PLAT}-amd64" ;;
  *)
    echo "❌ Unsupported architecture: $ARCH"
    echo "   Download manually: https://github.com/$MCP_REPO/releases"
    exit 1
    ;;
esac

if [ "$OS" = "linux" ] && [ "$PLAT" != "linux-amd64" ]; then
  echo "❌ Linux/$ARCH is not yet supported."
  exit 1
fi

# ── Resolve latest release versions ─────────────────────────────────────────

_latest() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep '"tag_name"' \
    | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/'
}

if [ -z "$CORE_VERSION" ]; then
  echo "🔍 Fetching latest ai-agent-telemetry release..."
  CORE_VERSION=$(_latest "$CORE_REPO")
fi

if [ -z "$MCP_VERSION" ]; then
  echo "🔍 Fetching latest ai-log-mcp release..."
  MCP_VERSION=$(_latest "$MCP_REPO")
fi

if [ -z "$CORE_VERSION" ] || [ -z "$MCP_VERSION" ]; then
  echo "❌ Could not determine release versions. Set CORE_VERSION= / MCP_VERSION= manually."
  exit 1
fi

# ── Download archives ────────────────────────────────────────────────────────

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "📦 Downloading ai-agent-telemetry $CORE_VERSION for $PLAT..."
curl -fsSL \
  "https://github.com/$CORE_REPO/releases/download/$CORE_VERSION/ai-agent-telemetry-${PLAT}.tar.gz" \
  -o "$TMP_DIR/core.tar.gz"
tar -xzf "$TMP_DIR/core.tar.gz" -C "$TMP_DIR"

echo "📦 Downloading ai-log-mcp $MCP_VERSION for $PLAT..."
curl -fsSL \
  "https://github.com/$MCP_REPO/releases/download/$MCP_VERSION/ai-log-mcp-${PLAT}.tar.gz" \
  -o "$TMP_DIR/mcp.tar.gz"
tar -xzf "$TMP_DIR/mcp.tar.gz" -C "$TMP_DIR"

# ── Install binaries ─────────────────────────────────────────────────────────

mkdir -p "$INSTALL_DIR"
mv "$TMP_DIR/ai-log"        "$INSTALL_DIR/ai-log"
mv "$TMP_DIR/ai-log-report" "$INSTALL_DIR/ai-log-report"
mv "$TMP_DIR/ai-log-mcp"    "$INSTALL_DIR/ai-log-mcp"
chmod +x "$INSTALL_DIR/ai-log" "$INSTALL_DIR/ai-log-report" "$INSTALL_DIR/ai-log-mcp"

echo "✅ Installed ai-log, ai-log-report, and ai-log-mcp to $INSTALL_DIR"

if ! echo ":$PATH:" | grep -q ":$INSTALL_DIR:"; then
  echo ""
  echo "⚠️  $INSTALL_DIR is not in your PATH. Add this to your shell profile:"
  echo "   export PATH=\"\$PATH:$INSTALL_DIR\""
  echo ""
  export PATH="$PATH:$INSTALL_DIR"
fi

# ── Initialise database ──────────────────────────────────────────────────────

echo ""
echo "🗄️  Initialising telemetry database..."
ai-log init

# ── Register MCP server with agent CLIs ─────────────────────────────────────

echo ""
echo "🔧 Registering MCP server with installed agent CLIs..."

# When piped through curl, $0 is "sh"; detect a sibling script on disk first.
_SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || echo "")"
REGISTER_SCRIPT="$_SCRIPT_DIR/install-mcp-servers.sh"

if [ -f "$REGISTER_SCRIPT" ]; then
  bash "$REGISTER_SCRIPT"
else
  curl -fsSL \
    "https://raw.githubusercontent.com/$MCP_REPO/main/scripts/install-mcp-servers.sh" \
    -o "$TMP_DIR/install-mcp-servers.sh"
  bash "$TMP_DIR/install-mcp-servers.sh"
fi

echo ""
echo "✨ All done!"
echo "   Run 'ai-log-report summary' to view telemetry."
echo "   Run 'ai-log-report dashboard' for an HTML overview."
