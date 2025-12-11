cdh() {
    # Define the path to the directory history file
    local history_file="${DIR_HISTORY_FILE:-$HOME/.dir_history}"
    local max_history="${CDH_MAX_HISTORY:-100}"
    local usage="Usage:
    cdh                    - List all directories in history with line numbers
    cdh add [directory]    - Add current or specified directory to history
    cdh remove <index>     - Remove directory at the specified index
    cdh <index>            - Change to directory at the specified index
    cdh clean              - Clear the directory history
    cdh help               - Show this help message
    
Environment variables:
    DIR_HISTORY_FILE       - History file path (default: ~/.dir_history)
    CDH_AUTO_TRACK         - Auto-track on cd (default: 1, set to 0 to disable)
    CDH_MAX_HISTORY        - Maximum history entries (default: 100)"

    # Create history file if it doesn't exist
    if [[ ! -f "$history_file" ]]; then
        touch "$history_file"
    fi

    case "${1:-}" in
    add)
        local new_dir
        if [[ $# -lt 2 ]]; then
            # No argument - use current directory
            new_dir=$(pwd)
        else
            # Directory argument provided
            new_dir="${*:2}"
            echo "Changing to directory: $new_dir"
            
            # Change to the new directory
            if ! cd "$new_dir"; then
                echo "Error: Failed to change to directory: $new_dir"
                return 1
            fi
            new_dir=$(pwd)
        fi
        
        # Check if directory already exists anywhere in history
        if [[ -s "$history_file" ]] && grep -Fxq "$new_dir" "$history_file"; then
            echo "Directory already exists in history, skipping duplicate"
            return 0
        fi
        
        # Add to history
        echo "$new_dir" >> "$history_file"
        
        # Trim history if it exceeds max size
        local total_lines
        total_lines=$(wc -l < "$history_file" | tr -d ' ')
        if [[ $total_lines -gt $max_history ]]; then
            local temp_file="${history_file}.tmp"
            tail -n "$max_history" "$history_file" > "$temp_file"
            mv "$temp_file" "$history_file"
        fi
        
        echo "✓ Directory added to history: $new_dir"
        ;;

    remove)
        if [[ $# -lt 2 ]]; then
            echo "Error: 'remove' requires an index argument"
            echo "Usage: cdh remove <index>"
            return 1
        fi
        
        if [[ ! -s "$history_file" ]]; then
            echo "Error: No directories in history"
            return 1
        fi
        
        local index="$2"
        local total_lines
        total_lines=$(wc -l < "$history_file" | tr -d ' ')
        
        if [[ ! "$index" =~ ^[0-9]+$ ]] || [[ $index -lt 1 || $index -gt $total_lines ]]; then
            echo "Error: Invalid index $index (must be 1-$total_lines)"
            return 1
        fi
        
        local removed_dir
        removed_dir=$(sed -n "${index}p" "$history_file")
        
        # Remove the line
        local temp_file="${history_file}.tmp"
        sed "${index}d" "$history_file" > "$temp_file"
        mv "$temp_file" "$history_file"
        
        echo "✓ Removed from history: $removed_dir"
        ;;

    clean)
        if [[ -f "$history_file" ]]; then
            : > "$history_file"
            echo "✓ Directory history cleared"
        else
            echo "History file does not exist: $history_file"
        fi
        ;;

    help|-h|--help)
        echo "$usage"
        ;;

    [0-9]*)
        # Handle numeric argument - change to directory by index
        if [[ ! -s "$history_file" ]]; then
            echo "Error: No directories in history"
            return 1
        fi

        local index="$1"
        local total_lines
        total_lines=$(wc -l < "$history_file" | tr -d ' ')
        
        if [[ $index -lt 1 || $index -gt $total_lines ]]; then
            echo "Error: Index $index out of range (1-$total_lines)"
            return 1
        fi

        local target_dir
        target_dir=$(sed -n "${index}p" "$history_file")
        
        if [[ -n "$target_dir" && -d "$target_dir" ]]; then
            cd "$target_dir" || {
                echo "Error: Cannot access directory: $target_dir"
                return 1
            }
            echo "✓ Changed to directory #$index: $target_dir"
        else
            echo "Error: Directory not found or inaccessible at index $index: $target_dir"
            return 1
        fi
        ;;

    "")
        # No arguments - list all directories
        if [[ ! -s "$history_file" ]]; then
            echo "No directories in history"
            echo "Use 'cdh add' to add the current directory"
            return 0
        fi

        echo "Directory history:"
        local line_num=0
        while IFS= read -r dir; do
            ((line_num++))
            if [[ -d "$dir" ]]; then
                printf "%2d: %s\n" "$line_num" "$dir"
            else
                printf "%2d: %s [MISSING]\n" "$line_num" "$dir"
            fi
        done < "$history_file"
        ;;

    *)
        echo "Error: Unknown command or invalid index: $1"
        echo "$usage"
        return 1
        ;;
    esac
}

# Auto-tracking function
_cdh_track() {
    local history_file="${DIR_HISTORY_FILE:-$HOME/.dir_history}"
    local current_dir max_history total_lines
    
    # Skip if auto-tracking is disabled
    [[ "${CDH_AUTO_TRACK:-1}" == "0" ]] && return 0
    
    current_dir=$(pwd)
    
    # Skip if directory already exists in history
    if [[ -s "$history_file" ]] && grep -Fxq "$current_dir" "$history_file"; then
        return 0
    fi
    
    # Create history file if needed
    if [[ ! -f "$history_file" ]]; then
        touch "$history_file"
    fi
    
    # Add to history
    echo "$current_dir" >> "$history_file"
    
    # Trim history if needed
    max_history="${CDH_MAX_HISTORY:-100}"
    total_lines=$(wc -l < "$history_file" | tr -d ' ')
    if [[ $total_lines -gt $max_history ]]; then
        local temp_file="${history_file}.tmp"
        tail -n "$max_history" "$history_file" > "$temp_file"
        mv "$temp_file" "$history_file"
    fi
}

# Set up auto-tracking via chpwd hook (zsh only)
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -U add-zsh-hook
    add-zsh-hook chpwd _cdh_track
fi
