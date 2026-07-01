---
name: psframework-testing
description: 'Write and run Pester tests for PSFramework commands and C#-backed cmdlets. Use for new test files, updating assertions, validating LogEntry metadata, and running tests against the local workspace module instead of the installed module.'
argument-hint: 'Command/file under test, expected behavior, and scope (single test file or broader run)'
user-invocable: true
---

# PSFramework Testing

## When To Use
- Add or update tests in PSFramework test folders, especially under PSFramework/tests/functions.
- Validate behavior of commands implemented in C# under library/PSFramework or behaviour of commands implemented in script under PSFramework/functions or PSFramework/internal/functions.
- Run Pester verification in a way that guarantees the local workspace module is used.

## Key Rules
1. Match repository test style.
- Use Describe, Context, It with clear behavioral names.
- Prefer BeforeEach for Clear-PSFMessage when tests inspect message queues.
- Keep assertions specific and stable.

2. Verify behavior through public surfaces.
- Prefer Get-PSFMessage and command outputs instead of internal/private state.
- When verifying command tests through the messages they write, validate LogEntry shape and metadata (Message, LogMessage, Level, Tags, Data, TargetObject, Runspace, FunctionName, ModuleName, File, Line, CallStack, ErrorRecord).

3. Always test against the workspace module build.
- Do not rely on an installed PSFramework module for verification.
- Import from PSFramework/PSFramework.psd1 first.
- If the interactive session has assembly conflicts, run tests in an isolated job process.

## Workflow
1. Inspect implementation and existing tests.
- For C#-based commands, read the command implementation in library/PSFramework/Commands.
- For script-based commands, read the command implementation in PSFramework/functions or PSFramework/internal/functions, including subfolders.
- Read related models in library/PSFramework/Message when asserting logged metadata.
- Mirror neighboring test layout in PSFramework/tests/functions/<area>/.

2. Implement or update tests.
- Create a focused test file named <Command>.Tests.ps1 under the matching function area.
- Add contract tests (parameters/sets) where useful.
- Add behavior tests for happy path, metadata persistence, and edge cases.
- Add at least one behavior test per Parameter Set.

3. Run tests with local-manifest import.
- Preferred command for single-file validation, replacing the path provided to Invoke-Pester with the path to the respective tests file being generated or updated:

```powershell
$job = Start-Job -ScriptBlock {
    Import-Module "c:\Code\github\psframework\PSFramework\PSFramework.psd1" -Force
    $path = (Get-Module PSFramework).Path
    $result = Invoke-Pester -Path "c:\Code\github\psframework\PSFramework\tests\functions\message\Write-PSFMessage.Tests.ps1" -PassThru
    [PSCustomObject]@{
        ModulePath = $path
        Passed = $result.PassedCount
        Failed = $result.FailedCount
        Total = $result.TotalCount
    }
}
Wait-Job $job
Receive-Job $job
Remove-Job $job
```

4. Confirm module provenance in output.
- Verify ModulePath points to the workspace module path, not user/profile module directories.

## Done Criteria
- Tests are readable and consistent with nearby repository tests.
- Assertions verify externally observable behavior.
- Verification run is executed with local module import from PSFramework.psd1.
- Report includes pass/fail counts and loaded module path.
