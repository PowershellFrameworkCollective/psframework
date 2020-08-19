function New-PSFSupportPackage
{
<#
	.SYNOPSIS
		Creates a package of troubleshooting information that can be used by developers to help debug issues.
	
	.DESCRIPTION
		This function creates an extensive debugging package that can help with reproducing and fixing issues.
		
		The file will be created on the desktop by default and will contain quite a bit of information:
		- OS Information
		- Hardware Information (CPU, Ram, things like that)
		- .NET Information
		- PowerShell Information
		- Your input history
		- The In-Memory message log
		- The In-Memory error log
		- Screenshot of the console buffer (Basically, everything written in your current console, even if you have to scroll upwards to see it).
	
	.PARAMETER Path
		The folder where to place the output xml in.
		Defaults to your desktop.
	
	.PARAMETER Include
		What to include in the export.
		By default, all is included.
	
	.PARAMETER Exclude
		Anything not to include in the export.
		Use this to explicitly exclude content you do not wish to be part of the dump (for example for data protection reasons).
	
	.PARAMETER Variables
		Name of additional variables to attach.
		This allows you to add the content of variables to the support package, if you believe them to be relevant to the case.
	
	.PARAMETER ExcludeError
		By default, the content of $Error is included, as it often can be helpful in debugging, even with error handling using the message system.
		However, there can be rare instances where this will explode the total export size to gigabytes, in which case it becomes necessary to skip this.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		New-PSFSupportPackage
		
		Creates a large support pack in order to help us troubleshoot stuff.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/New-PSFSupportPackage')]
	param (
		[string]
		$Path = "$($env:USERPROFILE)\Desktop",
		
		[PSFramework.Utility.SupportData]
		$Include = 'All',
		
		[PSFramework.Utility.SupportData]
		$Exclude = 'None',
		
		[string[]]
		$Variables,
		
		[switch]
		$ExcludeError,
		
		[switch]
		[Alias('Silent')]
		$EnableException
	)
	
	begin
	{
		#region Helper functions
		function Get-ShellBuffer
		{
			[CmdletBinding()]
			param ()
			
			if ($Host.Name -eq 'Windows PowerShell ISE Host')
			{
				return $psIse.CurrentPowerShellTab.ConsolePane.Text
			}
			
			try
			{
				# Define limits
				$rec = New-Object System.Management.Automation.Host.Rectangle
				$rec.Left = 0
				$rec.Right = $host.ui.rawui.BufferSize.Width - 1
				$rec.Top = 0
				$rec.Bottom = $host.ui.rawui.BufferSize.Height - 1
				
				# Load buffer
				$buffer = $host.ui.rawui.GetBufferContents($rec)
				
				# Convert Buffer to list of strings
				$int = 0
				$lines = @()
				while ($int -le $rec.Bottom)
				{
					$n = 0
					$line = ""
					while ($n -le $rec.Right)
					{
						$line += $buffer[$int, $n].Character
						$n++
					}
					$line = $line.TrimEnd()
					$lines += $line
					$int++
				}
				
				# Measure empty lines at the beginning
				$int = 0
				$temp = $lines[$int]
				while ($temp -eq "") { $int++; $temp = $lines[$int] }
				
				# Measure empty lines at the end
				$z = $rec.Bottom
				$temp = $lines[$z]
				while ($temp -eq "") { $z--; $temp = $lines[$z] }
				
				# Skip the line launching this very function
				$z--
				
				# Measure empty lines at the end (continued)
				$temp = $lines[$z]
				while ($temp -eq "") { $z--; $temp = $lines[$z] }
				
				# Cut results to the limit and return them
				return $lines[$int .. $z]
			}
			catch { }
		}
		#endregion Helper functions
	}
	process
	{
		$filePathXml = Join-Path $Path "powershell_support_pack_$(Get-Date -Format "yyyy_MM_dd-HH_mm_ss").cliDat"
		$filePathZip = $filePathXml -replace "\.cliDat$", ".zip"
		
		Write-PSFMessage -Level Critical -String 'New-PSFSupportPackage.Header' -StringValues $filePathZip, (Get-PSFConfigValue -FullName 'psframework.supportpackage.contactmessage' -Fallback '')
		
		$hash = @{ }
		if (($Include -band 1) -and -not ($Exclude -band 1))
		{
			Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.Messages'
			$hash["Messages"] = Get-PSFMessage
		}
		if (($Include -band 2) -and -not ($Exclude -band 2))
		{
			Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.MsgErrors'
			$hash["Errors"] = Get-PSFMessage -Errors
		}
		if (($Include -band 4) -and -not ($Exclude -band 4))
		{
			Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.ConsoleBuffer'
			$hash["ConsoleBuffer"] = Get-ShellBuffer
		}
		if (($Include -band 8) -and -not ($Exclude -band 8))
		{
			Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.OperatingSystem'
			$hash["OperatingSystem"] = if ($IsLinux -or $IsMacOs)
			{
				[PSCustomObject]@{
					OSVersion = [System.Environment]::OSVersion
					ProcessorCount = [System.Environment]::ProcessorCount
					Is64Bit   = [System.Environment]::Is64BitOperatingSystem
					LogicalDrives = [System.Environment]::GetLogicalDrives()
					SystemDirectory = [System.Environment]::SystemDirectory
				}
			}
			else
			{
				Get-CimInstance -ClassName Win32_OperatingSystem
			}
		}
		if (($Include -band 16) -and -not ($Exclude -band 16))
		{
			$hash["CPU"] = if ($IsLinux -and (Test-Path -Path /proc/cpuinfo))
			{
				Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.CPU' -StringValues '/proc/cpuinfo'
				Get-Content -Raw -Path /proc/cpuinfo
			}
			else
			{
				Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.CPU' -StringValues Win32_Processor
				Get-CimInstance -ClassName Win32_Processor
			}
		}
		if (($Include -band 32) -and -not ($Exclude -band 32))
		{
			$hash["Ram"] = if ($IsLinux -and (Test-Path -Path /proc/meminfo))
			{
				Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.RAM' -StringValues '/proc/meminfo'
				Get-Content -Raw -Path /proc/meminfo
			}
			else
			{
				Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.RAM' -StringValues Win32_PhysicalMemory
				Get-CimInstance -ClassName Win32_PhysicalMemory
			}
		}
		if (($Include -band 64) -and -not ($Exclude -band 64))
		{
			Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.PSVersion'
			$hash["PSVersion"] = $PSVersionTable
		}
		if (($Include -band 128) -and -not ($Exclude -band 128))
		{
			Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.History'
			$hash["History"] = Get-History
		}
		if (($Include -band 256) -and -not ($Exclude -band 256))
		{
			Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.Modules'
			$hash["Modules"] = Get-Module
		}
		if ((($Include -band 512) -and -not ($Exclude -band 512)) -and (Get-Command -Name Get-PSSnapIn -ErrorAction SilentlyContinue))
		{
			Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.Snapins'
			$hash["SnapIns"] = Get-PSSnapin
		}
		if (($Include -band 1024) -and -not ($Exclude -band 1024))
		{
			Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.Assemblies'
			$hash["Assemblies"] = [appdomain]::CurrentDomain.GetAssemblies() | Select-Object CodeBase, FullName, Location, ImageRuntimeVersion, GlobalAssemblyCache, IsDynamic
		}
		if (Test-PSFParameterBinding -ParameterName "Variables")
		{
			Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.Variables' -StringValues ($Variables -join ", ")
			$hash["Variables"] = $Variables | Get-Variable -ErrorAction Ignore
		}
		if (($Include -band 2048) -and -not ($Exclude -band 2048) -and (-not $ExcludeError))
		{
			Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.PSErrors'
			$hash["PSErrors"] = @()
			foreach ($errorItem in $global:Error) { $hash["PSErrors"] += New-Object PSFramework.Message.PsfException($errorItem) }
		}
		if (($Include -band 4096) -and -not ($Exclude -band 4096))
		{
			if (Test-Path function:Get-DbatoolsLog)
			{
				Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.DbaTools.Messages'
				$hash["DbatoolsMessages"] = Get-DbatoolsLog
				Write-PSFMessage -Level Important -String 'New-PSFSupportPackage.DbaTools.Errors'
				$hash["DbatoolsErrors"] = Get-DbatoolsLog -Errors
			}
		}
		
		$data = [pscustomobject]$hash
		
		try { $data | Export-PsfClixml -Path $filePathXml -ErrorAction Stop }
		catch
		{
			Stop-PSFFunction -String 'New-PSFSupportPackage.Export.Failed' -ErrorRecord $_ -Target $filePathXml -EnableException $EnableException
			return
		}
		
		try { Compress-Archive -Path $filePathXml -DestinationPath $filePathZip -ErrorAction Stop }
		catch
		{
			Stop-PSFFunction -String 'New-PSFSupportPackage.ZipCompression.Failed' -ErrorRecord $_ -Target $filePathZip -EnableException $EnableException
			return
		}
		
		Remove-Item -Path $filePathXml -ErrorAction Ignore
	}
}