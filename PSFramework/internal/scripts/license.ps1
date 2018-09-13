$license = New-PSFLicense -Product 'PSFramework' -Manufacturer 'Friedrich Weinmann' -ProductVersion $ModuleVersion -ProductType Module -Name MIT -Version "1.0.0.0" -Date (Get-Date -Year 2017 -Month 04 -Day 27 -Hour 0 -Minute 0 -Second 0) -Text @"
Copyright (c) Friedrich Weinmann

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@

#region Chris Dent
$null = New-PSFLicense -Product 'Import-PSCmdlet' -Manufacturer 'Chris Dent' -ProductVersion '1.0.0.0' -ProductType Script -Name MIT -Version '1.0.0.0' -Date (Get-Date -Year 2018 -Month 05 -Day 16).Date -Text @"
Copyright (c) Chris Dent

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@ -Description @"
The PSFramework is happy to publish the Import-PSFCmdlet command, based on the
original work of Chris Dent's, 'Import-PSCmdlet'

Thank you for allowing its use :)
- Original Source: https://www.indented.co.uk/cmdlets-without-a-dll/
- Author blog: https://www.indented.co.uk/
"@ -Parent $license
#endregion Chris Dent

#region Joel Bennet
$null = New-PSFLicense -Product 'Configuration-ExportPaths' -Manufacturer 'Joel Bennet' -ProductVersion '1.3.0' -ProductType Script -Name MIT -Version '1.0.0.0' -Date (Get-Date -Year 2018 -Month 05 -Day 16).Date -Text @"
Copyright (c) 2015 Joel Bennett

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"@ -Description @"
The PSFramework is happy to base its internal path selection for configuration
exports on the original work of Joel Bennet's, 'Configuration' module.
Its implementation can be found in the internal script file:
internal/scripts/loadConfigurationPersisted.ps1

Thank you for allowing its use :)
- Original Source: https://github.com/PoshCode/Configuration
- Author blog: http://huddledmasses.org/blog/
- Author Twitter: https://twitter.com/jaykul?lang=en
"@ -Parent $license
#endregion Joel Bennet