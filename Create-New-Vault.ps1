# Create-New-Vault.ps1
# Smart script to create next year's vault based on JSON configuration

param(
    [string]$ConfigPath = ".\config-template.json",
    [int]$TargetYear = 0,  # 0 = auto-detect
    [switch]$ForceCreation,
    [switch]$ValidateOnly
)

# Colors for output
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorInfo = "Cyan"

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Type) {
        "SUCCESS" { $ColorSuccess }
        "WARNING" { $ColorWarning }
        "ERROR" { $ColorError }
        default { $ColorInfo }
    }
    
    Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
    
    if ($config.options.log_operations) {
        "$timestamp [$Type] $Message" | Out-File -FilePath "vault-template.log" -Append
    }
}

function Test-VaultExists {
    param([string]$Path)
    return (Test-Path $Path) -and (Test-Path "$Path\.obsidian")
}

function Get-VaultPath {
    param([string]$BasePath, [string]$Pattern, [int]$Year)
    return Join-Path $BasePath ($Pattern -replace '\{year\}', $Year)
}

# Load configuration
Write-Log "Loading configuration from: $ConfigPath" "INFO"

if (-not (Test-Path $ConfigPath)) {
    Write-Log "Configuration file not found: $ConfigPath" "ERROR"
    Write-Log "Create the config-template.json file with the necessary structure" "ERROR"
    exit 1
}

try {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
} catch {
    Write-Log "Error parsing JSON file: $_" "ERROR"
    exit 1
}

# Detect current and target year
$currentYear = Get-Date -Format "yyyy"
$targetYear = if ($TargetYear -eq 0) { [int]$currentYear + 1 } else { $TargetYear }

Write-Log "Current year detected: $currentYear" "INFO"
Write-Log "Target year: $targetYear" "INFO"

# Build paths
$sourceVault = Get-VaultPath -BasePath $config.base_vault_path -Pattern $config.name_pattern -Year $currentYear
$targetVault = Get-VaultPath -BasePath $config.base_vault_path -Pattern $config.name_pattern -Year $targetYear

Write-Log "Source vault: $sourceVault" "INFO"
Write-Log "Target vault: $targetVault" "INFO"

# Validations
if (-not (Test-VaultExists $sourceVault)) {
    Write-Log "Source vault does not exist or is not valid: $sourceVault" "ERROR"
    exit 1
}

if ((Test-Path $targetVault) -and -not $ForceCreation) {
    Write-Log "Target vault already exists: $targetVault" "WARNING"
    Write-Log "Use the -ForceCreation parameter to overwrite" "WARNING"
    exit 1
}

if ($ValidateOnly) {
    Write-Log "Validation mode - No changes will be made" "INFO"
    Write-Log "Source vault valid: ✓" "SUCCESS"
    Write-Log "Configuration valid: ✓" "SUCCESS"
    exit 0
}

# Create backup if enabled
if ($config.options.backup_before_create -and (Test-Path $targetVault)) {
    $backupPath = "$targetVault-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Log "Creating backup at: $backupPath" "INFO"
    Copy-Item -Path $targetVault -Destination $backupPath -Recurse -Force
}

# Create target directory
Write-Log "Creating target directory..." "INFO"
New-Item -ItemType Directory -Force -Path $targetVault | Out-Null

# 1. Copy complete folders
Write-Log "Copying complete folders..." "INFO"
foreach ($folder in $config.copy_complete) {
    $source = Join-Path $sourceVault $folder
    $destination = Join-Path $targetVault $folder
    
    if (Test-Path $source) {
        Write-Log "  Copying: $folder" "INFO"
        Copy-Item -Path $source -Destination $destination -Recurse -Force
    } else {
        Write-Log "  Not found (skipping): $folder" "WARNING"
    }
}

# 2. Remove excluded files from .obsidian
Write-Log "Removing excluded files..." "INFO"
foreach ($exclude in $config.exclude_from_obsidian) {
    $excludeFile = Join-Path $targetVault $exclude
    if (Test-Path $excludeFile) {
        Write-Log "  Removing: $exclude" "INFO"
        Remove-Item -Path $excludeFile -Recurse -Force
    }
}

