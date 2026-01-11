<#
.SYNOPSIS
Runs automated tests for P_EAIS and P_MiniFootball.
#>

$UE_Root = "d:\UE\UE_S"
$ProjectRoot = "d:\Projects\UE\A_MiniFootball"
$UProject = "$ProjectRoot\A_MiniFootball.uproject"
$EditorParams = "`"$UProject`" -ExecCmds=`"Automation RunTests P_EAIS; Quit`" -log -unattended -nopause -nullrhi"
$UnrealEditor = "$UE_Root\Engine\Binaries\Win64\UnrealEditor-Cmd.exe"

Write-Host "Running Tests..." -ForegroundColor Cyan

$ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
$ProcessInfo.FileName = $UnrealEditor
$ProcessInfo.Arguments = $EditorParams
$ProcessInfo.RedirectStandardOutput = $true
$ProcessInfo.UseShellExecute = $false
$ProcessInfo.CreateNoWindow = $true

$Process = New-Object System.Diagnostics.Process
$Process.StartInfo = $ProcessInfo
$Process.Start() | Out-Null
$Process.WaitForExit()

if ($Process.ExitCode -eq 0) {
    Write-Host "Tests passed!" -ForegroundColor Green
} else {
    Write-Host "Tests failed or crashed." -ForegroundColor Red
    exit 1
}
