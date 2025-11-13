# cdh - Change Directory History

`cdh` is a simple shell function to manage and navigate your directory history.  
It saves directories you visit so you can easily list and return to them later.

---

## Overview

The function stores directory paths in a history file (default: `~/.dir_history`).  
You can add directories manually and switch between them by using numeric indexes.

---

## Usage

| Command | Description |
|----------|-------------|
| `cdh` | List all directories in history with line numbers |
| `cdh add` | Add current directory to history |
| `cdh add <directory>` <directory> | Add a specific directory to history |
| `cdh <index>` | Change to directory at the given index |
| `cdh clean` | Clear the directory history |
| `cdh help` | Show help message |

---

## Example

1. Add current directory  
   cdh add  

2. Add another directory  
   cdh add ~/projects/demo  

3. List directories  
   cdh  

4. Go to the 3rd directory in the list  
   cdh 3  

5. Clear history  
   cdh clean  

---

## Configuration

The default history file path is:  
`~/.dir_history`

You can change this by setting the `DIR_HISTORY_FILE` environment variable:  
`export DIR_HISTORY_FILE="/path/to/custom_history_file"`

---

## Installation

Option 1) Add the `cdh()` function to your shell configuration file: `~/.zshrc`.

Option 2) Add in the last line of your `~/.zshrc`, `source /path/to/cdh.zsh`.

Reload the configuration file to make the command available.
`source ~/.zshrc`.

After that, you can use `cdh` directly from your terminal.