# 3. Copy specific files
Write-Log "Copying specific files..." "INFO"
foreach ($file in $config.copy_files) {
    $source = Join-Path $sourceVault $file
    $destination = Join-Path $targetVault $file
    
    if (Test-Path $source) {
        Write-Log "  Copying: $file" "INFO"
        $destinationDir = Split-Path $destination -Parent
        if (-not (Test-Path $destinationDir)) {
            New-Item -ItemType Directory -Force -Path $destinationDir | Out-Null
        }
        Copy-Item -Path $source -Destination $destination -Force
    }
}

# 4. Create empty folder structure
Write-Log "Creating folder structure..." "INFO"
foreach ($folder in $config.create_empty_folders) {
    $folderPath = Join-Path $targetVault $folder
    if (-not (Test-Path $folderPath)) {
        Write-Log "  Creating: $folder" "INFO"
        New-Item -ItemType Directory -Force -Path $folderPath | Out-Null
    }
}

# 5. Create base files with templates
Write-Log "Creating base files..." "INFO"
foreach ($file in $config.create_base_files.PSObject.Properties) {
    # Replace variables in filename
    $fileName = $file.Name
    $fileName = $fileName -replace '\{year\}', $targetYear
    $fileName = $fileName -replace '\{date\}', (Get-Date -Format "yyyy-MM-dd")
    
    $filePath = Join-Path $targetVault $fileName
    $content = $file.Value
    
    # Replace variables in content
    $content = $content -replace '\{year\}', $targetYear
    $content = $content -replace '\{date\}', (Get-Date -Format "yyyy-MM-dd")
    
    # Create directory if it doesn't exist
    $fileDir = Split-Path $filePath -Parent
    if (-not (Test-Path $fileDir)) {
        New-Item -ItemType Directory -Force -Path $fileDir | Out-Null
    }
    
    Write-Log "  Creating: $fileName" "INFO"
    $content | Out-File -FilePath $filePath -Encoding UTF8 -Force
}

# 6. Initialize Git if enabled
if ($config.options.create_git_repo) {
    Write-Log "Initializing Git repository..." "INFO"
    Push-Location $targetVault
    git init
    git add .
    git commit -m "Initial vault for $targetYear"
    Pop-Location
}

# Summary
Write-Log "=====================================" "SUCCESS"
Write-Log "Vault created successfully!" "SUCCESS"
Write-Log "=====================================" "SUCCESS"
Write-Log "Location: $targetVault" "INFO"
Write-Log "Year: $targetYear" "INFO"

# Open new vault if enabled
if ($config.options.open_new_vault) {
    Write-Log "Opening vault in Obsidian..." "INFO"
    
    try {
        # Method 1: Try Obsidian URI protocol
        $vaultURI = "obsidian://open?path=" + [System.Uri]::EscapeDataString($targetVault)
        Write-Log "Attempting to open with URI: $vaultURI" "INFO"
        Start-Process $vaultURI -ErrorAction Stop
        
        Write-Log "Vault opened successfully via URI protocol" "SUCCESS"
    } catch {
        Write-Log "URI protocol failed, trying alternative method..." "WARNING"
        
        try {
            # Method 2: Try to start Obsidian directly with path
            $obsidianPath = Get-Command "obsidian" -ErrorAction SilentlyContinue
            if ($obsidianPath) {
                Start-Process "obsidian" -ArgumentList "`"$targetVault`"" -ErrorAction Stop
                Write-Log "Vault opened successfully via direct command" "SUCCESS"
            } else {
                # Method 3: Try common Obsidian installation paths
                $commonPaths = @(
                    "$env:LOCALAPPDATA\Obsidian\Obsidian.exe",
                    "$env:PROGRAMFILES\Obsidian\Obsidian.exe",
                    "${env:PROGRAMFILES(X86)}\Obsidian\Obsidian.exe"
                )
                
                $obsidianFound = $false
                foreach ($path in $commonPaths) {
                    if (Test-Path $path) {
                        Start-Process $path -ArgumentList "`"$targetVault`"" -ErrorAction Stop
                        Write-Log "Vault opened successfully via: $path" "SUCCESS"
                        $obsidianFound = $true
                        break
                    }
                }
                
                if (-not $obsidianFound) {
                    Write-Log "Could not find Obsidian installation. Please open manually:" "WARNING"
                    Write-Log "Path: $targetVault" "INFO"
                }
            }
        } catch {
            Write-Log "Failed to auto-open vault. Please open manually:" "WARNING"
            Write-Log "Path: $targetVault" "INFO"
            Write-Log "Error: $($_.Exception.Message)" "ERROR"
        }
    }
}

Write-Log "Process completed." "SUCCESS"
