[PSFramework.Logging.ProviderHost]::ProviderV2ModuleScript = {
	param (
		$LoggingProviderInstance
	)
	
	try
	{
		$module = New-Module -Name ([guid]::NewGuid()) -ArgumentList $LoggingProviderInstance -ScriptBlock {
			param (
				$LoggingProviderInstance
			)
			
			$Instance = [pscustomobject]@{
				Name = $LoggingProviderInstance.Name
				Provider = $LoggingProviderInstance.Provider.Name
				ConfigurationRoot = $LoggingProviderInstance.Provider.ConfigurationRoot
			}
			
			# Validate Language Mode for security reasons
			if (Test-PSFLanguageMode -ScriptBlock $LoggingProviderInstance.Provider.BeginEvent -Mode 'ConstrainedLanguage') { throw "The event BeginEvent is in constrained language mode and cannot be loaded!" }
			if (Test-PSFLanguageMode -ScriptBlock $LoggingProviderInstance.Provider.StartEvent -Mode 'ConstrainedLanguage') { throw "The event StartEvent is in constrained language mode and cannot be loaded!" }
			if (Test-PSFLanguageMode -ScriptBlock $LoggingProviderInstance.Provider.MessageEvent -Mode 'ConstrainedLanguage') { throw "The event MessageEvent is in constrained language mode and cannot be loaded!" }
			if (Test-PSFLanguageMode -ScriptBlock $LoggingProviderInstance.Provider.ErrorEvent -Mode 'ConstrainedLanguage') { throw "The event ErrorEvent is in constrained language mode and cannot be loaded!" }
			if (Test-PSFLanguageMode -ScriptBlock $LoggingProviderInstance.Provider.EndEvent -Mode 'ConstrainedLanguage') { throw "The event EndEvent is in constrained language mode and cannot be loaded!" }
			if (Test-PSFLanguageMode -ScriptBlock $LoggingProviderInstance.Provider.FinalEvent -Mode 'ConstrainedLanguage') { throw "The event FinalEvent is in constrained language mode and cannot be loaded!" }
			
			if ($LoggingProviderInstance.Provider.Functions)
			{
				if (Test-PSFLanguageMode -ScriptBlock $LoggingProviderInstance.Provider.Functions -Mode "ConstrainedLanguage") { throw "The functions resource scriptblock is in constrained language mode and cannot be loaded!" }
				# Invoke in current scope after localizing the scriptblock into the current context
				$LoggingProviderInstance.Provider.Functions.InvokeEx($false, $true, $false)
			}
			
			${  functionNames  } = @{
				Begin   = [guid]::NewGuid()
				Start   = [guid]::NewGuid()
				Message = [guid]::NewGuid()
				Error   = [guid]::NewGuid()
				End	    = [guid]::NewGuid()
				Final   = [guid]::NewGuid()
			}
			
			function Get-ConfigValue
			{
				[CmdletBinding()]
				param (
					[string]
					$Name
				)
				
				$rootPath = $script:Instance.ConfigurationRoot
				if ($script:Instance.Name -and $script:Instance.Name -ne "Default")
				{
					$rootPath += ".$($script:Instance.Name)"
				}
				
				Get-PSFConfigValue -FullName "$rootPath.$Name"
			}
			
			Set-Content -Path "function:\$(${  functionNames  }.Begin)" -Value $LoggingProviderInstance.Provider.BeginEvent.ToString()
			$LoggingProviderInstance.BeginCommand = Get-Command ${  functionNames  }.Begin
			Set-Content -Path "function:\$(${  functionNames  }.Start)" -Value $LoggingProviderInstance.Provider.StartEvent.ToString()
			$LoggingProviderInstance.StartCommand = Get-Command ${  functionNames  }.Start
			Set-Content -Path "function:\$(${  functionNames  }.Message)" -Value $LoggingProviderInstance.Provider.MessageEvent.ToString()
			$LoggingProviderInstance.MessageCommand = Get-Command ${  functionNames  }.Message
			Set-Content -Path "function:\$(${  functionNames  }.Error)" -Value $LoggingProviderInstance.Provider.ErrorEvent.ToString()
			$LoggingProviderInstance.ErrorCommand = Get-Command ${  functionNames  }.Error
			Set-Content -Path "function:\$(${  functionNames  }.End)" -Value $LoggingProviderInstance.Provider.EndEvent.ToString()
			$LoggingProviderInstance.EndCommand = Get-Command ${  functionNames  }.End
			Set-Content -Path "function:\$(${  functionNames  }.Final)" -Value $LoggingProviderInstance.Provider.FinalEvent.ToString()
			$LoggingProviderInstance.FinalCommand = Get-Command ${  functionNames  }.Final
			
			$ExecutionContext.SessionState.Module.PrivateData = @{
				Commands = ${  functionNames  }
			}
			Remove-Variable -Name 'event', '  functionNames  ', 'LoggingProviderInstance'
			
			Export-ModuleMember
		} -ErrorAction Stop
	}
	catch
	{
		$LoggingProviderInstance.Errors.Enqueue($_)
		$LoggingProviderInstance.Enabled = $false
	}
	if ($module)
	{
		$LoggingProviderInstance.Module = $module
	}
}