# Applies Steam launch options to run haloLoginFix.ps1 everytime Halo MCC starts.

# Copyright (C) 2024 Thomas Rader

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

param(
    [string] $steamPath = "C:/Program Files (x86)/Steam",
    [string] $gameID = "976730",
    [string] $key = "",
    [string] $value = "",
    [boolean] $remove = $false,     # Removes they key from the VDF file
    [boolean] $continue = $false    # Asks user before closing Steam if false
)
if ( !(Test-Path $steamPath -PathType Container) ){ $steamPath = Read-Host 'Please enter steam install path'; }

# Function for errors
function vdfErr{ Write-Error $args[0]; $args[0] | Out-File -FilePath "$PSScriptRoot/error.txt"; exit(1); }

# Checking if Steam is running
$steamRunning = $false
$steam = Get-Process steam -ErrorAction SilentlyContinue
if ($steam) {
    if ( !($continue) ) { $empty = Read-Host "Steam is running, press enter to continue and reset Steam..."; }
    $steamRunning = $true
    $steam | Stop-Process -Force
    Start-Sleep -Seconds 1
} ; Remove-Variable steam

# Setting paths
$steamPath = $steamPath.TrimEnd('/')
$localConfigFolder = $steamPath + "/userdata"
if ( !(Test-Path $steamPath -PathType Container) ){ vdfErr "Can't find proper steam path, need install path with config files"; }
if ( !(Test-Path $localConfigFolder -PathType Container) -or (Get-ChildItem $localConfigFolder | Measure-Object).Count -eq 0){ 
    vdfErr "Can't find user data $localConfigFolder"
}

# Default Halo install
if( [string]::IsNullOrEmpty($key) ){
    # Getting game install path
    $libraryConfig = $steamPath + "/config/libraryfolders.vdf"
    if( !(Test-Path $libraryConfig -PathType Leaf) ){ vdfErr "Can't find library folder $libraryConfig"; }
    $gamePath = powershell "$PSScriptRoot/findGamePathVDF.ps1 '$libraryConfig' '$gameID'"
    if ( [string]::IsNullOrEmpty($gamePath) ) { vdfErr "Can't find game in $libraryConfig with $gameID"; }

    # Copying haloLoginFix.ps1 to the game's path (changing it to auto start)
    $autoLoginFile = (Get-Content "$PSScriptRoot/haloLoginFix.ps1" -Raw).Replace('[boolean] $launchGame = $false','[boolean] $launchGame = $true')
    "$autoLoginFile" | Out-File -FilePath "$gamePath/steamapps/common/Halo The Master Chief Collection/autoLoginFix.ps1" -Force

    # Setting default key value
    $key = "LaunchOptions"
    $value = "`"\`"$gamePath\\steamapps\\common\\Halo The Master Chief Collection\\autoLoginFix.ps1\`" %command%`""
}

# Going through all users in Steam/userdata
$userFolders = Get-ChildItem "$localConfigFolder"
foreach( $userFolder in $userFolders ){
    # Getting username to possibly save multiple backup config files
    $user = ($userFolder -split '\\', -2)[-1]
    $time = [int](Get-Date -UFormat %s -Millisecond 0)

    # Getting config file (running as admin causes userFolder to lose absolute path, so we do this)
    $userConfigFile = "$localConfigFolder/$user/config/localconfig.vdf"
    if ( !(Test-Path "$userConfigFile" -PathType Leaf) ) { Write-Error "Can't find user config file $userConfigFile"; "Can't find user config file $userConfigFile" | Out-File -FilePath "$PSScriptRoot/error.txt"; continue; }

    # Copying config file to two locations for safety
    Copy-Item "$userConfigFile" -Destination "$userConfigFile.$time.bak"
    Copy-Item "$userConfigFile" -Destination "$PSScriptRoot/localconfig-$user.vdf.$time.bak"
    
    # Modifying config file
    . "$PSScriptRoot/modifyLocalConfigVDF.ps1" "$userConfigFile" "$gameID" "$key" "$value" -file "$PSScriptRoot/localconfig-modified.vdf" -remove $remove

    # Replace steam config file
    Move-Item -Path "$PSScriptRoot/localconfig-modified.vdf" -Destination "$userConfigFile" -Force
}

# Restarting Steam if it was running
if ( $steamRunning ){ Start-Process -FilePath "$steamPath/steam.exe"; }