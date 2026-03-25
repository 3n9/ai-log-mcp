GOPATH_BIN := $(shell go env GOPATH)/bin
GO         := go
LDFLAGS    := -s -w
DIST       := dist

INSTALL_DIR ?= $(HOME)/.local/bin

.PHONY: all clean build install uninstall install-global-mcp install-mcp-servers

all: \
	$(DIST)/darwin-arm64/ai-log-mcp \
	$(DIST)/darwin-amd64/ai-log-mcp \
	$(DIST)/linux-amd64/ai-log-mcp \
	$(DIST)/windows-amd64/ai-log-mcp.exe

# ── macOS arm64 (Apple Silicon) ───────────────────────────────────────────────
$(DIST)/darwin-arm64/ai-log-mcp:
	@mkdir -p $(DIST)/darwin-arm64
	GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 $(GO) build -ldflags "$(LDFLAGS)" -o $@ ./cmd/ai-log-mcp

# ── macOS amd64 (Intel) ───────────────────────────────────────────────────────
$(DIST)/darwin-amd64/ai-log-mcp:
	@mkdir -p $(DIST)/darwin-amd64
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 $(GO) build -ldflags "$(LDFLAGS)" -o $@ ./cmd/ai-log-mcp

# ── Linux amd64 ───────────────────────────────────────────────────────────────
$(DIST)/linux-amd64/ai-log-mcp:
	@mkdir -p $(DIST)/linux-amd64
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 $(GO) build -ldflags "$(LDFLAGS)" -o $@ ./cmd/ai-log-mcp

# ── Windows amd64 ─────────────────────────────────────────────────────────────
$(DIST)/windows-amd64/ai-log-mcp.exe:
	@mkdir -p $(DIST)/windows-amd64
	GOOS=windows GOARCH=amd64 CGO_ENABLED=0 $(GO) build -ldflags "$(LDFLAGS)" -o $@ ./cmd/ai-log-mcp

# ── dev shortcut (native) ─────────────────────────────────────────────────────
build:
	$(GO) build -o $(DIST)/ai-log-mcp ./cmd/ai-log-mcp

clean:
	rm -rf $(DIST)

# ── install (native build → ~/.local/bin) ────────────────────────────────────
install: build
	@mkdir -p $(INSTALL_DIR)
	cp $(DIST)/ai-log-mcp $(INSTALL_DIR)/
	@echo "installed to $(INSTALL_DIR)"
	@echo "make sure $(INSTALL_DIR) is in your PATH"

uninstall:
	rm -f $(INSTALL_DIR)/ai-log-mcp
	@echo "uninstalled from $(INSTALL_DIR)"

# ── MCP server registration + auto-accept for all agents ─────────────────────
install-global-mcp:
	@bash scripts/install-global-mcp.sh

install-mcp-servers: install
	@bash scripts/install-mcp-servers.sh
