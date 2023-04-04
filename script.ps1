param (
    [string]$domain = $( Read-Host "Domain" ),
    [string]$csvfile = $( Read-Host "Pfad zur CSV-File" ),
    [int]$PasswordLenght = 12
)

Function GenerateStrongPassword ([Parameter(Mandatory=$true)][int]$PasswordLenght)
{
    Add-Type -AssemblyName System.Web
    $PassComplexCheck = $false
    do {
        $newPassword=[System.Web.Security.Membership]::GeneratePassword($PasswordLenght,1)
        If ( ($newPassword -cmatch "[A-Z\p{Lu}\s]") `
        -and ($newPassword -cmatch "[a-z\p{Ll}\s]") `
        -and ($newPassword -match "[\d]") `
        -and ($newPassword -match "[^\w]")
        )
        {
            $PassComplexCheck=$True
        }
    } While ($PassComplexCheck -eq $false)
    return $newPassword
}

# Importiere Powershell Module
Import-Module ActiveDirectory

# Lade CSV-Datei in Array
$ADUsers = Import-Csv $csvfile

# Loope durch Array (CSV)
foreach ($User in $ADUsers) {
    $Benutzername = $User.Benutzername

    if (Get-ADUser -F { SamAccountName -eq $Benutzername }) {
        Write-Warning "Benutzer $Benutzername existiert bereits in der Active Directory Domäne '$domain'."
    }
    else {
        # Definiere alle Werte in eigene Variablen
        $Vorname = $User.Vorname
        $Nachname = $User.Nachname
        $Initialen = $User.Initialen
        if (!$User.Passwort) {
            $Passwort = GenerateStrongPassword -PasswordLenght $PasswordLenght
            Write-Host "Passwort für Benutzer '$Benutzername' wurde automatisch generiert: $Passwort" -ForegroundColor Blue
        }
        else {
            $Passwort = $User.Passwort
        }
        $Email = $User.Email
        $Abteilung = $User.Abteilung
        $OU = $User.OU

        New-ADUser `
        -SamAccountName $Benutzername `
        -Name "$Vorname $Nachname" `
        -GivenName $Vorname `
        -Surname $Nachname `
        -Initials $Initialen `
        -DisplayName "$Vorname $Nachname" `
        -UserPrincipalName "$Benutzername@$domain" `
        -AccountPassword (ConvertTo-SecureString $Passwort -AsPlainText -Force) `
        -Enabled $true `
        -ChangePasswordAtLogon $false `
        -PasswordNeverExpires $true `
        -Path $OU `
        -EmailAddress $Email `
        -Department $Abteilung

        Write-Host "Benutzer $Benutzername wurde erfolgreich in der Active Directory Domäne '$domain' erstellt." -ForegroundColor Green
    }
}

Write-Host "Vorgang abgeschlossen."
