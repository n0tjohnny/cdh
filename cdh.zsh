cdh() {
    # Define the path to the directory history file
    local history_file="${DIR_HISTORY_FILE:-$HOME/.dir_history}"
    local usage="Usage:
    cdh                    - List all directories in history with line numbers
    cdh add <directory>    - Add current directory to history after changing to it
    cdh <index>            - Change to directory at the specified index
    cdh clean              - Clear the directory history
    cdh help               - Show this help message"

    # Create history file if it doesn't exist
    if [[ ! -f "$history_file" ]]; then
        touch "$history_file"
    fi

    case "${1:-}" in
    add)
        if [[ $# -lt 2 ]]; then
            echo "Error: 'add' requires a directory argument"
            echo "Usage: cdh add <directory>"
            return 1
        fi

        local new_dir="${*:2}"
        echo "Changing to directory: $new_dir"
        
        # Change to the new directory
        if cd "$new_dir"; then
            local current_dir current_dir_escaped
            current_dir=$(pwd)
            current_dir_escaped=$(printf '%q' "$current_dir")
            
            # Read the last directory from history, handling empty file
            local last_dir=""
            if [[ -s "$history_file" ]]; then
                last_dir=$(tail -n 1 "$history_file")
            fi
            
            # Only add if it's different from the last entry
            if [[ "$current_dir" != "$last_dir" ]]; then
                echo "$current_dir" >> "$history_file"
                echo "✓ Directory added to history: $current_dir"
            else
                echo "Directory already exists as last entry, skipping duplicate"
            fi
        else
            echo "Error: Failed to change to directory: $new_dir"
            return 1
        fi
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
            echo "Use 'cdh add <directory>' to add directories"
            return 0
        fi

        echo "Directory history:"
        nl -w2 -s': ' "$history_file"
        ;;

    *)
        echo "Error: Unknown command or invalid index: $1"
        echo "$usage"
        return 1
        ;;
    esac
}

# Only set up autoload for zsh
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -Uz cdh
fi