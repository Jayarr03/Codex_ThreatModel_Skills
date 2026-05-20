# Script Review Checklist

Use this checklist when the script performs risky operations or when the first pass suggests non-trivial issues.

## Input to Execution

- Check whether user-controlled data can reach shell commands, subprocess arguments, SQL, templates, interpreters, regular expressions, or dynamic module loading.
- Check whether quoting, escaping, allowlisting, or structured argument passing removes the risk.
- Check whether environment variables can unexpectedly influence execution.

## Filesystem Safety

- Check for path traversal through joins, string concatenation, archive extraction, or user-provided filenames.
- Check temp-file creation for predictable names, unsafe permissions, race windows, and missing cleanup.
- Check destructive operations such as deletion, overwrite, chmod, chown, and move for guardrails, dry-run support, and scope validation.
- Check symlink handling when writing to shared or attacker-controlled locations.

## Secrets and Authentication

- Check for hardcoded credentials, tokens in URLs, secrets written to logs, and secret values passed to subprocesses without need.
- Check whether auth or authorization decisions rely on weak client-side or environment-side assumptions.
- Check whether sensitive data is redacted in error messages and reports.

## Network and Supply Chain

- Check for disabled certificate verification, weak TLS settings, plain HTTP for sensitive operations, and unverified redirects.
- Check for downloads that are executed or unpacked without integrity verification.
- Check whether the script implicitly trusts tools, plugins, packages, or remote endpoints without pinning or provenance.

## Reliability and Failure Handling

- Check whether every important command or API call verifies success and surfaces failure.
- Check whether cleanup and rollback paths run reliably on early exit or interruption.
- Check whether retries are bounded and whether backoff, timeout, and cancellation behavior are safe.
- Check whether the script can exhaust disk, memory, CPU, or API quotas through unbounded loops or inputs.

## Design Smells Worth Reporting

- Flag surprising side effects during import or startup.
- Flag mixed responsibilities that blur validation, execution, and reporting.
- Flag implicit defaults that could become dangerous in production.
- Flag missing auditability for scripts that change infrastructure, files, permissions, or external systems.
