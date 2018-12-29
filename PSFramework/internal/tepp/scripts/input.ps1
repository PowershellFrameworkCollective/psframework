Register-PSFTeppScriptblock -Name PSFramework-Input-Object -ScriptBlock {
	[System.Management.Automation.Language.PipelineAst]$pipelineAst = $commandAst.parent
	$index = $pipelineAst.PipelineElements.IndexOf($commandAst)
	
	#region If it's the first command
	if ($index -lt 1)
	{
		return
	}
	#endregion If it's the first command
	
	$properties = @()
	$constraintsPositive = @()
	
	#region Process pre-commands
	$inputIndex = $index - 1
	:main while ($true)
	{
		if ($pipelineAst.PipelineElements[$inputIndex].CommandElements)
		{
			# Resolve command and fail if it breaks
			$command = Get-Command $pipelineAst.PipelineElements[$inputIndex].CommandElements[0].Value -ErrorAction Ignore
			if ($command -is [System.Management.Automation.AliasInfo]) { $command = $command.ResolvedCommand }
			if (-not $command) { break }
			
			switch ($command.Name)
			{
				'Where-Object' { $inputIndex = $inputIndex - 1; continue main }
				'Tee-Object' { $inputIndex = $inputIndex - 1; continue main }
				#region Select-Object
				'Select-Object'
				{
					$firstAst = $pipelineAst.PipelineElements[$inputIndex].CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.ArrayLiteralAst] } | Select-Object -First 1
					
					foreach ($element in $firstAst.Elements)
					{
						switch ($element.GetType().FullName)
						{
							'System.Management.Automation.Language.StringConstantExpressionAst'
							{
								$constraintsPositive += $element.Value
								if ($element.Value -notmatch "\*") { $properties += $element.Value }
							}
							'System.Management.Automation.Language.HashtableAst'
							{
								$constraintsPositive += ($element.KeyValuePairs | Where-Object Item1 -Match '^N$|^Name$' | Select-Object -First 1).Item2.ToString().Trim('"')
								$properties += ($element.KeyValuePairs | Where-Object Item1 -Match '^N$|^Name$' | Select-Object -First 1).Item2.ToString().Trim('"')
							}
						}
					}
					$inputIndex = $inputIndex - 1;
					continue main
				}
				#endregion Select-Object
				#region Select-PSFObject
				'Select-PSFObject'
				{
					$firstAst = $pipelineAst.PipelineElements[$inputIndex].CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.ArrayLiteralAst] } | Select-Object -First 1
					foreach ($element in $firstAst.Elements)
					{
						switch ($element.GetType().FullName)
						{
							"System.Management.Automation.Language.StringConstantExpressionAst"
							{
								$par = [PSFramework.Parameter.SelectParameter]$element.Value
								if ($par.Value -match "\*") { $constraintsPositive += $par.Value }
								else
								{
									if ($par.Value -is [System.String])
									{
										$properties += $par.Value
										$constraintsPositive += $par.Value
									}
									else
									{
										$properties += $par.Value["Name"]
										$constraintsPositive += $par.Value["Name"]
									}
								}
							}
							"System.Management.Automation.Language.HashtableAst"
							{
								$properties += ($element.KeyValuePairs | Where-Object Item1 -Match '^N$|^Name$' | Select-Object -First 1).Item2.ToString().Trim('"')
								$constraintsPositive += ($element.KeyValuePairs | Where-Object Item1 -Match '^N$|^Name$' | Select-Object -First 1).Item2.ToString().Trim('"')
							}
						}
					}
					$inputIndex = $inputIndex - 1;
				}
				#endregion Select-PSFObject
				default { break main }
			}
		}
		
		else
		{
			break
		}
	}
	
	# Catch moving through _all_ options in the pipeline
	if ($inputIndex -lt 0) { return $properties }
	#endregion Process pre-commands
	
	
	#region Input from command
	if ($pipelineAst.PipelineElements[$inputIndex].CommandElements)
	{
		if ($command = Get-Command $pipelineAst.PipelineElements[$inputIndex].CommandElements[0].Value -ErrorAction Ignore)
		{
			switch ($command.Name)
			{
				#region Default for commands
				default
				{
					foreach ($type in $command.OutputType.Type)
					{
						switch ($type.FullName)
						{
							'System.IO.FileInfo'
							{
								$properties += ($type.GetMembers("Instance, Public") | Where-Object MemberType -match "Field|Property").Name
								$properties += 'PSChildName', 'PSDrive', 'PSIsContainer', 'PSParentPath', 'PSPath', 'PSProvider', 'BaseName'
								break
							}
							'System.IO.DirectoryInfo'
							{
								$properties += ($type.GetMembers("Instance, Public") | Where-Object MemberType -match "Field|Property").Name
								$properties += 'PSChildName', 'PSDrive', 'PSIsContainer', 'PSParentPath', 'PSPath', 'PSProvider', 'BaseName', 'VersionInfo'
								break
							}
							default { $properties += ($type.GetMembers("Instance, Public") | Where-Object MemberType -match "Field|Property").Name }
						}
					}
				}
				#endregion Default for commands
			}
		}
	}
	#endregion Input from command
	
	#region Input from Variable
	if ($pipelineAst.PipelineElements[$inputIndex].Expression -and $pipelineAst.PipelineElements[0].Expression[0].VariablePath)
	{
		$properties += ((Get-Variable -Name $pipelineAst.PipelineElements[0].Expression[0].VariablePath.UserPath -ValueOnly) | Select-Object -First 1 | Get-Member -MemberType Properties).Name
	}
	#endregion Input from Variable
	
	$properties | Select-Object -Unique | Sort-Object | ForEach-Object {
		if (-not $constraintsPositive) { $_ }
		foreach ($constraint in $constraintsPositive)
		{
			if ($_ -like $constraint)
			{
				$_
				break
			}
		}
	}
}