
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
    'microsoft-windows-terminal -pre',
    'microsoftazurestorageexplorer',
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

function Execute
{
    [CmdletBinding()]
    param(
        $File
    )

    # Note we're calling powershell.exe directly, instead
    # of running Invoke-Expression, as suggested by
    # https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/avoid-using-invoke-expression?view=powershell-7.3
    # Note that this will run powershell.exe
    # even if the system has pwsh.exe.
    powershell.exe -File $File

    # capture the exit code from the process
    $processExitCode = $LASTEXITCODE

    # This check allows us to capture cases where the command we execute exits with an error code.
    # In that case, we do want to throw an exception with whatever is in stderr. Normally, when
    # Invoke-Expression throws, the error will come the normal way (i.e. $Error) and pass via the
    # catch below.
    if ($processExitCode -or $expError)
    {
        if ($processExitCode -eq 3010)
        {
            # Expected condition. The recent changes indicate a reboot is necessary. Please reboot at your earliest convenience.
        }
        elseif ($expError)
        {
            throw $expError
        }
        else
        {
            throw "Installation failed with exit code: $processExitCode. Please see the Chocolatey logs in %ALLUSERSPROFILE%\chocolatey\logs folder for details."
            break
        }
    }
}

##############################
#    Prep for AVD Install    #
##############################

#Disable Security Warnings on MSI
$env:SEE_MASK_NOZONECHECKS = 1

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
set-location $LocalAVDpath 

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
#    Mark Complete       #
##########################
remove-item env:SEE_MASK_NOZONECHECKS
Add-Content -LiteralPath C:\log\New-AVDSessionHost.log "Process Complete - REBOOT"
