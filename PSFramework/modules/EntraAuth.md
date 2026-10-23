# EntraAuth

> Source

https://github.com/FriedrichWeinmann/EntraAuth

> Purpose

Used in the Azure LogAnalytics (v2) Logging Provider.

> Adjustments

Removed Format-XML file and its reference in the module manifest.
No human is ever going to see the objects from this module, no need to risk a conflict with other EntraAuth versions loaded into the main runspace.
