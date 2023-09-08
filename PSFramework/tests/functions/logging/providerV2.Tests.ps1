Describe "Logging System: Provider V2 Unit Test" {
	Describe "Logging Provider - Act 1: Post-Registration" {
		It "Should register without an error" {
			#region Register Logging Provider
			$paramRegisterPSFLoggingProvider = @{
				Name			   = 'Demo'
				ConfigurationRoot  = 'Demo.Provider'
				InstanceProperties = 'StartCounter', 'Increment', 'MaxCounter'
				BeginEvent		   = { Write-PSFMessage "Starting Provider Instance: $($Instance.Name) of Provider $($Instance.Provider)" -Target $Instance.Name }
				StartEvent		   = {
					$script:counter = Get-ConfigValue -Name StartCounter
					$script:increment = Get-ConfigValue -Name Increment
					$script:maxCounter = Get-ConfigValue -Name MaxCounter
					Write-Hello -Name "Jack"
					Write-PSFMessage "Starting Counter at $script:counter" -Target $Instance.Name
				}
				MessageEvent	   = {
					param (
						$Message
					)
					
					if (($script:counter + $script:increment) -le $script:maxCounter)
					{
						$script:counter = $script:counter + $script:increment
					}
				}
				EndEvent		   = {
					Write-PSFMessage "Current Counter is at $script:counter" -Target $Instance.Name
				}
				FinalEvent		   = {
					Write-PSFMessage "Stopping to count" -Target $Instance.Name
				}
				FunctionDefinitions = {
					function Write-Hello
					{
						[CmdletBinding()]
						param (
							$Name
						)
						Write-PSFMessage "Hello $Name" -Target $Instance.Name
					}
				}
			}
			
			{ Register-PSFLoggingProvider @paramRegisterPSFLoggingProvider } | Should -Not -Throw
			
			# Wait until the next logging cycle has definitely passed
			Start-Sleep -Seconds 10
			#endregion Register Logging Provider
		}
		It "Should exist" {
			Get-PSFLoggingProvider -Name Demo | Should -BeNullOrEmpty -Not
		}
		
		It "Should create a default instance that is disabled" {
			$provider = Get-PSFLoggingProvider -Name Demo
			$provider.Instances.Count | Should -BeIn 1,2 # Repeated Test Runs will see the MyInstance provider below
			$provider.Instances.Keys | Should -Contain 'Default'
			$provider.Instances.Default.Enabled | Should -BeFalse
		}
	}
	
	Describe "Logging Provider - Act 2: Post-Activation" {
		BeforeAll {
			Set-PSFLoggingProvider -Name Demo -InstanceName MyInstance -StartCounter 0 -Increment 2 -MaxCounter 50 -Enabled $true
			
			# Wait until the next logging cycle has definitely passed
			Start-Sleep -Seconds 8
		}
		
		It "Should have created the MyInstance instance" {
			$provider = Get-PSFLoggingProvider -Name Demo
			$provider.Instances.Count | Should -Be 2
			$provider.Instances.Keys | Should -Contain 'MyInstance'
			$provider.Instances.MyInstance.Enabled | Should -BeTrue
		}
		
		It "Should have written messages without error" {
			Get-PSFMessage | Where-Object FunctionName -eq 'Write-Hello' | Should -BeNullOrEmpty -Not
			Get-PSFMessage | Where-Object Message -eq 'Current Counter is at 6' | Should -BeNullOrEmpty -Not
			# Get-PSFMessage | Where-Object Message -eq 'Starting Provider Instance: MyInstance of Provider Demo' | Should -BeNullOrEmpty -Not
			$provider = Get-PSFLoggingProvider -Name Demo
			$provider.Instances.MyInstance.Errors.Count | Should -Be 0
		}
		
		AfterAll {
			Set-PSFLoggingProvider -Name Demo -InstanceName MyInstance -Enabled $false
			$null = [PSFramework.Logging.ProviderHost]::Providers.TryRemove("Demo", [ref]$null)
		}
	}
}