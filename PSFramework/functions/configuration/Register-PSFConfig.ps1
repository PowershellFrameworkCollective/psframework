function Register-PSFConfig
{
	[CmdletBinding(DefaultParameterSetName = "FullName")]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = "Config", Position = 0, ValueFromPipeline = $true)]
		[PSFramework.Configuration.Config[]]
		$Config,
		
		[Parameter(Mandatory = $true, ParameterSetName = "FullName", Position = 0, ValueFromPipeline = $true)]
		[string]
		$FullName,
		
		[Parameter(Mandatory = $true, ParameterSetName = "Name", Position = 0)]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = "Name", Position = 1)]
		[string]
		$Name = "*",
		
		$Scope = "UserDefault"
	)
	
	begin
	{
		$parSet = $PSCmdlet.ParameterSetName
		
		function Write-Config
		{
			[CmdletBinding()]
			Param (
				[PSFramework.Configuration.Config]
				$Config,
				
				$Scope
			)
		}
	}
	process
	{
		switch ($parSet)
		{
			"Config"
			{
				foreach ($item in $Config)
				{
					Write-Config -Config $item -Scope $Scope
				}
			}
			"FullName"
			{
				
			}
			"Name"
			{
				
			}
		}
	}
	end
	{
		
	}
}