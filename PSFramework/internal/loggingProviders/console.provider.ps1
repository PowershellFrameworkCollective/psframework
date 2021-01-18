$message_event = {
	param (
		$Message
	)
	$style = Get-ConfigValue -Name Style
	$string = $style.Replace('%Time%',$Message.Timestamp.ToString('HH:mm:ss.fff')).Replace('%Date%',$Message.Timestamp.ToString('yyyy-MM-dd')).Replace('%Level%', $Message.Level).Replace('%Module%', $Message.ModuleName).Replace('%FunctionName%', $Message.FunctionName).Replace('%Line%', $Message.Line).Replace('%File%', $Message.File).Replace('%Tags%', ($Message.Tags -join ",")).Replace('%Message%', $Message.LogMessage)
	[System.Console]::WriteLine($string)
}

$configuration_Settings = {
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.Console.Style' -Value '%Message%' -Initialize -Validation string -Description 'The style in which the message is printed. Supports several placeholders: %Message%, %Time%, %Date%, %Tags%, %Level%, %Module%, %FunctionName%, %Line%, %File%. Supports newline and tabs.'
}
$paramRegisterPSFLoggingProvider = @{
	Name			   = "console"
	Version2		   = $true
	ConfigurationRoot  = 'PSFramework.Logging.Console'
	InstanceProperties = 'Style'
	MessageEvent	   = $message_Event
	ConfigurationSettings	   = $configuration_Settings
	ConfigurationDefaultValues = @{
		Style = '%Message%'
	}
}

# Register the Console logging provider
Register-PSFLoggingProvider @paramRegisterPSFLoggingProvider