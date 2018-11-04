function Get-PSFPipeline
{
<#
	.SYNOPSIS
		Generates meta-information for the pipeline from the calling command.
	
	.DESCRIPTION
		Generates meta-information for the pipeline from the calling command.
	
	.EXAMPLE
		PS C:\> Get-Pipeline
	
		Generates meta-information for the pipeline from the calling command.
#>
	[OutputType([PSFramework.Meta.Pipeline])]
	[CmdletBinding()]
	param (
		
	)
	
	begin
	{
		function Get-PrivateProperty
		{
			[CmdletBinding()]
			param (
				$Object,
				
				[string]
				$Name,
				
				[ValidateSet('Any', 'Field', 'Property')]
				[string]
				$Type = 'Any'
			)
			
			if ($null -eq $Object) { return }
			
			$typeObject = $Object.GetType()
			[System.Reflection.BindingFlags]$flags = "NonPublic, Instance"
			switch ($Type)
			{
				'Field'
				{
					$field = $typeObject.GetField($Name, $flags)
					$field.GetValue($Object)
				}
				'Property'
				{
					$property = $typeObject.GetProperty($Name, $flags)
					$property.GetValue($Object)
				}
				'Any'
				{
					$field = $typeObject.GetField($Name, $flags)
					if ($field) { return $field.GetValue($Object) }
					$property = $typeObject.GetProperty($Name, $flags)
					$property.GetValue($Object)
				}
			}
		}
	}
	process
	{
		$callerCmdlet = (Get-PSCallStack)[1].GetFrameVariables()["PSCmdlet"].Value
		
		$commandRuntime = Get-PrivateProperty -Object $callerCmdlet -Name _commandRuntime -Type Field
		$pipelineProcessor = Get-PrivateProperty -Object $commandRuntime -Name PipelineProcessor -Type Property
		$localPipeline = Get-PrivateProperty -Object $pipelineProcessor -Name LocalPipeline -Type Property
		
		$pipeline = New-Object PSFramework.Meta.Pipeline -Property @{
			InstanceId = $localPipeline.InstanceId
			StartTime  = Get-PrivateProperty -Object $localPipeline -Name _pipelineStartTime -Type Field
			Text	   = Get-PrivateProperty -Object $localPipeline -Name HistoryString -Type Property
			PipelineItem = $localPipeline
		}
		
		if ($pipeline.Text)
		{
			$tokens = $null
			$errorItems = $null
			$ast = [System.Management.Automation.Language.Parser]::ParseInput($pipeline.Text, [ref]$tokens, [ref]$errorItems)
			$pipeline.Ast = $ast
			
			$baseItem = $ast.EndBlock.Statements[0]
			if ($baseItem -is [System.Management.Automation.Language.AssignmentStatementAst])
			{
				$pipeline.OutputAssigned = $true
				$pipeline.OutputAssignedTo = $baseItem.Left
				$baseItem = $baseItem.Right.PipelineElements
			}
			else { $baseItem = $baseItem.PipelineElements }
			
			if ($baseItem[0] -is [System.Management.Automation.Language.CommandExpressionAst])
			{
				if ($baseItem[0].Expression -is [System.Management.Automation.Language.VariableExpressionAst])
				{
					$pipeline.InputFromVariable = $true
					$pipeline.InputVariable = $baseItem[0].Expression.VariablePath.UserPath
				}
				else { $pipeline.InputDirect = $true }
				if ($baseItem[0].Expression -is [System.Management.Automation.Language.ConstantExpressionAst])
				{
					$pipeline.InputValue = $baseItem[0].Expression.Value
				}
				elseif ($baseItem[0].Expression -is [System.Management.Automation.Language.ArrayLiteralAst])
				{
					$pipeline.InputValue = @()
					foreach ($element in $baseItem[0].Expression.Elements)
					{
						if ($element -is [System.Management.Automation.Language.ConstantExpressionAst])
						{
							$pipeline.InputValue += $element.Value
						}
						else { $pipeline.InputValue += $element }
					}
				}
				else { $pipeline.InputValue = $baseItem[0].Expression }
			}
		}
		
		$commands = Get-PrivateProperty -Object $pipelineProcessor -Name Commands -Type Property
		$index = 0
		foreach ($command in $commands)
		{
			$commandItem = Get-PrivateProperty -Object $command -Name Command
			$pipeline.Commands.Add((New-Object PSFramework.Meta.PipelineCommand($pipeline.InstanceId, $index, (Get-PrivateProperty -Object $command -Name CommandInfo), $commandItem.MyInvocation, $commandItem)))
			$index++
		}
		
		$pipeline
	}
}