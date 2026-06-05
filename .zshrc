export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  sudo
  zsh-autosuggestions
  zoxide
  zsh-syntax-highlighting
  zsh-completions
)

fix() {
  hyprctl keyword monitor "eDP-1,3000x1876@120,auto,1"
  sleep 0.5
  hyprctl keyword monitor "eDP-1,3000x1876@120,auto,1.33"

  pkill waybar
  sleep 0.5
  waybar & disown
}

mntssd() {
  sudo mkdir -p /mnt/windowsdisk
  sudo mount -t ntfs-3g UUID=EC9CF6169CF5DB52 /mnt/windowsdisk -o uid=$(id -u),gid=$(id -g),rw
  echo "SSD monté dans /mnt/windowsdisk"
}

source $ZSH/oh-my-zsh.sh

# History
HISTSIZE=5000
SAVEHIST=5000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
setopt AUTO_CD
setopt CORRECT

# Completion
autoload -Uz compinit && compinit

alias perf="echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
alias eco="echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"

# Zoxide
eval "$(zoxide init zsh)"


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

fastfetch


export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/home/amine/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/home/amine/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"

unsetopt correct