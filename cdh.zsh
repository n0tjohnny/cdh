#!/usr/bin/env bash
#
# cdh - Change Directory History | @n0tjohnny

# Find project root by looking for common markers
_cdh_find_root() {
    local dir="$1"
    local markers=(".git" ".hg" "package.json" "Cargo.toml" "go.mod" "pom.xml" "Makefile")
    
    while [[ "$dir" != "/" ]]; do
        for marker in "${markers[@]}"; do
            if [[ -e "$dir/$marker" ]]; then
                echo "$dir"
                return 0
            fi
        done
        dir=$(dirname "$dir")
    done
    
    # No root found, return original directory
    echo "$1"
}

# Add directory to history
_cdh_add() {
    local dir="$1"
    local history_file="${DIR_HISTORY_FILE:-$HOME/.dir_history}"
    local max_history="${CDH_MAX_HISTORY:-100}"
    
    # Skip if already in history
    [[ -s "$history_file" ]] && grep -Fxq "$dir" "$history_file" && return 0
    
    # Create file if needed
    [[ ! -f "$history_file" ]] && touch "$history_file"
    
    # Add to history
    echo "$dir" >> "$history_file"
    
    # Trim if too long
    local lines=$(wc -l < "$history_file" | tr -d ' ')
    if [[ $lines -gt $max_history ]]; then
        tail -n "$max_history" "$history_file" > "${history_file}.tmp"
        mv "${history_file}.tmp" "$history_file"
    fi
}

# Main function
cdh() {
    local history_file="${DIR_HISTORY_FILE:-$HOME/.dir_history}"
    
    case "${1:-}" in
        add)
            local target="${2:-$(pwd)}"
            if [[ ! -d "$target" ]]; then
                echo "Error: Directory not found: $target"
                return 1
            fi
            
            cd "$target" || return 1
            local dir=$(pwd)
            
            # Find root if enabled
            if [[ "${CDH_AUTO_TRACK_ROOT_ONLY:-1}" == "1" ]]; then
                dir=$(_cdh_find_root "$dir")
            fi
            
            _cdh_add "$dir"
            echo "✓ Added to history: $dir"
            ;;
            
        remove|rm)
            if [[ -z "${2:-}" ]]; then
                echo "Usage: cdh remove <index>"
                return 1
            fi
            
            local index="$2"
            local total=$(wc -l < "$history_file" 2>/dev/null | tr -d ' ')
            
            if [[ ! "$index" =~ ^[0-9]+$ ]] || [[ $index -lt 1 || $index -gt ${total:-0} ]]; then
                echo "Error: Invalid index (must be 1-${total:-0})"
                return 1
            fi
            
            local removed=$(sed -n "${index}p" "$history_file")
            sed -i.bak "${index}d" "$history_file" && rm "${history_file}.bak"
            echo "✓ Removed: $removed"
            ;;
            
        clean|clear)
            > "$history_file"
            echo "✓ History cleared"
            ;;
            
        config)
            echo "Current configuration:"
            echo "  DIR_HISTORY_FILE: ${DIR_HISTORY_FILE:-$HOME/.dir_history}"
            echo "  CDH_AUTO_TRACK: ${CDH_AUTO_TRACK:-1} (1=enabled, 0=disabled)"
            echo "  CDH_AUTO_TRACK_ROOT_ONLY: ${CDH_AUTO_TRACK_ROOT_ONLY:-1} (1=root only, 0=all dirs)"
            echo "  CDH_MAX_HISTORY: ${CDH_MAX_HISTORY:-100}"
            echo "  CDH_USE_FZF: ${CDH_USE_FZF:-1} (1=use fzf if available, 0=disabled)"
            echo ""
            echo "Set in ~/.bashrc or ~/.zshrc:"
            echo "  export CDH_AUTO_TRACK=0              # Disable auto-tracking"
            echo "  export CDH_AUTO_TRACK_ROOT_ONLY=0    # Track all dirs, not just roots"
            ;;
            
        help|-h|--help)
            cat << 'EOF'
cdh - Directory history navigator

Usage:
    cdh                 - List history (or use fzf if available)
    cdh <index>         - Change to directory at index
    cdh add [dir]       - Add directory to history
    cdh remove <index>  - Remove entry at index
    cdh clean           - Clear history
    cdh config          - Show configuration
    
Environment variables:
    DIR_HISTORY_FILE           - History file path (default: ~/.dir_history)
    CDH_AUTO_TRACK             - Auto-track on cd (default: 1)
    CDH_AUTO_TRACK_ROOT_ONLY   - Only track project roots (default: 1)
    CDH_MAX_HISTORY            - Max entries (default: 100)
    CDH_USE_FZF                - Use fzf for selection (default: 1)
EOF
            ;;
            
        [0-9]*)
            # Jump to index
            if [[ ! -s "$history_file" ]]; then
                echo "No history"
                return 1
            fi
            
            local index="$1"
            local total=$(wc -l < "$history_file" | tr -d ' ')
            
            if [[ $index -lt 1 || $index -gt $total ]]; then
                echo "Error: Index out of range (1-$total)"
                return 1
            fi
            
            local target=$(sed -n "${index}p" "$history_file")
            
            if [[ ! -d "$target" ]]; then
                echo "Error: Directory not found: $target"
                return 1
            fi
            
            cd "$target" && echo "✓ #$index: $target"
            ;;
            
        "")
            # List or use fzf
            if [[ ! -s "$history_file" ]]; then
                echo "No history. Use 'cdh add' to start tracking."
                return 0
            fi
            
            # Try fzf if enabled and available
            if [[ "${CDH_USE_FZF:-1}" == "1" ]] && command -v fzf &>/dev/null; then
                local selected
                selected=$(nl -w2 -s': ' "$history_file" | fzf --height 40% --reverse --preview 'echo {2..} | xargs ls -lah 2>/dev/null || echo "Directory not found"' --preview-window=down:3) || return 0
                
                if [[ -n "$selected" ]]; then
                    local target=$(echo "$selected" | awk -F': ' '{print $2}')
                    cd "$target" && echo "✓ $target"
                fi
            else
                # Simple listing
                echo "Directory history:"
                local i=0
                while IFS= read -r dir; do
                    ((i++))
                    if [[ -d "$dir" ]]; then
                        printf "%2d: %s\n" "$i" "$dir"
                    else
                        printf "%2d: %s [MISSING]\n" "$i" "$dir"
                    fi
                done < "$history_file"
            fi
            ;;
            
        *)
            echo "Unknown command: $1"
            echo "Use 'cdh help' for usage"
            return 1
            ;;
    esac
}

# Auto-tracking function
_cdh_track() {
    [[ "${CDH_AUTO_TRACK:-1}" == "0" ]] && return 0
    
    local dir=$(pwd)
    
    # Find root if enabled
    if [[ "${CDH_AUTO_TRACK_ROOT_ONLY:-1}" == "1" ]]; then
        dir=$(_cdh_find_root "$dir")
    fi
    
    _cdh_add "$dir"
}

# Setup for zsh
if [[ -n "${ZSH_VERSION:-}" ]]; then
    autoload -U add-zsh-hook 2>/dev/null && add-zsh-hook chpwd _cdh_track
fi

# Setup for bash (requires PROMPT_COMMAND)
if [[ -n "${BASH_VERSION:-}" ]]; then
    _cdh_prompt_command() {
        local exit_code=$?
        _cdh_track
        return $exit_code
    }
    
    if [[ "$PROMPT_COMMAND" != *"_cdh_prompt_command"* ]]; then
        PROMPT_COMMAND="_cdh_prompt_command${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    fi
fi