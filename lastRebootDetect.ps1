# Set toast text
# Message for reboot
$Title = "Your device has not rebooted or shutdown since"
# Warning message
$Message = "`nTo ensure the stability and proper functioning of your system, consider rebooting or shutting down your device very soon."
# Advice message 
$Advice = "`nWe recommend you to restart or shut down your computer at least once every 3 days"
# Header
$Text_AppName = "NBN IT"

$Show_RestartNow_Button = $True # It will add a button to reboot the device

# Function to set an action
Function Set_Action {
    param(
    $Action_Name        
    )   
    
    $Main_Reg_Path = "HKCU:\SOFTWARE\Classes\$Action_Name"
    $Command_Path = "$Main_Reg_Path\shell\open\command"
    $CMD_Script = "C:\Windows\Temp\$Action_Name.cmd"
    New-Item $Command_Path -Force
    New-ItemProperty -Path $Main_Reg_Path -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null
    Set-ItemProperty -Path $Main_Reg_Path -Name "(Default)" -Value "URL:$Action_Name Protocol" -Force | Out-Null
    Set-ItemProperty -Path $Command_Path -Name "(Default)" -Value $CMD_Script -Force | Out-Null        
}

# Script to restart the machine
$Restart_Script = @'
shutdown /r /f /t 300
'@
$Script_Export_Path = "C:\Windows\Temp"
If ($Show_RestartNow_Button -eq $True) {
    $Restart_Script | Out-File "$Script_Export_Path\RestartScript.cmd" -Force -Encoding ASCII
    Set_Action -Action_Name RestartScript    
}

# Function to register the notification app
Function Register-NotificationApp($AppID,$AppDisplayName) {
    [int]$ShowInSettings = 0
    [int]$IconBackgroundColor = 0
    $IconUri = "C:\Windows\ImmersiveControlPanel\images\logo.png"
    
    $AppRegPath = "HKCU:\Software\Classes\AppUserModelId"
    $RegPath = "$AppRegPath\$AppID"
    
    $Notifications_Reg = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings'
    If (!(Test-Path -Path "$Notifications_Reg\$AppID")) {
        New-Item -Path "$Notifications_Reg\$AppID" -Force
        New-ItemProperty -Path "$Notifications_Reg\$AppID" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force
    }

    If ((Get-ItemProperty -Path "$Notifications_Reg\$AppID" -Name 'ShowInActionCenter' -ErrorAction SilentlyContinue).ShowInActionCenter -ne '1') {
        New-ItemProperty -Path "$Notifications_Reg\$AppID" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force | Out-Null
    }       
    
    try {
        if (-NOT(Test-Path $RegPath)) {
            New-Item -Path $AppRegPath -Name $AppID -Force | Out-Null
        }
        $DisplayName = Get-ItemProperty -Path $RegPath -Name DisplayName -ErrorAction SilentlyContinue | Select -ExpandProperty DisplayName -ErrorAction SilentlyContinue
        if ($DisplayName -ne $AppDisplayName) {
            New-ItemProperty -Path $RegPath -Name DisplayName -Value $AppDisplayName -PropertyType String -Force | Out-Null
        }
        $ShowInSettingsValue = Get-ItemProperty -Path $RegPath -Name ShowInSettings -ErrorAction SilentlyContinue | Select -ExpandProperty ShowInSettings -ErrorAction SilentlyContinue
        if ($ShowInSettingsValue -ne $ShowInSettings) {
            New-ItemProperty -Path $RegPath -Name ShowInSettings -Value $ShowInSettings -PropertyType DWORD -Force | Out-Null
        }
        
        New-ItemProperty -Path $RegPath -Name IconUri -Value $IconUri -PropertyType ExpandString -Force | Out-Null    
        New-ItemProperty -Path $RegPath -Name IconBackgroundColor -Value $IconBackgroundColor -PropertyType ExpandString -Force | Out-Null        
        
    }
    catch {}
}

# Function to get the last shutdown time
Function Get-LastShutdownTime {
    $ShutdownEvent = Get-WinEvent -LogName System -MaxEvents 1 | Where-Object { $_.Id -eq 1074 -or $_.Id -eq 6008 } | Sort-Object TimeCreated -Descending | Select-Object -First 1
    if ($ShutdownEvent -eq $null) {
        return $null
    }
    return $ShutdownEvent.TimeCreated
}

# Function to get the last reboot time
Function Get-LastRebootTime {
    $RebootEvent = Get-WinEvent -LogName System -MaxEvents 1 | Where-Object { $_.Id -eq 1074 -or $_.Id -eq 6008 } | Sort-Object TimeCreated -Descending | Select-Object -First 1
    if ($RebootEvent -eq $null) {
        return $null
    }
    return $RebootEvent.TimeCreated
}

# Function to check if the device should show the toast notification
Function ShouldShowToastNotification {
    param (
        [int]$daysThreshold
    )

    $LastRebootTime = Get-LastRebootTime
    $LastShutdownTime = Get-LastShutdownTime

    # Check if the event logs contained the necessary information
    if ($LastRebootTime -eq $null -or $LastShutdownTime -eq $null) {
        return $false
    }

    $CurrentDate = Get-Date

    # Calculate the uptime based on the last reboot, last shutdown, or power-on time
    if ($LastRebootTime -ge $LastShutdownTime) {
        $Uptime = $LastRebootTime
    } else {
        $Uptime = $LastShutdownTime
    }

    $UptimeDuration = $CurrentDate - $Uptime
    $UptimeDays = [math]::Floor($UptimeDuration.TotalDays)

    return $UptimeDays -gt $daysThreshold
}

# Check if the device should show the toast notification
$DaysThreshold = 3
if (ShouldShowToastNotification -daysThreshold $DaysThreshold) {
    # Tost Notification part
    $Title = $Title + " $($DaysThreshold) day(s) or more"

    $Scenario = 'reminder' 

    $Action_Restart = "RestartScript:"
    If ($Show_RestartNow_Button -eq $True) {
        $Actions = 
    @"
      <actions>
            <action activationType="protocol" arguments="$Action_Restart" content="Restart now" />        
            <action activationType="protocol" arguments="Dismiss" content="Dismiss" />
       </actions>    
"@
    } else {
        $Actions = 
    @"
      <actions>
            <action activationType="protocol" arguments="Dismiss" content="Dismiss" />
       </actions>    
"@
    }

    [xml]$Toast = @"
    <toast scenario="$Scenario">
        <visual>
        <binding template="ToastGeneric">
            <text placement="attribution">$Text_AppName</text>
            <text>$Title</text>
            <group>
                <subgroup>     
                    <text hint-style="body" hint-wrap="true" >$Message</text>
                </subgroup>
            </group>
            
            <group>                
                <subgroup>     
                    <text hint-style="body" hint-wrap="true" >$Advice</text>                                
                </subgroup>                
            </group>                
        </binding>
        </visual>
        $Actions
    </toast>
"@ 

    $AppID = $Text_AppName
    $AppDisplayName = $Text_AppName
    Register-NotificationApp -AppID $Text_AppName -AppDisplayName $Text_AppName

    # Toast creation and display
    $Load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $Load = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
    $ToastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
    $ToastXml.LoadXml($Toast.OuterXml)    
    # Display the Toast
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppID).Show($ToastXml)
} else {
    Write-Host "Uptime is less than $DaysThreshold days. No notification will be shown."
}
