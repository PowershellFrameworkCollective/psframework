# psframework
A module that provides tools for other modules and scripts

# Objective
Welcome to the psframework project.
The design goal is to create a framework specific to powershell scripting in general. It provides infrastructure for generic scripting tasks, such as:
 - configuration management
 - logging
 - optimizing the user experience
 - improving manageability of PowerShell

 # Getting Started
 ## Installation
 In order to get started with the latest production build, simply run this in an elevated console:
 ```powershell
 Install-Module PSFramework
 ```
 This will install the module on your system, ready for use
 
 ## A quick peek into logging
 After installing the PSFramework, simply replace all instances of ...
 ```powershell
 Write-Verbose "<whatever>"
 ```
 ... with ...
 ```powershell
 Write-PSFMessage "<Whatever>"
 ```
 It will still write to verbose, but also ...
  - Write to a log in your appdata folder
  - Automatically rotate old or too large logs
  
## More guidance
All of the upcoming documentation will also be hosted at the [official PSFramework website](https://psframework.org), existing documentation shall be copied to also be available there.

The PSFramework project has a related slack community, where everybody is free to join, ask questions or discuss practices. For a free invite, check our [Contact](https://psframework.org/general/contact.html) page

The PSFramework comes with lots of internal documentation.
All functions ship with help and examples and there are quite a few concept help articles:
```powershell
Get-Help about_psf*
```
(Note: Some of them are not quite done yet)
Finally, I also like to [write in my blog](https://allthingspowershell.blogspot.de) about the PSFramework and all my other projects.
