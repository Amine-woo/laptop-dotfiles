# =========================
# Oh My Zsh base config
# =========================

# Path to Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
# Important:
# - zsh-syntax-highlighting should stay last
# - zoxide is initialized manually later with --cmd cd, so don't put it here
plugins=(
  git
  sudo
  zsh-completions
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"


# =========================
# Environment variables
# =========================

# Flatpak apps integration
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"


# =========================
# History settings
# =========================

# Bigger shell history
HISTSIZE=5000
SAVEHIST=5000

# Avoid duplicated commands in history
setopt HIST_IGNORE_DUPS

# Share history between opened terminals
setopt SHARE_HISTORY


# =========================
# Navigation
# =========================

# Allows typing a folder name directly instead of cd folder
setopt AUTO_CD

# Disable annoying zsh autocorrect
unsetopt CORRECT

# Zoxide smart cd
# This makes commands like:
#   cd laptop
#   cd dotfiles
# jump to frequently used folders automatically
eval "$(zoxide init zsh --cmd cd)"


# =========================
# Custom functions
# =========================

# Fix laptop screen scale issue and restart Waybar
fix() {
  hyprctl keyword monitor "eDP-1,3000x1876@120,auto,1"
  sleep 0.5
  hyprctl keyword monitor "eDP-1,3000x1876@120,auto,1.33"

  pkill waybar
  sleep 0.5
  waybar & disown
}

# Mount Windows SSD partition to /mnt/windowsdisk
mntssd() {
  sudo mkdir -p /mnt/windowsdisk
  sudo mount -t ntfs-3g UUID=EC9CF6169CF5DB52 /mnt/windowsdisk -o uid=$(id -u),gid=$(id -g),rw
  echo "SSD monté dans /mnt/windowsdisk"
}


# =========================
# Aliases
# =========================

# Set CPU governor to performance mode
alias perf="echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"

# Set CPU governor to power saving mode
alias eco="echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"

# Quick shortcut to dotfiles repo
alias laptop="cd ~/code/laptop-dotfiles"


# =========================
# Powerlevel10k prompt
# =========================

# To customize prompt, run:
#   p10k configure
[[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"


# =========================
# Startup command
# =========================

# Show system info when opening terminal
fastfetch