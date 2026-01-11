#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Fast Ubuntu setup for:
# - fish shell v4 (PPA fish-shell/release-4) including:
#   - fisher
#   - tide@v6
#   - z
#   - dracula
#   - bass
#   - nvm.fish
# - Neovim v0.10.4 (tarball install)
# - Node.js v22 via nvm.fish (default version)
# - kitty terminal (official installer)
# - My dotfiles: https://github.com/jinchuangtw/dotfiles
#   and Neovim config: https://github.com/jinchuangtw/Jvim
# ------------------------------------------------------------

DOTFILES_REPO_URL="https://github.com/jinchuangtw/dotfiles"
JVIM_REPO_URL="https://github.com/jinchuangtw/Jvim"

# Neovim pinned version
NVIM_VERSION="0.10.4"
NVIM_TARBALL_URL="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"

# Accept optional args:
#   --dotfiles /path/on/usb/dotfiles
#   --fonts    /path/on/usb/fonts
DOTFILES_SRC=""
FONTS_SRC=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dotfiles) DOTFILES_SRC="${2:-}"; shift 2 ;;
    --fonts)    FONTS_SRC="${2:-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

log()  { printf "\033[1;32m[setup]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m  %s\n" "$*"; }
die()  { printf "\033[1;31m[err]\033[0m   %s\n" "$*"; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  die "Please run as a normal user (not root)."
fi

USER_NAME="${USER}"
HOME_DIR="${HOME}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME_DIR/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME_DIR/.local/share}"
LOCAL_BIN="$HOME_DIR/.local/bin"

mkdir -p "$LOCAL_BIN" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"

log "Updating apt + installing base packages…"
sudo apt update -y

# Base tools
sudo apt install -y \
  ca-certificates curl wget git gnupg lsb-release software-properties-common \
  build-essential pkg-config cmake ninja-build \
  unzip zip xz-utils tar jq \
  ripgrep fzf fd-find bat \
  tmux \
  python3 python3-pip python3-venv python-is-python3 \
  fontconfig pynvim

# Discard apt neovim
sudo apt purge neovim

# Clipboard helpers (Wayland/X11)
sudo apt install -y wl-clipboard xclip || true

# libfuse2 helps some AppImages; harmless even if we use tarball Neovim
sudo apt install -y libfuse2 || sudo apt install -y libfuse2t64 || true

log "Installing fish v4 from PPA (fish-shell/release-4)…"
if command -v fish >/dev/null 2>&1; then
  FISH_VER="$(fish --version | awk '{print $3}' || true)"
else
  FISH_VER=""
fi

# Install / upgrade fish to v4
if [[ -z "$FISH_VER" || "${FISH_VER%%.*}" -lt 4 ]]; then
  sudo apt-add-repository -y ppa:fish-shell/release-4
  sudo apt update -y
  sudo apt install -y fish
else
  log "fish already installed: $FISH_VER"
fi

# Make sure fish is a valid login shell
FISH_PATH="$(command -v fish)"
if ! grep -qx "$FISH_PATH" /etc/shells; then
  echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
fi

log "Installing kitty (official binary install)…"
if ! command -v kitty >/dev/null 2>&1; then
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
  ln -sf "$HOME_DIR/.local/kitty.app/bin/kitty"   "$LOCAL_BIN/kitty"
  ln -sf "$HOME_DIR/.local/kitty.app/bin/kitten" "$LOCAL_BIN/kitten"
else
  log "kitty already installed."
fi

log "Installing Neovim v${NVIM_VERSION} (tarball)…"
NVIM_DIR="$XDG_DATA_HOME/nvim/nvim-linux-x86_64-${NVIM_VERSION}"
mkdir -p "$XDG_DATA_HOME/nvim"

if [[ ! -x "$NVIM_DIR/bin/nvim" ]]; then
  tmp_tar="$(mktemp -t nvim.XXXXXX.tar.gz)"
  curl -L "$NVIM_TARBALL_URL" -o "$tmp_tar"
  rm -rf "$NVIM_DIR"
  mkdir -p "$NVIM_DIR"
  tar -xzf "$tmp_tar" -C "$XDG_DATA_HOME/nvim"
  # tarball extracts to "nvim-linux-x86_64"
  mv "$XDG_DATA_HOME/nvim/nvim-linux-x86_64" "$NVIM_DIR"
  rm -f "$tmp_tar"
fi
ln -sf "$NVIM_DIR/bin/nvim" "$LOCAL_BIN/nvim"

log "Picking dotfiles source…"
DOTFILES_DIR="$HOME_DIR/.dotfiles"
if [[ -n "$DOTFILES_SRC" ]]; then
  if [[ ! -d "$DOTFILES_SRC" ]]; then
    die "--dotfiles path not found: $DOTFILES_SRC"
  fi
  log "Using dotfiles from: $DOTFILES_SRC"
  rm -rf "$DOTFILES_DIR"
  # copy (USB might not be a git repo)
  rsync -a --delete "$DOTFILES_SRC"/ "$DOTFILES_DIR"/
else
  if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    log "Cloning dotfiles repo → $DOTFILES_DIR"
    rm -rf "$DOTFILES_DIR"
    git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
  else
    log "Dotfiles repo already exists → pulling latest"
    git -C "$DOTFILES_DIR" pull --ff-only || true
  fi
fi

log "Linking dotfiles (kitty/tmux/clangd/clang-format)…"
mkdir -p "$XDG_CONFIG_HOME/kitty" "$XDG_CONFIG_HOME/clangd"

link_if_exists() {
  local src="$1" dst="$2"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    log "linked: $dst → $src"
  else
    warn "missing: $src"
  fi
}

link_if_exists "$DOTFILES_DIR/kitty.conf"      "$XDG_CONFIG_HOME/kitty/kitty.conf"
link_if_exists "$DOTFILES_DIR/.tmux.conf"      "$HOME_DIR/.tmux.conf"
link_if_exists "$DOTFILES_DIR/.tmux.statusline.conf" "$HOME_DIR/.tmux.statusline.conf"
link_if_exists "$DOTFILES_DIR/config.yaml"     "$XDG_CONFIG_HOME/clangd/config.yaml"
link_if_exists "$DOTFILES_DIR/.clang-format"   "$HOME_DIR/.clang-format"

# Fish config: try a few common layouts (since GitHub UI sometimes hides listing)
log "Linking fish config (best-effort)…"
mkdir -p "$XDG_CONFIG_HOME/fish"

# candidate roots inside repo
FISH_CANDIDATES=(
  "$DOTFILES_DIR/fish/.config/fish"
  "$DOTFILES_DIR/fish"
)

for cand in "${FISH_CANDIDATES[@]}"; do
  if [[ -d "$cand" ]]; then
    if [[ -f "$cand/config.fish" || -d "$cand/conf.d" || -d "$cand/functions" ]]; then
      # Link key directories/files if present
      [[ -f "$cand/config.fish" ]] && ln -sfn "$cand/config.fish" "$XDG_CONFIG_HOME/fish/config.fish"
      [[ -d "$cand/conf.d" ]]     && ln -sfn "$cand/conf.d"     "$XDG_CONFIG_HOME/fish/conf.d"
      [[ -d "$cand/functions" ]]  && ln -sfn "$cand/functions"  "$XDG_CONFIG_HOME/fish/functions"
      [[ -f "$cand/fish_plugins" ]] && ln -sfn "$cand/fish_plugins" "$XDG_CONFIG_HOME/fish/fish_plugins"
      log "fish config linked from: $cand"
      break
    fi
  fi
done

log "Setting up Neovim config (Jvim)…"
JVIM_DIR="$HOME_DIR/.jvim"
if [[ ! -d "$JVIM_DIR/.git" ]]; then
  rm -rf "$JVIM_DIR"
  git clone "$JVIM_REPO_URL" "$JVIM_DIR"
else
  git -C "$JVIM_DIR" pull --ff-only || true
fi

# Backup existing nvim config if it exists and isn't symlink
NVIM_CFG_DIR="$XDG_CONFIG_HOME/nvim"
if [[ -e "$NVIM_CFG_DIR" && ! -L "$NVIM_CFG_DIR" ]]; then
  bk="$NVIM_CFG_DIR.backup.$(date +%Y%m%d%H%M%S)"
  mv "$NVIM_CFG_DIR" "$bk"
  warn "Backed up existing nvim config → $bk"
fi
ln -sfn "$JVIM_DIR" "$NVIM_CFG_DIR"

log "Installing fisher + fish plugins (tide@v6, z, dracula, bass, nvm.fish)…"
# Fisher install command from official docs
fish -lc 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher' >/dev/null

# Plugins listed in your dotfiles README (plus fzf.fish nice-to-have)
fish -lc 'fisher install IlanCosman/tide@v6 jethrokuan/z dracula/fish edc/bass jorgebucaran/nvm.fish ' >/dev/null

log "Installing Node.js v22 via nvm.fish + setting default…"
fish -lc 'nvm install v22; set --universal nvm_default_version v22' >/dev/null
fish -lc 'node -v && npm -v' || true

log "Installing Nerd Fonts from USB (optional)…"
if [[ -n "$FONTS_SRC" ]]; then
  if [[ ! -d "$FONTS_SRC" ]]; then
    die "--fonts path not found: $FONTS_SRC"
  fi
  mkdir -p "$XDG_DATA_HOME/fonts"
  rsync -a "$FONTS_SRC"/ "$XDG_DATA_HOME/fonts"/
  fc-cache -fv >/dev/null || true
  log "Fonts installed to: $XDG_DATA_HOME/fonts"
else
  warn "No --fonts provided; skipping font install."
fi

log "Setting fish as default shell (non-sudo chsh)…"
# chsh should be run as the user (sudo chsh can trigger PAM weirdness)
if [[ "${SHELL:-}" != "$FISH_PATH" ]]; then
  chsh -s "$FISH_PATH" "$USER_NAME" || warn "chsh failed (you can run: chsh -s $FISH_PATH)"
fi

cat <<'EOF'

Done.

Next steps I usually do (optional):
- Open a new terminal (or log out/in) so default shell switches to fish.
- Run:  tide configure

Quick checks:
- nvim --version
- fish --version
- kitty --version
- node -v / npm -v
EOF
