# Goes through VDF file and copies each line to a new file until the game needed
# to modify is found, then it makes the modifications it needs accordingly
# (only modifies values in the Software->Valve->Steam->apps section).

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
    [Parameter(Mandatory)][string] $vdfPath,
    [Parameter(Mandatory)][string] $gameID,
    [Parameter(Mandatory)][string] $key,
    [string] $value = "",
    [boolean] $remove = $false,
    [string] $file = "" # Keep empty for direct output
)

$valvePattern = "`"Valve`"\s*{" # Pattern to put us in Valve section
$gamePattern = "`"$gameID`"\s*{"# Pattern to put us in game section
$keyPattern = "`"$key`"\s*`""   # Identifies key we'll change
$endPattern = "\s*}"    # Pattern needed to signal end of modification
$tabCount = 0           # Keeps track of sections
$valveTabCount = 0      # Use this to only modify within Valve section
$gameTabCount = 9999    # Use this to trigger when finished
$finished = 0           # When 1 then the program will copy the rest of the VDF file like normal
$lastLine = ""          # Reading 2 lines at a time for pattern recognition
[regex]$tabRegex ="\G\s"# Regex to count tabs with

# Function for output
function vdfOut {
    if([string]::IsNullOrEmpty($file)){ $output = $args[0]; Write-Output "$output"; }
    else{ Add-Content -Path "$file" -NoNewline -Value $args[0]; }
}

# If file exists delete it so we're not just adding to it
if (Test-Path $file) { Remove-Item $file; }

# Going through VDF file 
foreach($line in Get-Content "$vdfPath") {
    if ($finished -eq 1){ vdfOut $line"`n"; continue; }
    
    # Setting up line/count to check what we need
    $twoLines = "$lastLine`n$line"
    $outLine = "$line"
    $tabCount = $tabRegex.matches($line).count

    # Check if we're out of the Valve section and finished
    if($tabCount -lt $valveTabCount){ $finished = 1; }

    # Check if we're in the Valve section
    if($twoLines -match $valvePattern){ $valveTabCount = $tabRegex.matches($line).count; }

    # Check if we're in the game section we need
    if($twoLines -match $gamePattern){ $gameTabCount = $tabRegex.matches($line).count; }

    # If we're in the game section and see our key then lets change it
    if (($tabCount -gt $gameTabCount) -and ($line -match $keyPattern)){
        $outLine = "`t"*$tabCount + "`"$key`"`t`t" + "$value"
        $finished = 1
        if($remove){ continue; }
    }

    # If we're at the end of the game section then we'll add the line we need to the new file
    if (($tabCount -eq $gameTabCount) -and ($line -match $endPattern)){
        $tabbedKeyValue = "`t"*($gameTabCount+1) + "`"$key`"`t`t" + "$value"
        if (!$remove) { vdfOut $tabbedKeyValue"`n" ; } 
        $finished = 1
    }

    # Copy line
    vdfOut $outLine"`n"

    $lastLine = $line
}