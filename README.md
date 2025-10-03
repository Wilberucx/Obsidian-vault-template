# Obsidian Vault Creator

A smart PowerShell script to automatically create new Obsidian vaults for the next year based on JSON configuration.

## Features

- 🔄 **Automatic Year Detection**: Automatically detects current year and creates vault for next year
- 📁 **Flexible Copying**: Copy complete folders, specific files, or create empty folder structures
- 🗑️ **Smart Exclusion**: Remove unwanted files from .obsidian configuration
- 📝 **Template Support**: Create base files with variable replacement (year, date)
- 🔧 **Backup Support**: Optional backup before creating new vault
- 📊 **Validation Mode**: Test configuration without making changes
- 🎨 **Colored Output**: Clear, colored console output with timestamps
- 📜 **Logging**: Optional operation logging to file
- 🔗 **Git Integration**: Optional Git repository initialization
- 🚀 **Auto-Open**: Automatically open new vault in Obsidian

## Usage

### Basic Usage
```powershell
.\Create-New-Vault.ps1
```

**Note:** This command works if you have `config-template.json` in the same folder as the script. Make sure to customize the configuration file with your specific paths and structure before running the script.

### Advanced Options
```powershell
# Use custom config file
.\Create-New-Vault.ps1 -ConfigPath ".\my-config.json"

# Create vault for specific year
.\Create-New-Vault.ps1 -TargetYear 2025

# Force creation (overwrite existing vault)
.\Create-New-Vault.ps1 -ForceCreation

# Validation mode only (no changes)
.\Create-New-Vault.ps1 -ValidateOnly
```

## Configuration

Copy `config-template.json` to create your configuration file. The script looks for configuration in the following order:
1. File specified with `-ConfigPath` parameter
2. `config-template.json` in script directory

### Configuration Structure

```json
{
  "base_vault_path": "C:\\Users\\YourUsername\\Documents\\Obsidian Vaults",
  "name_pattern": "Vault-{year}",
  "copy_complete": [
    ".obsidian",
    "Templates",
    "Attachments",
    "Resources"
  ],
  "exclude_from_obsidian": [
    ".obsidian/workspace.json",
    ".obsidian/workspace-mobile.json",
    ".obsidian/cache"
  ],
  "copy_files": [
    "README.md",
    "Index.md",
    "Projects/Projects.md",
    "Areas/Areas.md",
    "Resources/Resources.md"
  ],
  "create_empty_folders": [
    "Daily Notes",
    "Weekly Reviews", 
    "Monthly Reviews",
    "Projects",
    "Areas",
    "Archive",
    "Inbox",
    "Templates",
    "Attachments",
    "Resources"
  ],
  "create_base_files": {
    "Welcome-{year}.md": "# Welcome to {year}\n\nThis vault was created on {date}...",
    "Index.md": "# {year} Vault Index\n\nMain navigation for the {year} vault..."
  },
  "options": {
    "create_git_repo": true,
    "open_new_vault": false,
    "backup_before_create": true,
    "log_operations": true
  }
}
```

### Configuration Options

| Option | Description |
|--------|-------------|
| `base_vault_path` | Base directory where vaults are stored |
| `name_pattern` | Naming pattern for vaults (use `{year}` placeholder) |
| `copy_complete` | Array of folders to copy entirely |
| `exclude_from_obsidian` | Files to remove after copying .obsidian |
| `copy_files` | Array of specific files to copy |
| `create_empty_folders` | Array of empty folders to create |
| `create_base_files` | Object with filename: content pairs for template files |
| `options.backup_before_create` | Create backup if target vault exists before overwriting |
| `options.log_operations` | Enable logging to vault-template.log file |
| `options.create_git_repo` | Initialize Git repository in the new vault |
| `options.open_new_vault` | Automatically open vault in Obsidian after creation |

#### Options Detailed Explanation

**`create_git_repo`** (boolean): 
- `true`: Initializes a Git repository in the new vault and makes an initial commit
- `false`: Creates vault without Git version control

**`open_new_vault`** (boolean):
- `true`: Automatically opens the new vault in Obsidian using URI protocol
- `false`: Creates vault but doesn't open it (you'll need to open manually)

**`backup_before_create`** (boolean):
- `true`: Creates a timestamped backup copy before overwriting existing vault (only when using `-ForceCreation`)
- `false`: Overwrites existing vault directly without backup

**`log_operations`** (boolean):
- `true`: Logs all operations to `vault-template.log` file with timestamps
- `false`: No logging (only console output)

### Template Variables

Use these variables in `create_base_files` content:
- `{year}` - Target year
- `{date}` - Current date (yyyy-MM-dd format)

## Requirements

- PowerShell 5.1 or later
- Obsidian installed (for auto-open feature)
- Git (if using Git integration)

## Examples

### Creating a 2025 vault
```powershell
.\Create-New-Vault.ps1 -TargetYear 2025
```

### Validation before creation
```powershell
.\Create-New-Vault.ps1 -ValidateOnly
```

### Force overwrite existing vault
```powershell
.\Create-New-Vault.ps1 -ForceCreation
```

## Error Handling

The script includes comprehensive error handling:
- Validates source vault exists
- Checks if target vault already exists
- Validates JSON configuration syntax
- Provides clear error messages with timestamps

## Logging

When `log_operations` is enabled, all operations are logged to `vault-template.log` with timestamps and operation types.

## License

This project is open source. Feel free to modify and adapt to your needs.