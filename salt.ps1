# run as administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# check if salt-minion service exists unistall salt
$serviceName = "*salt-minion*"

If (Get-Service $serviceName -ErrorAction SilentlyContinue) {

    If ((Get-Service $serviceName).Status -eq 'Running') {

        Stop-Service $serviceName
        Write-Host "Stopping $serviceName"
        # delete salt-minion service
        Remove-Service -Name "TestService"
        Remove-Item -LiteralPath 'c:\tempsalt' -Force -Recurse

    } Else {

        Write-Host "$serviceName found, but it is not running."

    }

} Else {

    Write-Host "$serviceName not found"

}

## delete salt directory if exixts
if (Test-Path 'c:\salt') { Remove-Item -LiteralPath 'c:\salt' -Force -Recurse; }

## service salt status
#Get-Service -Displayname "*salt-minion*"

# create temp directory for downloading salt
new-item c:\tempsalt -itemtype directory

# downlaod salt exe
Invoke-WebRequest -Uri ftp://ftp.behdasht.gov.ir/Softwares/DevOps/Agent/Salt-Minion-3000.1-Py3-AMD64-Setup.exe -OutFile 'C:\tempsalt\Salt-Minion-3000.1-Py3-AMD64-Setup.exe'

# install salt-minion
C:\tempsalt\Salt-Minion-3000.1-Py3-AMD64-Setup.exe /S /master=acm.behdasht.gov.ir /start-minion=0

# delete grains.conf file if exists
#$FileName = "C:\salt\conf\minion.d\grains.conf"
#if (Test-Path $FileName) 
#{
#  Remove-Item $FileName
#}

# export env vars
Set-Variable -Name "G" -Value "grains:"
$org = Read-Host -Prompt 'org'
$ser = Read-Host -Prompt 'services'
$poj = Read-Host -Prompt 'project'

# create grains file
Add-Content C:\salt\conf\minion.d\grains.conf $G
Add-Content C:\salt\conf\minion.d\grains.conf "  org: $org"
Add-Content C:\salt\conf\minion.d\grains.conf "  services: $ser"
Add-Content C:\salt\conf\minion.d\grains.conf "  project: $poj"

# start salt service
start-service "*salt-minion*"

## service salt status
#Get-Service -Displayname "*salt-minion*"

# delete salt exe if service is running
$ServiceName = '*salt-minion*'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{

    Start-Service $ServiceName
    write-host $arrService.status
    write-host 'Service starting'
    Start-Sleep -seconds 5
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host 'Service is now Running'
        Remove-Item -LiteralPath 'c:\tempsalt' -Force -Recurse
    }

}

# enter to close powershell
pause