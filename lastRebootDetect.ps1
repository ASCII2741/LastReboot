# Set the path to store the last reboot time
$RebootTimeFile = "C:\Windows\Temp\LastRebootTime.txt"

# Function to get the last reboot time from the file
Function Get-LastRebootTime {
    if (Test-Path $RebootTimeFile) {
        $lastRebootTime = Get-Content $RebootTimeFile | Get-Date
        return $lastRebootTime
    }
    return $null
}

# Function to save the last reboot time to the file
Function Save-LastRebootTime {
    $Last_reboot | Out-File -FilePath $RebootTimeFile -Force
}

# Get the last reboot time from the file or CIMInstance
$Last_reboot = Get-LastRebootTime
if ($Last_reboot -eq $null) {
    $Last_reboot = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime
    Save-LastRebootTime
}

# Calculate system uptime
$Current_Date = Get-Date
$Diff_boot_time = $Current_Date - $Last_reboot
$Boot_Uptime_Days = $Diff_boot_time.Days

# Rest of the script remains the same...
