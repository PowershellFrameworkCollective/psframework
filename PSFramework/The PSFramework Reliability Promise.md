# The PSFramework Reliability Promise
## About

The PSFramework is designed as a platform for others to build their code upon.
As such, there is a special need for reliability and stability of code.
This is my promise on how I ensure it is safe to use and safe to rely upon.

## Supported Platforms

This module is supported on:

 - Windows PowerShell 3+ (And Windows 6.1 and later)
 - PowerShell Core 6.0+ (Any OS; Stable Release only)
 - PowerShell Core 6.0+ (Any OS; Preview support; Limited support only*)

*Generally, Platform compatibility issues take top priority, having me drop any other issues to fix them.
For preview editions of PowerShell Core this priority may not apply.

## No breaking change (?)

The greatest risk to relying on foreign code is that that code might introduce a breaking change, thereby breaking your code without you doing anything but deploying a latest version of it.

Therefore, my one greatest promise is this:

> No Breaking Changes*

That is, if a feature has reached deployment stage, I will not introduce breaking changes whatsoever, except for under some very limited and constrained circumstances.
And even then I'll try not to if I somehow can.

## Coverage

Now what is covered by this promise:

 - All functions and cmdlets signatures. Any current parameterization will keep being valid and produce the same result.
 - All logging providers. Configuration and default behavior cannot be changed.
 - All parameter classes will keep understanding current input (they may _also_ learn to understand new input)
 - All validation attributes will keep accepting the current definition (but new definitions may be introduced)
 - Any otherwise advertised feature on the [documentation site](https://psframework.org/documentation/documents/psframework.html)

Not covered by this promise:

 - Preview features. All new commands that are being released are considered to be in preview for one month. This is designed to allow for initial user feedback to be implemented. Note: This only applies to the initial command release, _not_ to any later updates that were made after the preview stage was over.
 - Any other internal library mechanics. Some of them need to be public for script functions to access them. That does _not_ imply they are for public consumption (You may use them for that, but at your own risk).
 - UI User Interaction. Messages written to the host intended for a human consumption may be changed in how they are being displayed. The previous state however must be available using configuration (thus changes to the _default_ behavior can be made, as long as the old state can be reintroduced).
 - Experimental features. Any feature listed as experimental below is considered to be exempt from this policy.
 - System mandated change: If a feature needs to be adapted in order for it to be operable on all supported platforms (for example an active conflict with PowerShell Core), then that is an overriding technical need to change it.
 - A feature undergoing the Process of Change.

## Process of Change

One of the great limitations of a "No Breaking Change" policy is that in some few cases, keeping to support the old ways incurs a penalty, a cost.
Whether that is hurt performance or undesired environment impact.
In order to not fully prevent improvement in those scenarios, there shall be implemented a public change process:

For each desired breaking change, an RFC most be posted as an issue, describing the reason for this change and the benefits it brings.
This RFC will be open for discussion for three months.
If these three months pass and no convincing argument against it have been brought forward, the suggested change will be marked as a pending change:

 - The way of operation that will be broken by that change will be declared deprecated.
 - The affected feature will be updated to include a warning if a deprecated way of using it is detected, to warn about the impeding change.
 - On Windows Systems, use of a deprecated functionality will generate a warning eventlog event in the PowerShell Eventlog (ID: 666; Category: 1; EntryType: Warning; Source: PowerShell)
 - Nine months after the RFC is approved, the breaking change may be implemented.

## Pending Change

There are currently no breaking changes pending

## Experimental features

There currently are no experimental features in the PSFramework