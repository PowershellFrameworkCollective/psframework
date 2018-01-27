$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")

Describe "$CommandName Unit Tests" -Tag "UnitTests" {
	Context "Validate parameters" {
		$paramCount = 13
        <#
            Get commands, Default count = 11
            Commands with SupportShouldProcess = 13
        #>
		$defaultParamCount = 11
		[object[]]$params = (Get-Item function:\Write-PSFMessage).Parameters.Keys
		$knownParameters = 'Level', 'Message', 'Tag', 'FunctionName', 'ModuleName', 'File', 'Line', 'ErrorRecord', 'Exception', 'Once', 'OverrideExceptionMessage', 'Target', 'EnableException'
		It "Should contian our specifc parameters" {
			((Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count) | Should Be $paramCount
		}
		It "Should only contain $paramCount parameters" {
			$params.Count - $defaultParamCount | Should Be $paramCount
		}
	}
	
	Context "Writing messages" {
		It "Should write a message to verbose" {
			$message = Write-PSFMessage -Message "foo" -Verbose 4>&1
			$message.Message | Should Match "^\[\d\d:\d\d:\d\d\]\[[\w><\.]+\] foo"
			$message.GetType().FullName | Should Be "System.Management.Automation.VerboseRecord"
		}
		
		It "Should remove color tags on verbose" {
			$message = Write-PSFMessage -Message "<c='red'>foo</c>" -Verbose 4>&1
			$message.Message | Should Not Match "<c='red'>"
		}
		
		It "Should write a once message only once to information" {
			$random = (0 .. 9 | Get-Random -Count 6) -join ""
			Write-PSFMessage -Message "foo" -Level Important -Once $random
			Write-PSFMessage -Message "foo" -Level Important -Once $random
			$messages = (Get-PSFMessage)[-2 .. -1]
			($messages | Where-Object Type -like "*Information*" | Measure-Object).Count | Should Be 1
		}
		
		Write-PSFMessage -Level System -Message "This is a test message" -Tag test, message -FunctionName Get-Test -ModuleName PSFrameworkTests -Target "TestTarget"
		$message = Get-PSFMessage | Select-Object -Last 1
		
		It "Should write the correct message contents" {
			$message.Message | Should Be "This is a test message"
			$message.Type | Should Be "Debug"
			#$message.Timestamp | Should Be ((New-Object System.DateTime(2018, 1, 1)).Date)
			$message.FunctionName | Should Be "Get-Test"
			$message.ModuleName | Should Be "PSFrameworkTests"
			$message.Tags | Should Be "test", "message"
			$message.Level | Should Be "System"
			$message.Runspace | Should Be ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId)
			$message.ComputerName | Should Be $env:COMPUTERNAME
			$message.TargetObject | Should Be "TestTarget"
			$message.File | Should BeLike "*\Write-PSFMessage.Tests.ps1"
			$message.Line | Should Be 41
		}
		
		It "Should only have known properties" {
			$properties = 'Message', 'Type', 'Timestamp', 'FunctionName', 'ModuleName', 'Tags', 'Level', 'Runspace', 'ComputerName', 'TargetObject', 'File', 'Line'
			$message.PSObject.Properties.Name | Should Be $properties
		}
		
		try { $null.GetType() }
		catch
		{
			$err = $_
			Write-PSFMessage -Message "This has an error" -ErrorRecord $_
		}
		
		$message = Get-PSFMessage | Select-Object -Last 1
		$messageError = Get-PSFMessage -Errors | Select-Object -Last 1
		
		It "Should have included the error message" {
			$message.Message | Should BeLike "*$($err.Exception.Message)*"
		}
		
		It "Should have logged the error correctly" {
			$messageError.ExceptionType | Should Be "RuntimeException"
		}
	}
}