Register-PSFConfigValidation -Name "sizestyle" -ScriptBlock {
    param (
        $Value
    )

    $Result = [PSCustomObject]@{
        Success = $True
        Value   = $null
        Message = ""
    }

    try { [PSFramework.Utility.SizeStyle]$style = $Value }
    catch {
        $Result.Message = "Not a size style: $Value"
        $Result.Success = $False
        return $Result
    }

    $Result.Value = $style

    return $Result
}