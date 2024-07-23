# Outputs path location in vdf library file for game ID provided 

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
    [Parameter(Mandatory)][string] $gameID
)

$currentPath = ""

# Going through libraryfolders.vdf
foreach($line in Get-Content "$vdfPath") {
    # Updating path if available
    if ($line -match "`"path`""){ $currentPath = $line.Split("`"")[3]; }

    # Check if the id number we need is in the line
    if($line -match "`"$gameID`""){
        Write-Output "$currentPath"
        exit(0)
    }
}
exit(1)