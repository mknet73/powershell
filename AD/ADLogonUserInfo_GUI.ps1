Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-ADUserLogonInfo {
    $users = Get-ADUser -Filter * -Properties SamAccountName, LastLogon, LastLogonTimestamp, PasswordLastSet, PasswordNeverExpires, PasswordExpired, WhenCreated
    $results = @()

    foreach ($user in $users) {
        # LastLogonTimestamp can be null, convert to DateTime if exists
        $lastLogonDate = if ($user.LastLogonTimestamp) {
            [DateTime]::FromFileTime($user.LastLogonTimestamp)
        } else {
            $null
        }

        $firstLogonDate = if ($user.LastLogon) {
            [DateTime]::FromFileTime($user.LastLogon)
        } else {
            $null
        }

        $passwordLastSet = if ($user.PasswordLastSet) {
            $user.PasswordLastSet
        } else {
            $null
        }

        # Get password policy
        $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        $maxPwdAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
        $passwordExpiryDate = if ($passwordLastSet -and $maxPwdAge) {
            $passwordLastSet + $maxPwdAge
        } else {
            $null
        }
        $daysToPasswordExpiry = if ($passwordExpiryDate) {
            [int](($passwordExpiryDate - (Get-Date)).TotalDays)
        } else {
            $null
        }

        $daysSinceLastLogon = if ($lastLogonDate) {
            [int]( (Get-Date) - $lastLogonDate ).TotalDays
        } else {
            $null
        }

        $results += [PSCustomObject]@{
            'SamAccountName' = $user.SamAccountName
            'FirstLogon'     = if ($firstLogonDate) { $firstLogonDate } else { 'Brak danych' }
            'LastLogon'      = if ($lastLogonDate) { $lastLogonDate } else { 'Brak danych' }
            'DaysSinceLastLogon' = if ($daysSinceLastLogon -ne $null) { $daysSinceLastLogon } else { 'Brak danych' }
            'PasswordLastSet' = if ($passwordLastSet) { $passwordLastSet } else { 'Brak danych' }
            'DaysToPasswordExpiry' = if ($daysToPasswordExpiry -ne $null) { $daysToPasswordExpiry } else { 'Brak danych' }
            'PasswordChangedBy' = 'Niedostępne*'
        }
    }
    return $results
}

# GUI

$form = New-Object System.Windows.Forms.Form
$form.Text = "AD - Informacje o użytkownikach"
$form.Size = New-Object System.Drawing.Size(1000,600)
$form.StartPosition = "CenterScreen"

$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "Pobierz dane"
$btnLoad.Location = New-Object System.Drawing.Point(10,10)
$btnLoad.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($btnLoad)

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(10,50)
$grid.Size = New-Object System.Drawing.Size(960,500)
$grid.AutoSizeColumnsMode = 'Fill'
$grid.ReadOnly = $true
$form.Controls.Add($grid)

$btnLoad.Add_Click({
    $btnLoad.Enabled = $false
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $grid.DataSource = $null
    try {
        $data = Get-ADUserLogonInfo
        $grid.DataSource = $data
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Błąd pobierania danych: $($_.Exception.Message)")
    }
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
    $btnLoad.Enabled = $true
})

$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()

# * Do wykrycia 'kto zmienił hasło' wymagany jest włączony auditing w dziennikach zabezpieczeń domeny i analiza logów.
