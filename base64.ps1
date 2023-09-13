# ***************************************************************************
# 								Part to fill
# ***************************************************************************
# Set toast text
# Message for reboot
$Title = "Your device has not rebooted since"
# Warning message
$Message = "`nTo ensure the stability and proper functioning of your system, consider rebooting your device very soon."
# Advice message 
$Advice = "`nWe recommend you to restart your computer at least once every 3 days"
# Header
$Text_AppName = "NBN IT"

$Show_RestartNow_Button = $True # It will add a button to reboot the device

# ***************************************************************************
# 								Export picture
# ***************************************************************************
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

# Function to get the last power-on time
Function Get-LastPowerOnTime {
    $PowerOnEvent = Get-WinEvent -LogName System | Where-Object { $_.Id -eq 12 } | Sort-Object TimeCreated -Descending | Select-Object -First 1
    return $PowerOnEvent.TimeCreated
}

# Get the last reboot time and last power-on time
$LastRebootTime = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime
$LastPowerOnTime = Get-LastPowerOnTime

# Calculate the uptime based on the last reboot or power-on time
if ($LastRebootTime -ge $LastPowerOnTime) {
    $Uptime = $LastRebootTime
} else {
    $Uptime = $LastPowerOnTime
}

# Calculate the number of days since the last reboot or power-on
$CurrentDate = Get-Date
$UptimeDuration = $CurrentDate - $Uptime
$UptimeDays = [math]::Floor($UptimeDuration.TotalDays)

# Tost Notification part
$Title = $Title + " $UptimeDays day(s)"

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
