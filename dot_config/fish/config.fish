if not test -f ~/.config/fish/fish_env
    echo "Creating fish_env template..."
    echo "# Add your environment variables here" > ~/.config/fish/fish_env
    echo "# set -gx MY_VAR value" >> ~/.config/fish/fish_env
end

source ~/.config/fish/fish_env

switch (uname)
    case Linux
        # CachyOS ships its own fish config; guard it so plain Arch works too
        if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
            source /usr/share/cachyos-fish-config/cachyos-config.fish
        end
    case Darwin
        # fish-native Homebrew setup (brew shellenv emits POSIX syntax
        # unless the login shell is already fish, so do it manually)
        for brew_prefix in /opt/homebrew /usr/local
            if test -x $brew_prefix/bin/brew
                set -gx HOMEBREW_PREFIX $brew_prefix
                set -gx HOMEBREW_CELLAR $brew_prefix/Cellar
                set -gx HOMEBREW_REPOSITORY $brew_prefix
                fish_add_path $brew_prefix/bin $brew_prefix/sbin
                break
            end
        end
        if test -d /Applications/Ghostty.app/Contents/MacOS
            fish_add_path /Applications/Ghostty.app/Contents/MacOS
        end
    case '*'
end

function fish_greeting
    clear
end

# Run starship prompt
starship init fish | source

# Replace ls with eza
alias ls='eza -al --color=always --group-directories-first --icons' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons' # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons' # long format
alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
alias l.="eza -a | grep -e '^\.'" # show only dotfiles

# Add ~/.local/bin to PATH
if test -d "$HOME/.local/bin"
    fish_add_path $HOME/.local/bin
end
