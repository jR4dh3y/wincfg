# ═══════════════════════════════════════════════════════════════════════════════
# OPTIMIZED POWERSHELL PROFILE
# Key optimizations: Deferred loading, cached oh-my-posh, consolidated options
# ═══════════════════════════════════════════════════════════════════════════════

# Telemetry opt-out (system level, runs once)
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# ═══════════════════════════════════════════════════════════════════════════════
# ADMIN CHECK & WINDOW TITLE (cached, runs once)
# ═══════════════════════════════════════════════════════════════════════════════
$script:isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$Host.UI.RawUI.WindowTitle = "PowerShell {0}{1}" -f $PSVersionTable.PSVersion.ToString(), $(if ($script:isAdmin) { " [ADMIN]" } else { "" })

function prompt {
    if ($script:isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}

# ═══════════════════════════════════════════════════════════════════════════════
# OH-MY-POSH (CACHED INITIALIZATION - Major speedup!)
# ═══════════════════════════════════════════════════════════════════════════════
$ompCache = "$env:LOCALAPPDATA\oh-my-posh-init.ps1"
$ompConfig = "$env:USERPROFILE\Documents\PowerShell\Scripts\theme.json"
if (!(Test-Path $ompCache) -or ((Test-Path $ompConfig) -and (Get-Item $ompCache).LastWriteTime -lt (Get-Item $ompConfig).LastWriteTime)) {
    oh-my-posh init pwsh --config $ompConfig | Out-File $ompCache -Encoding utf8
}
. $ompCache

# ═══════════════════════════════════════════════════════════════════════════════
# PSREADLINE (Single consolidated call - no redundant Set-PSReadLineOption)
# ═══════════════════════════════════════════════════════════════════════════════
$PSReadLineOptions = @{
    EditMode                      = 'Windows'
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
    PredictionSource              = 'HistoryAndPlugin'
    PredictionViewStyle           = 'ListView'
    BellStyle                     = 'None'
    MaximumHistoryCount           = 10000
    Colors                        = @{
        Command   = '#87CEEB'
        Parameter = '#98FB98'
        Operator  = '#FFB6C1'
        Variable  = '#DDA0DD'
        String    = '#FFDAB9'
        Number    = '#B0E0E6'
        Type      = '#F0E68C'
        Comment   = '#D3D3D3'
        Keyword   = '#8367c7'
        Error     = '#FF6347'
    }
}
Set-PSReadLineOption @PSReadLineOptions

# Key handlers (consolidated)
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

# History filter (simplified regex)
Set-PSReadLineOption -AddToHistoryHandler {
    param($line)
    return ($line -notmatch 'password|secret|token|apikey|connectionstring')
}

# ═══════════════════════════════════════════════════════════════════════════════
# DEFERRED MODULE LOADING (Loads AFTER prompt appears)
# ═══════════════════════════════════════════════════════════════════════════════
$null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue
    $chocoProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path $chocoProfile) { Import-Module $chocoProfile }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ALIASES (Fast - no command lookups)
# ═══════════════════════════════════════════════════════════════════════════════
$EDITOR = 'code'
Set-Alias -Name vim -Value $EDITOR
Set-Alias -Name su -Value admin
Set-Alias -Name ep -Value Edit-Profile
Set-Alias -Name z -Value __zoxide_z -Option AllScope -Scope Global -Force
Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force

