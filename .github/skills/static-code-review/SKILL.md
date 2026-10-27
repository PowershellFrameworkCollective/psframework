---
name: static-code-review
description: 'Perform evidence-based static code reviews for bugs, technical errors, security vulnerabilities, and performance or scaling risks without executing project code. Use when asked to review, audit, inspect, or assess a PowerShell module, Azure integration, build pipeline, or repository through read-only analysis.'
argument-hint: 'Optionally specify files, folders, categories, or a strict no-execution constraint'
user-invocable: true
---

# Static Code Review

Review code through read-only analysis and report actionable findings before summaries. Prioritize defects that affect correctness, safety, security, or behavior at scale.

## Scope And Constraints

- Respect the files, symbols, categories, and depth requested by the user.
- When no scope is supplied, cover all functions, module initialization, manifests, build and release paths, and relevant tests.
- Do not edit files during a review unless the user separately asks for fixes.
- In strict no-execution mode, do not run or import project code, scripts, modules, tests, builds, linters, analyzers, parsers, package managers, or cloud operations.
- In strict no-execution mode, use only read-only file listing, file reading, text or semantic search, read-only exploration agents, repository history when needed, and authoritative documentation lookup.

## Review Procedure

1. Establish the review boundary and execution constraints from the request.
2. Inventory the smallest set of public entry points that represents the requested surface.
3. Trace each entry point to the code that directly constructs requests, mutates state, transforms data, resolves identity or configuration, or controls error and confirmation behavior.
4. Inspect the module loader, manifest, build pipeline, and published-artifact assembly path. Distinguish source-tree behavior from generated release behavior.
5. Inspect tests for behavioral coverage of the reviewed paths. Do not treat a missing test as a defect unless it leaves a concrete finding unprotected.
6. Compare external request paths, API versions, body shapes, query parameters, enumerations, and response assumptions with authoritative vendor documentation.
7. Search for security-sensitive behavior: destructive operations, confirmation bypasses, credential or token exposure, command or expression evaluation, mutable remote scripts, untrusted input crossing trust boundaries, and overly broad exports.
8. Search for scaling behavior: repeated remote enumeration, per-item authentication or resolution, client-side filtering after broad list calls, missing pagination handling, unbounded materialization, and nested work whose cost grows with input size.
9. Validate every candidate against nearby code, language semantics, build transformations, and external contracts. Remove findings that depend only on style, convention, or an unverified assumption.
10. Report findings in descending severity with exact file and line references, impact, static evidence, and the condition that triggers the problem.

## PowerShell Checks

- Verify advanced functions that mutate state declare `SupportsShouldProcess` and pass `$PSCmdlet` through wrappers that implement `ShouldProcess`.
- Trace whether `-WhatIf` and `-Confirm` reach the actual mutating operation rather than relying on help text or naming.
- Check parameter mandatory status, parameter sets, validation attributes, aliases, default values, pipeline binding, and variable mutation across `begin`, `process`, and `end`.
- Inspect list commands for wildcard routing, pagination, server-side versus client-side filtering, and subscription-wide enumeration.
- Inspect manifests together with `Export-ModuleMember` and build-time manifest rewriting before claiming that internal functions are exported.
- Inspect build scripts for incorrect source paths, omitted classes or enums, cleanup that removes uncompiled sources, and differences between local and published modules.
- Do not claim that accessing a property such as `$null.Keys` throws unless strict mode or the actual runtime semantics make that true.

## API Interaction Checks

- Check request URI construction for missing resource segments, accidental collection endpoints, invalid interpolation, and path/query values derived from unchecked input.
- Check request bodies against the selected API version, including property nesting, read-only fields, enum values, conditional properties, and service-specific types.
- Verify service or cloud mappings are propagated to every request and helper call rather than replaced with hard-coded defaults.
- Check converters for assumptions about resource ID shape, null input, collection responses, and property availability.

## Candidate Validation

Before reporting a finding, answer all of the following:

- What exact input, configuration, or call path reaches it?
- What observable failure, security impact, or scaling cost follows?
- Which line directly causes the behavior?
- Is the claim confirmed by local language semantics or an authoritative external contract?
- Could a wrapper, build step, generated artifact, dependency behavior, or later guard invalidate the claim?
- Is this a defect rather than a preference, hardening suggestion, or documentation issue?

If any answer is missing, investigate one nearby hop or downgrade the item to an explicit risk or open question. Do not present speculation as a confirmed defect.

## Severity

- **Critical**: Prevents parsing, loading, building, or publishing the primary artifact; enables direct compromise; or causes catastrophic unintended mutation.
- **High**: Breaks a core operation, bypasses an expected safety control, creates a practical security vulnerability, or sends materially invalid external requests.
- **Medium**: Breaks an optional feature or common edge case, creates misleading behavior with operational impact, or scales poorly under realistic load.
- **Low**: Limited correctness defect, hardening opportunity, or performance issue with a narrow trigger and small impact.

Do not inflate severity merely because code calls a cloud API or performs deletion. Base severity on reachability and impact.

## Reporting Format

Lead with findings, ordered by severity. For each finding include:

1. A concise impact-oriented title.
2. A clickable file and line reference.
3. The triggering path or input.
4. The resulting behavior and why it matters.
5. The decisive static evidence or external contract.

After findings, include only relevant open questions, then a short review summary covering:

- areas reviewed;
- whether confirmed security or scaling defects were found;
- test gaps tied to reported findings;
- the no-execution limitation.

If no actionable findings remain after validation, say so clearly and identify residual risks or unreviewed boundaries. Avoid padding the report with style observations.