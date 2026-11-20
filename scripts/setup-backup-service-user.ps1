<#
.SYNOPSIS
    Configura la cuenta de servicio local para Uranium Backup en Windows 10/11.
.DESCRIPTION
    Crea el usuario local 'UraniumBackup', lo incorpora al grupo local de Administradores
    (compatible con sistemas en español e ingles) y desactiva la caducidad de contrasena.
.NOTES
    Autor: Enrique Ramirez (@enrique-ramirez-it)
    Repositorio: backup-automation-uranium
    Requisitos: Ejecutar como Administrador en PowerShell.
#>

#Requires -RunAsAdministrator

$Username = "UraniumBackup"
$Description = "Cuenta de servicio dedicada para copias de seguridad automatizadas (Uranium Backup)"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  CONFIGURACION DE CUENTA DE SERVICIO - URANIUM BACKUP" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Solicitar contrasena de forma segura
$Password = Read-Host -Prompt "Introduce una contrasena segura para el usuario '$Username'" -AsSecureString

# Verificar si el usuario ya existe
$ExistingUser = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue

if ($null -eq $ExistingUser) {
    Write-Host "[1/3] Creando usuario local '$Username'..." -ForegroundColor Yellow
    New-LocalUser -Name $Username -Password $Password -FullName $Username -Description $Description -PasswordNeverExpires:$true -AccountNeverExpires | Out-Null
    Write-Host "      Usuario creado correctamente." -ForegroundColor Green
} else {
    Write-Host "[1/3] El usuario '$Username' ya existe. Actualizando contrasena y politica..." -ForegroundColor Yellow
    Set-LocalUser -Name $Username -Password $Password -PasswordNeverExpires:$true -AccountNeverExpires
    Write-Host "      Usuario actualizado correctamente." -ForegroundColor Green
}

# Detectar nombre del grupo Administradores por SID bien conocido (S-1-5-32-544)
$AdminGroup = Get-LocalGroup | Where-Object { $_.SID.Value -eq "S-1-5-32-544" }

Write-Host "[2/3] Verificando pertenencia al grupo '$($AdminGroup.Name)'..." -ForegroundColor Yellow
$IsMember = Get-LocalGroupMember -Group $AdminGroup.Name -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*\$Username" }

if ($null -eq $IsMember) {
    Add-LocalGroupMember -Group $AdminGroup.Name -Member $Username
    Write-Host "      Usuario anadido al grupo '$($AdminGroup.Name)'." -ForegroundColor Green
} else {
    Write-Host "      El usuario ya pertenece al grupo '$($AdminGroup.Name)'." -ForegroundColor Green
}

# Comprobacion final
Write-Host "[3/3] Resumen de estado de la cuenta:" -ForegroundColor Yellow
Get-LocalUser -Name $Username | Select-Object Name, Enabled, PasswordExpires, LastLogon | Format-Table -AutoSize

Write-Host "Siguiente paso: Abre services.msc -> 'Uranium Backup Service' -> Iniciar sesion -> .\$Username" -ForegroundColor Cyan
