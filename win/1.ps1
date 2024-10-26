# Win11 dotfiles symlink script

# Define sources, targets, and file names in an array
$configs = @(

    # GlazeWM tilling window manager config
    @{
        SourcePath = "\\wsl$\Ubuntu\home\fdong\dotfiles\glazewm\.glzr\glazewm\config.yaml"
        TargetDir  = "$HOME\.glzr\glazewm"
        FileName   = "config.yaml"
    },

    # # WezTerm terminal Win11 config
    # @{
    #     SourcePath = "$HOME\dotfiles\wezterm_win\.config\wezterm\wezterm.lua"
    #     TargetDir  = "$HOME\.config\wezterm"
    #     FileName   = "wezterm.lua"
    # },
    #
    # # PowerShell Core profile
    # @{
    #     SourcePath = "$HOME\dotfiles\powershell_core\Microsoft.PowerShell_profile.ps1"
    #     TargetDir  = "$HOME\Documents\PowerShell"
    #     FileName   = "Microsoft.PowerShell_profile.ps1"
    # },
    #
    # # PowerShell oh-my-posh custom theme
    # @{
    #     SourcePath = "$HOME\dotfiles\oh-my-posh\powershell\onehalf.minimal.omp.json"
    #     TargetDir  = "$HOME\AppData\Local\Programs\oh-my-posh\themes"
    #     FileName   = "onehalf.minimal.omp.json"
    # }
)

# Function to print status messages
function Print-Info {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] [$Type] $Message"
}

# Loop through each configuration and process it
foreach ($config in $configs) {
    $sourcePath = $config.SourcePath
    $targetDir  = $config.TargetDir
    $targetPath = Join-Path $targetDir $config.FileName

    Print-Info "Processing symbolic link for: $($config.FileName)"
    Print-Info "Source Path: $sourcePath"
    Print-Info "Target Path: $targetPath"

    # Check if the source file exists
    if (-not (Test-Path $sourcePath)) {
        Print-Info "Source file does not exist: $sourcePath" "ERROR"
        continue  # Skip to the next configuration if the source file is missing
    } else {
        Print-Info "Source file exists: $sourcePath"
    }

    # Check if the target directory exists; if not, create it
    if (-not (Test-Path $targetDir)) {
        Print-Info "Target directory does not exist. Creating: $targetDir"
        try {
            New-Item -ItemType Directory -Path $targetDir | Out-Null
            Print-Info "Directory created: $targetDir"
        }
        catch {
            Print-Info "Failed to create directory: $targetDir. Error: $_" "ERROR"
            continue  # Skip to the next configuration if directory creation fails
        }
    } else {
        Print-Info "Target directory exists: $targetDir"
    }

    # Check if the target file or link already exists
    if (Test-Path $targetPath) {
        Print-Info "Target file or link exists. Deleting: $targetPath"
        try {
            Remove-Item -Path $targetPath -Force
            Print-Info "Deleted existing target: $targetPath"
        }
        catch {
            Print-Info "Failed to delete target: $targetPath. Error: $_" "ERROR"
            continue  # Skip to the next configuration if deletion fails
        }
    } else {
        Print-Info "No existing target found at: $targetPath"
    }

    # Create the symbolic link using PowerShell
    Print-Info "Creating symbolic link: $targetPath -> $sourcePath"
    try {
        New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath | Out-Null
        Print-Info "Symbolic link created successfully: $targetPath -> $sourcePath"
    }
    catch {
        Print-Info "Failed to create symbolic link: $targetPath -> $sourcePath. Error: $_" "ERROR"
    }

    Print-Info "------------------------------------"
}

