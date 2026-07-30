#Requires -Version 4.0
#Requires -Modules NetTCPIP
<#
.SYNOPSIS
    Checks if a Port is reachable on a specific client.

.DESCRIPTION
    The script checks if a port is accessible on a client. 
    If it is not reachable, the result is written to a log file.

.PARAMETER Target
    Is the ip address to be checked

.PARAMETER Port
    Is the port to be checked

.PARAMETER EnableLogging
    Enables the logging function

.PARAMETER CheckInterval
    How many seconds pass before the system retries the port connection

.PARAMETER LogPath
    The directory where the log file should be stored. Defaults to a "Logs" folder next to the script.

.EXAMPLE
    .\CheckPort.ps1 -Target "192.168.1.10" -Port "80" -EnableLogging -LogPath "C:\Logs\CheckPort"

.NOTES
    Version:    1.1
    Author:     mmnps
#>

######################
###   Parameters   ###
######################
param(
    [Parameter(Mandatory)][ValidateScript({ [System.Net.IPAddress]::TryParse($_, [ref]$null) })][string]$Target,   #Check if ip is valid
    [Parameter(Mandatory)][ValidateRange(1, 65535)][int]$Port,   #Check if port is valid
    [switch]$EnableLogging,
    [int]$CheckInterval = 60,
    [string]$LogPath = "$PSScriptRoot\Logs"
)

#########################
###   Configuration   ###
#########################
$LastUpdated = "30.07.2026"
$Date = Get-Date -Format "yyyy-MM-dd"
$LogFile = Join-Path $LogPath "$Date.log"
$Global:ProgressPreference = "SilentlyContinue"
$Global:WarningPreference = "SilentlyContinue"


#################
###   Infos   ###
#################
Write-Host "# This script checks if a port is reachable on a client for over a longer period of time." -ForegroundColor DarkCyan
if ($EnableLogging) { Write-Host "# Path to Logfile: $LogFile" -ForegroundColor DarkCyan } 
Write-Host "# Last updated: $LastUpdated" -ForegroundColor DarkCyan


####################################
###   Create the log directory   ###
####################################
if ($EnableLogging -and -not (Test-Path (Split-Path $LogFile))) {
    New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
}


#####################
###   Functions   ###
#####################
function Write-Log {
    param(
        [ValidateSet('INFO','ERROR')][string]$Level = 'INFO',
        [Parameter(Mandatory)][string]$Text,
        [Switch]$ToConsole
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Msg = "[$Timestamp] - $Level - $Text"

    if ($EnableLogging) {
        Add-Content -Path $LogFile -Value $Msg
    }

    if ($ToConsole) {
        switch ($Level) {
            'INFO'  { Write-Host $Msg -ForegroundColor Green }
            'ERROR' { Write-Host $Msg -ForegroundColor Red}
        }
    }
}


######################
###   Main logic   ###
######################
$Connection = Test-Connection -ComputerName $Target -count 1 -Quiet -ErrorAction SilentlyContinue

if (-not $Connection) {
    Write-Log -Level ERROR -Text "$Target is offline." -ToConsole
    exit 1
}

$Offline = $False
$PortReachable = 0
$PortNotReachable = 0

try {
    while ($True) {
        $Reachable = Test-NetConnection -ComputerName $Target -Port $Port -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        if (-not $Reachable.TcpTestSucceeded) {
            Write-Log -Level ERROR -Text "Port $Port is not reachable on $Target." -ToConsole
            $Offline = $True
            $PortNotReachable++
        }
        else {
            if ($Offline) {
                Write-Log -Level INFO -Text "Port $Port is reachable again on $Target." -ToConsole
            }
            else {
                Write-Host "Port $Port is reachable on $Target" -ForegroundColor Green  
            }
            $PortReachable++
            $Offline = $False
        }

        Start-Sleep -Seconds $CheckInterval
    }
}

finally {
    Write-Host "`n----------------------------------"
    Write-Host "Summary:"
    Write-Host "Port Reachable: " -NoNewline
    Write-Host $PortReachable -ForegroundColor Green 
    Write-Host "Port not reachable: " -NoNewline
    Write-Host $PortNotReachable -ForegroundColor Red 
}

