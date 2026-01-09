# cdh - Change Directory History

## Overview

The function stores directory paths in a history file (default: `~/.dir_history`).  
Directories are tracked automatically as you navigate, or you can add them manually.  
Use interactive fuzzy search (fzf) or numeric indexes to quickly jump between directories.

---

## Usage

| Command | Description |
|----------|-------------|
| `cdh` | Interactive fuzzy selection (fzf) or list all directories |
| `cdh ls` | List all directories with line numbers |
| `cdh add` | Add current directory to history |
| `cdh add <directory>` | Add a specific directory to history |
| `cdh <index>` | Change to directory at the given index |
| `cdh remove <index>` | Remove directory at the specified index |
| `cdh clean` | Clear the directory history |
| `cdh config` | Show current configuration |
| `cdh config <key> <value>` | Set configuration option |
| `cdh help` | Show help message |

---

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `auto_track` | 1 | Auto-track directories as you navigate |
| `root_only` | 1 | Skip subdirectories of already tracked directories |
| `max_history` | 100 | Maximum number of history entries |

### Examples

```bash
cdh config auto_track 0     # Disable auto-tracking
cdh config root_only 0      # Track all directories (not just roots)
cdh config max_history 200  # Increase history size
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DIR_HISTORY_FILE` | `~/.dir_history` | Path to history file |
| `DIR_HISTORY_CONFIG` | `~/.cdh_config` | Path to config file |
| `CDH_AUTO_TRACK` | 1 | Enable/disable auto-tracking |
| `CDH_TRACK_ROOT_ONLY` | 1 | Track only root directories |
| `CDH_MAX_HISTORY` | 100 | Maximum history entries |

---

## Example Workflow

```bash
# Navigate around - directories are tracked automatically
cd ~/projects/my-app
cd ~/documents/notes

# View history interactively (requires fzf)
cdh

# Or list with numbers
cdh ls

# Jump to directory #3
cdh 3

# Disable auto-tracking
cdh config auto_track 0

# Manually add current directory
cdh add

# Remove directory at index 5
cdh remove 5

# Clear all history
cdh clean
```

---

## Features

- **Auto-tracking**: Automatically tracks directories as you navigate
- **Smart root detection**: Prevents tracking subdirectories of already tracked paths
- **Interactive search**: Fuzzy find with live preview (requires fzf)
- **Fast navigation**: Jump to any directory by index
- **Configurable**: Customize behavior via CLI or environment variables
- **Clean history**: Automatically removes missing directories and manages size

---

## Installation

**Option 1**: Add to your `~/.zshrc`:

```bash
# Copy the entire cdh() function and _cdh_track() function to ~/.zshrc
```

**Option 2**: Source the file from your `~/.zshrc`:

```bash
source /path/to/cdh.zsh
```

Then reload your shell:

```bash
source ~/.zshrc
```

---

## Requirements

- **Required**: Zsh shell
- **Optional**: [fzf](https://github.com/junegunn/fzf) for interactive fuzzy selection

Without fzf, `cdh` falls back to listing directories with numbers.
