
<#
.SYNOPSIS
  Configured AVD Host

.DESCRIPTION
 Configured a new AVD host for use with image builder.  Cleans image, installs chocolatey and enables App-V


.INPUTS
None

.OUTPUTS
Verbose output

.NOTES
  Version:        1.0
#>

##############################
#    AVD Script Parameters   #
##############################
Param (        
    [Parameter(Mandatory=$false)]
        [string]$Optimize = $true           
)

$ChocoPackages = @(
    '7zip.install',
    'audacity',
    'another-redis-desktop-manager',
    'azcopy10',
    'azureaccount-vscode',
    'azure-cli',
    'azure-kubelogin',
    'bluedis',
    'bginfo',
    'cosmosdbexplorer',
    'curl',
    'dbeaver',
    'git',
    'heidisql',
    'jq',
    'k6',
    'kubernetes-cli',
    'kui',
    'microsoftazurestorageexplorer',
    'microsoft-windows-terminal',
    'mongoclient',
    'notepadplusplus',
    'nvm',
    'octant',
    'openlens',
    'putty',
    'python3',
    'RDM.dev',
    'robo3t',
    'sourcetree',
    'sql-server-management-studio',
    'terminal-icons.powershell',
    'vim',
    'vscode',
    'vscode-ember-frost',
    'vscode-powershell',
    'vscode-python',
    'wget',
    'winscp',
    'winsshterm'
)

New-Item -Path c:\log -ItemType Directory
New-Item -Path c:\log\ -Name New-AVDSessionHost.log -ItemType File
######################
#    AVD Variables   #
######################
$LocalAVDpath            = "c:\temp\AVD\"


####################################
#    Test/Create Temp Directory    #
####################################
if((Test-Path c:\temp) -eq $false) {
    Add-Content -LiteralPath C:\log\New-AVDSessionHost.log "Create C:\temp Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating temp directory"
    New-Item -Path c:\temp -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\log\New-AVDSessionHost.log "C:\temp Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "temp directory already exists"
}
if((Test-Path $LocalAVDpath) -eq $false) {
    Add-Content -LiteralPath C:\log\New-AVDSessionHost.log "Create C:\temp\AVD Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating c:\temp\AVD directory"
    New-Item -Path $LocalAVDpath -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\log\New-AVDSessionHost.log "C:\temp\AVD Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "c:\temp\AVD directory already exists"
}

Add-Content `
-LiteralPath C:\log\New-AVDSessionHost.log `
"
Optimize          = $Optimize
"



##############################
#    Prep for AVD Install    #
##############################

#Disable Security Warnings on MSI
$env:SEE_MASK_NOZONECHECKS = 1

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
set-location $LocalAVDpath 


##############################
#    OS Specific Settings    #
##############################
$OS = (Get-WmiObject win32_operatingsystem).name
If(($OS) -match 'server') {
    Add-Content -LiteralPath C:\log\New-AVDSessionHost.log "Windows Server OS Detected"
    write-host -ForegroundColor Cyan -BackgroundColor Black "Windows Server OS Detected"
    If(((Get-WindowsFeature -Name RDS-RD-Server).installstate) -eq 'Installed') {
        "Session Host Role is already installed"
    }
    Else {
        "Installing Session Host Role"
        Install-WindowsFeature `
            -Name RDS-RD-Server `
            -Verbose `
            -LogPath "$LocalAVDpath\RdsServerRoleInstall.txt"
    }
    $AdminsKey = "SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UsersKey = "SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    $BaseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey("LocalMachine","Default")
    $SubKey = $BaseKey.OpenSubkey($AdminsKey,$true)
    $SubKey.SetValue("IsInstalled",0,[Microsoft.Win32.RegistryValueKind]::DWORD)
    $SubKey = $BaseKey.OpenSubKey($UsersKey,$true)
    $SubKey.SetValue("IsInstalled",0,[Microsoft.Win32.RegistryValueKind]::DWORD)    
}
Else {
    Add-Content -LiteralPath C:\log\New-AVDSessionHost.log "Windows Client OS Detected"
    write-host -ForegroundColor Cyan -BackgroundColor Black "Windows Client OS Detected"
    if(($OS) -match 'Windows 11') {
        write-host `
            -ForegroundColor Yellow `
            -BackgroundColor Black  `
            "Windows 11 detected...skipping to next step"
        Add-Content -LiteralPath C:\log\New-AVDSessionHost.log "Windows 11 Detected...skipping to next step"     
    }    
    else {
        ##NOT DOING WIN7!!!
        }        
    }





#########################
#    Enable App-V       #
#########################
Enable-appv
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\AppV\Client\Scripting' -Name 'EnablePackageScripts' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'NtfsDisable8dot3NameCreation' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;

###############################
#   Enable Script Execution   #
###############################
Set-ExecutionPolicy Unrestricted


###########################
##     Install Choco     ##
###########################

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

##########################
##  Install Choco Pkgs  ##
##########################
$ChocoExePath = "$Env:ProgramData/chocolatey/choco.exe" 
$ChocoExpression = "$ChocoExePath install -y -f --acceptlicense --no-progress --stoponfirstfailure --ignore-checksums"

# Loop through $ChocoPackages and install each package
foreach ($package in $ChocoPackages) {
    Add-Content -LiteralPath C:\log\New-AVDSessionHost.log "Installing $package"
    write-host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "Installing $package"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        $packageScriptPath = [System.IO.Path]::GetTempFileName() + ".ps1"
        $expression = "$ChocoExpression $package"
        Set-Content -Value $expression -Path $packageScriptPath
        Write-Host "File path $packageScriptPath"

        Execute -File $packageScriptPath
        Remove-Item $packageScriptPath

}


##########################
##    Install Winget    ##
##########################

$wingetURL = 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle'
$wingetInstaller = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"
$LocalOptimizePath = "C:\temp\AVD\"
Invoke-WebRequest `
    -Uri $wingetURL `
    -OutFile "$wingetInstaller"
    Add-AppxPackage $LocalOptimizePath$wingetInstaller


##########################
#    Mark Complete       #
##########################
remove-item env:SEE_MASK_NOZONECHECKS
Add-Content -LiteralPath C:\log\New-AVDSessionHost.log "Process Complete - REBOOT"
