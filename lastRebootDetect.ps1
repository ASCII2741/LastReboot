function Send-ToastNotification
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $Title,
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $Message,
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string]
        $Advice,
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [int]
        $DaysThreshold
    )
    $Toast = @"
    <toast launch="app-defined-string">
        <visual>
            <binding template="ToastGeneric">
                <text>$Title</text>
                <text>$Message</text>
                <text>$Advice</text>
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
}
$Actions = @"
  <actions>
        <action activationType="protocol" arguments="Dismiss" content="Dismiss" />
   </actions>    
"@