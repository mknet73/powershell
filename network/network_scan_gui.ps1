Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the window
$form = New-Object System.Windows.Forms.Form
$form.Text = "LAN Network Scanner"
$form.Size = New-Object System.Drawing.Size(700,500)
$form.StartPosition = "CenterScreen"

# Label and textbox for start IP
$labelStart = New-Object System.Windows.Forms.Label
$labelStart.Text = "Start IP address:"
$labelStart.Location = New-Object System.Drawing.Point(10,10)
$labelStart.Size = New-Object System.Drawing.Size(120,20)
$form.Controls.Add($labelStart)

$textStart = New-Object System.Windows.Forms.TextBox
$textStart.Location = New-Object System.Drawing.Point(130,10)
$textStart.Size = New-Object System.Drawing.Size(150,20)
$textStart.Text = "192.168.1.1"
$form.Controls.Add($textStart)

# Label and textbox for end IP
$labelEnd = New-Object System.Windows.Forms.Label
$labelEnd.Text = "End IP address:"
$labelEnd.Location = New-Object System.Drawing.Point(320,10)
$labelEnd.Size = New-Object System.Drawing.Size(110,20)
$form.Controls.Add($labelEnd)

$textEnd = New-Object System.Windows.Forms.TextBox
$textEnd.Location = New-Object System.Drawing.Point(430,10)
$textEnd.Size = New-Object System.Drawing.Size(150,20)
$textEnd.Text = "192.168.1.254"
$form.Controls.Add($textEnd)

# Scan button
$buttonScan = New-Object System.Windows.Forms.Button
$buttonScan.Text = "Scan"
$buttonScan.Location = New-Object System.Drawing.Point(600,10)
$buttonScan.Size = New-Object System.Drawing.Size(75,23)
$form.Controls.Add($buttonScan)

# Results table
$dataGrid = New-Object System.Windows.Forms.DataGridView
$dataGrid.Location = New-Object System.Drawing.Point(10,50)
$dataGrid.Size = New-Object System.Drawing.Size(665,350)
$dataGrid.ColumnCount = 3
$dataGrid.Columns[0].Name = "IP"
$dataGrid.Columns[1].Name = "Hostname"
$dataGrid.Columns[2].Name = "Model"
$form.Controls.Add($dataGrid)

# Save button
$buttonSave = New-Object System.Windows.Forms.Button
$buttonSave.Text = "Save to Excel"
$buttonSave.Location = New-Object System.Drawing.Point(10,420)
$buttonSave.Size = New-Object System.Drawing.Size(120,30)
$form.Controls.Add($buttonSave)

# Function to generate IP range (within the same subnet)
function Get-IpRange($start,$end) {
    $startBytes = [System.Net.IPAddress]::Parse($start).GetAddressBytes()
    $endBytes = [System.Net.IPAddress]::Parse($end).GetAddressBytes()
    $ipList = @()
    for ($i = $startBytes[3]; $i -le $endBytes[3]; $i++) {
        $ip = "$($startBytes[0]).$($startBytes[1]).$($startBytes[2]).$i"
        $ipList += $ip
    }
    return $ipList
}

# Scan function
$buttonScan.Add_Click({
    $dataGrid.Rows.Clear()
    $ipRange = Get-IpRange $textStart.Text $textEnd.Text
    foreach ($ip in $ipRange) {
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
            try { $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName } catch { $hostname = "" }
            $model = "" # Here you can add SNMP or HTTP code for model detection
            $row = $dataGrid.Rows.Add()
            $dataGrid.Rows[$row].Cells[0].Value = $ip
            $dataGrid.Rows[$row].Cells[1].Value = $hostname
            $dataGrid.Rows[$row].Cells[2].Value = $model
        }
    }
})

# Save function
$buttonSave.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "CSV|*.csv"
    $saveDialog.FileName = "Devices.csv"
    if ($saveDialog.ShowDialog() -eq "OK") {
        $csv = ""
        foreach ($row in $dataGrid.Rows) {
            if ($row.IsNewRow -eq $false) {
                $csv += "$($row.Cells[0].Value);$($row.Cells[1].Value);$($row.Cells[2].Value)`r`n"
            }
        }
        Set-Content $saveDialog.FileName $csv -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Saved to file: $($saveDialog.FileName)")
    }
})

[void]$form.ShowDialog()