# ═══════════════════════════════════════════════════════════════════════════════
# CORE FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════
function Edit-Profile { code $PROFILE }
function touch($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) { Get-ChildItem -Recurse -Filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName } }
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip -TimeoutSec 5).Content }
function winutil { irm https://christitus.com/win | iex }
function winutildev { irm https://christitus.com/windev | iex }

function admin {
    if ($args.Count -gt 0) {
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $($args -join ' ')"
    } else {
        Start-Process wt -Verb runAs
    }
}

function uptime {
    $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $up = (Get-Date) - $boot
    Write-Host "System started: $($boot.ToString('f'))" -ForegroundColor DarkGray
    Write-Host ("Uptime: {0}d {1}h {2}m {3}s" -f $up.Days, $up.Hours, $up.Minutes, $up.Seconds) -ForegroundColor Blue
}

function reload-profile { & $PROFILE; Write-Host "Profile reloaded." }

function unzip($file) {
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}

function grep($regex, $dir) {
    if ($dir) { Get-ChildItem $dir | Select-String $regex }
    else { $input | Select-String $regex }
}

function df { Get-Volume }
function sed($file, $find, $replace) { (Get-Content $file).Replace($find, $replace) | Set-Content $file }
function which($name) { Get-Command $name | Select-Object -ExpandProperty Definition }
function export($name, $value) { Set-Item -Force -Path "env:$name" -Value $value }
function pkill($name) { Get-Process $name -ErrorAction SilentlyContinue | Stop-Process }
function pgrep($name) { Get-Process $name }
function head { param($Path, $n = 10) Get-Content $Path -Head $n }
function tail { param($Path, $n = 10, [switch]$f) Get-Content $Path -Tail $n -Wait:$f }
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

function trash($path) {
    $fullPath = (Resolve-Path -Path $path).Path
    if (Test-Path $fullPath) {
        $item = Get-Item $fullPath
        $parentPath = if ($item.PSIsContainer) { $item.Parent.FullName } else { $item.DirectoryName }
        $shell = New-Object -ComObject 'Shell.Application'
        $shell.NameSpace($parentPath).ParseName($item.Name).InvokeVerb('delete')
        Write-Host "Moved to Recycle Bin: $fullPath"
    } else {
        Write-Host "Error: '$fullPath' not found."
    }
}

function Clear-Cache {
    Write-Host "Clearing cache..." -ForegroundColor Cyan
    @("$env:SystemRoot\Prefetch\*", "$env:SystemRoot\Temp\*", "$env:TEMP\*", "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*") | ForEach-Object {
        Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Cache cleared." -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════════════════════════
# NAVIGATION
# ═══════════════════════════════════════════════════════════════════════════════
function docs { Set-Location ([Environment]::GetFolderPath("MyDocuments")) }
function prog { Set-Location "C:\Users\radhe\OneDrive\Documents\1234" }
function dtop { Set-Location ([Environment]::GetFolderPath("Desktop")) }

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESS & FILE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════
function k9 { Stop-Process -Name $args[0] }
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }

# ═══════════════════════════════════════════════════════════════════════════════
# GIT SHORTCUTS
# ═══════════════════════════════════════════════════════════════════════════════
function gs { git status }
function ga { git add . }
function gc { param($m) git commit -m "$m" }
function gp { git push }
function g { __zoxide_z github }
function gcl { git clone $args }
function gcom { git add .; git commit -m "$args" }
function lazyg { git add .; git commit -m "$args"; git push }

# ═══════════════════════════════════════════════════════════════════════════════
# SYSTEM UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════
function sysinfo { Get-ComputerInfo }
function flushdns { Clear-DnsClientCache; Write-Host "DNS flushed" }
function cpy { Set-Clipboard $args[0] }
function pst { Get-Clipboard }

# ═══════════════════════════════════════════════════════════════════════════════
# ARGUMENT COMPLETERS (Lazy - only execute on tab completion)
# ═══════════════════════════════════════════════════════════════════════════════
Register-ArgumentCompleter -Native -CommandName git, npm, deno -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $completions = @{
        'git'  = @('status', 'add', 'commit', 'push', 'pull', 'clone', 'checkout', 'branch', 'merge', 'rebase', 'stash', 'log', 'diff')
        'npm'  = @('install', 'start', 'run', 'test', 'build', 'init', 'update')
        'deno' = @('run', 'compile', 'bundle', 'test', 'lint', 'fmt', 'cache', 'info', 'doc', 'upgrade')
    }
    $cmd = $commandAst.CommandElements[0].Value
    if ($completions.ContainsKey($cmd)) {
        $completions[$cmd] | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}

Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    dotnet complete --position $cursorPosition $commandAst.ToString() 2>$null | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════════════════════
function Show-Help {
    Write-Host @"
PowerShell Profile Help
=======================
Edit-Profile (ep)  - Edit profile      | reload-profile - Reload profile
touch <file>       - Create file       | ff <name>      - Find files
Get-PubIP          - Public IP         | uptime         - System uptime
winutil/winutildev - WinUtil           | unzip <file>   - Extract zip
grep <regex> [dir] - Search text       | df             - Disk volumes
sed <f> <s> <r>    - Replace in file   | which <cmd>    - Command path
pkill/pgrep <name> - Process mgmt      | head/tail      - View file parts
nf <name>          - New file          | mkcd <dir>     - Create & cd
trash <path>       - Recycle bin       | Clear-Cache    - Clear temp files
docs/dtop/prog     - Navigation        | la/ll          - List files
gs/ga/gc/gp        - Git shortcuts     | gcom/lazyg     - Git add+commit+push
sysinfo            - System info       | flushdns       - Clear DNS
cpy/pst            - Clipboard         | su             - Run as admin
"@
}
