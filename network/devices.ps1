# Zakres IP do przeskanowania
$Subnet = "192.168.1."
$Start = 1
$End = 254

# Wynikowa tablica
$Results = @()

# Funkcja pobierająca nazwę hosta
function Get-Hostname {
    param($ip)
    try {
        [System.Net.Dns]::GetHostEntry($ip).HostName
    } catch {
        ""
    }
}

# Funkcja pobierająca model urządzenia przez SNMP (jeśli masz snmpwalk lub snmpget)
function Get-SNMP-Model {
    param($ip)
    $oid = "1.3.6.1.2.1.1.1.0" # sysDescr
    try {
        $result = snmpget -v 2c -c public $ip $oid
        $result
    } catch {
        ""
    }
}

# Funkcja pobierająca nagłówek HTTP
function Get-HTTP-Model {
    param($ip)
    try {
        $response = Invoke-WebRequest -Uri "http://$ip" -UseBasicParsing -TimeoutSec 2
        $response.Headers["Server"]
    } catch {
        ""
    }
}

# Skanowanie sieci
for ($i = $Start; $i -le $End; $i++) {
    $ip = "$Subnet$i"
    Write-Host "Sprawdzam: $ip"
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
        $hostname = Get-Hostname $ip
        $model = Get-SNMP-Model $ip
        if (-not $model) {
            $model = Get-HTTP-Model $ip
        }
        $Results += [PSCustomObject]@{
            IP        = $ip
            Hostname  = $hostname
            Model     = $model
        }
    }
}

# Eksport do Excela (CSV)
$Results | Export-Csv -Path .\Devices.csv -NoTypeInformation -Delimiter ";"
Write-Host "Gotowe! Wyniki zapisane w Devices.csv"
