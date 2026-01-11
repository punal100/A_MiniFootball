<#
.SYNOPSIS
Builds the A_MiniFootball project (including all plugins) using UnrealBuildTool.
#>

$UE_Root = "d:\UE\UE_S"
$ProjectRoot = "d:\Projects\UE\A_MiniFootball"
$UProject = "$ProjectRoot\A_MiniFootball.uproject"
$UBT = "$UE_Root\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"

Write-Host "Building A_MiniFootball Editor..." -ForegroundColor Cyan

$BuildCmd = "& `"$UBT`" A_MiniFootballEditor Win64 Development -Project=`"$UProject`" -WaitMutex -FromMsBuild"
Invoke-Expression $BuildCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build Successful!" -ForegroundColor Green
}
else {
    Write-Error "Build Failed!"
    exit 1
}
