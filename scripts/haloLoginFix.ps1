# Removes credential & cache data produced by Halo MCC to fix login issues.

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
    [boolean] $removeCredentialReg = $true,
    [boolean] $removeCache = $true,
    [boolean] $restartGameService = $false,
    [boolean] $launchGame = $false
)

if ($removeCredentialReg) { cmdkey /list | ForEach-Object{if(($_ -like "*Target:*") -and (($_ -like "*XblGrts*") -or ($_ -like "*Xbl|DeviceKey*") -or ($_ -like "*Xbl_Ticket|1144039928|Production|*") -or ($_ -like "*Xbl|1144039928||Production|RETAIL|Dtoken|http://auth.xboxlive.com||JWT*"))){ cmdkey /del:($_ -replace " ","" -replace "Target:","") ; }} ; }
if ($removeCache) { Remove-Item "$env:UserProfile\AppData\LocalLow\MCC\Saved\webcache\*" -Force -Recurse ; }
if ($restartGameService) { Restart-Service -Name GamingServices ; }
if ($launchGame) { . "$PSScriptRoot/mcclauncher.exe" ; }