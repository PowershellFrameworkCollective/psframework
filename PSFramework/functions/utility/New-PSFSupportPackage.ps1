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
		Write-PSFMessage -Level InternalComment -Message "Starting"
		Write-PSFMessage -Level Verbose -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")"
		
		#region Helper functions
		function Get-ShellBuffer
		{
			[CmdletBinding()]
			param ()
			
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
		
		Write-PSFMessage -Level Critical -Message @"
Gathering information...
Will write the final output to: $filePathZip
$(Get-PSFConfigValue -FullName 'psframework.supportpackage.contactmessage' -Fallback '')
Be aware that this package contains a lot of information including your input history in the console.
Please make sure no sensitive data (such as passwords) can be caught this way.

Ideally start a new console, perform the minimal steps required to reproduce the issue, then run this command.
This will make it easier for us to troubleshoot and you won't be sending us the keys to your castle.
"@
		
		$hash = @{ }
		if (($Include -band 1) -and -not ($Exclude -band 1))
		{
			Write-PSFMessage -Level Important -Message "Collecting PSFramework logged messages (Get-PSFMessage)"
			$hash["Messages"] = Get-PSFMessage
		}
		if (($Include -band 2) -and -not ($Exclude -band 2))
		{
			Write-PSFMessage -Level Important -Message "Collecting PSFramework logged errors (Get-PSFMessage -Errors)"
			$hash["Errors"] = Get-PSFMessage -Errors
		}
		if (($Include -band 4) -and -not ($Exclude -band 4))
		{
			Write-PSFMessage -Level Important -Message "Trying to collect copy of console buffer (what you can see on your console)"
			$hash["ConsoleBuffer"] = Get-ShellBuffer
		}
		if (($Include -band 8) -and -not ($Exclude -band 8))
		{
			Write-PSFMessage -Level Important -Message "Collecting Operating System information (Win32_OperatingSystem)"
			$hash["OperatingSystem"] = if ($IsLinux -or $IsMacOs)
			{
				[PSCustomObject]@{
					OSVersion = [System.Environment]::OSVersion
					ProcessorCount = [System.Environment]::ProcessorCount
					Is64Bit = [System.Environment]::Is64BitOperatingSystem
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
				Write-PSFMessage -Level Important -Message "Collecting CPU information (/proc/cpuinfo)"
				Get-Content -Raw -Path /proc/cpuinfo
			}
			else
			{
				Write-PSFMessage -Level Important -Message "Collecting CPU information (Win32_Processor)"
				Get-CimInstance -ClassName Win32_Processor
			}
		}
		if (($Include -band 32) -and -not ($Exclude -band 32))
		{
			$hash["Ram"] = if ($IsLinux -and (Test-Path -Path /proc/meminfo))
			{
				Write-PSFMessage -Level Important -Message "Collecting Ram information (/proc/meminfo)"
				Get-Content -Raw -Path /proc/meminfo
			}
			else
			{
				Write-PSFMessage -Level Important -Message "Collecting Ram information (Win32_PhysicalMemory)"
				Get-CimInstance -ClassName Win32_PhysicalMemory
			}
		}
		if (($Include -band 64) -and -not ($Exclude -band 64))
		{
			Write-PSFMessage -Level Important -Message "Collecting PowerShell & .NET Version (`$PSVersionTable)"
			$hash["PSVersion"] = $PSVersionTable
		}
		if (($Include -band 128) -and -not ($Exclude -band 128))
		{
			Write-PSFMessage -Level Important -Message "Collecting Input history (Get-History)"
			$hash["History"] = Get-History
		}
		if (($Include -band 256) -and -not ($Exclude -band 256))
		{
			Write-PSFMessage -Level Important -Message "Collecting list of loaded modules (Get-Module)"
			$hash["Modules"] = Get-Module
		}
		if ((($Include -band 512) -and -not ($Exclude -band 512)) -and (Get-Command -Name Get-PSSnapIn -ErrorAction SilentlyContinue))
		{
			Write-PSFMessage -Level Important -Message "Collecting list of loaded snapins (Get-PSSnapin)"
			$hash["SnapIns"] = Get-PSSnapin
		}
		if (($Include -band 1024) -and -not ($Exclude -band 1024))
		{
			Write-PSFMessage -Level Important -Message "Collecting list of loaded assemblies (Name, Version, and Location)"
			$hash["Assemblies"] = [appdomain]::CurrentDomain.GetAssemblies() | Select-Object CodeBase, FullName, Location, ImageRuntimeVersion, GlobalAssemblyCache, IsDynamic
		}
		if (Test-PSFParameterBinding -ParameterName "Variables")
		{
			Write-PSFMessage -Level Important -Message "Adding variables specified for export: $($Variables -join ", ")"
			$hash["Variables"] = $Variables | Get-Variable -ErrorAction Ignore
		}
		if (($Include -band 2048) -and -not ($Exclude -band 2048) -and (-not $ExcludeError))
		{
			Write-PSFMessage -Level Important -Message "Adding content of `$Error"
			$hash["PSErrors"] = @()
			foreach ($errorItem in $global:Error) { $hash["PSErrors"] += New-Object PSFramework.Message.PsfException($errorItem) }
		}
		if (($Include -band 4096) -and -not ($Exclude -band 4096))
		{
			if (Test-Path function:Get-DbatoolsLog)
			{
				Write-PSFMessage -Level Important -Message "Collecting dbatools logged messages (Get-DbatoolsLog)"
				$hash["DbatoolsMessages"] = Get-DbatoolsLog
				Write-PSFMessage -Level Important -Message "Collecting dbatools logged errors (Get-DbatoolsLog -Errors)"
				$hash["DbatoolsErrors"] = Get-DbatoolsLog -Errors
			}
		}
		
		$data = [pscustomobject]$hash
		
		try { $data | Export-PsfClixml -Path $filePathXml -ErrorAction Stop }
		catch
		{
			Stop-PSFFunction -Message "Failed to export dump to file!" -ErrorRecord $_ -Target $filePathXml
			return
		}
		
		try { Compress-Archive -Path $filePathXml -DestinationPath $filePathZip -ErrorAction Stop }
		catch
		{
			Stop-PSFFunction -Message "Failed to pack dump-file into a zip archive. Please do so manually before submitting the results as the unpacked xml file will be rather large." -ErrorRecord $_ -Target $filePathZip
			return
		}
		
		Remove-Item -Path $filePathXml -ErrorAction Ignore
	}
	end
	{
		Write-PSFMessage -Level InternalComment -Message "Ending"
	}
}
