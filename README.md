# Codex Skills

This repository contains custom skills for Codex.

Each skill is a folder with a required `SKILL.md` file and, optionally:

- `agents/openai.yaml`
- `references/`
- `scripts/`
- `assets/`

## What These Skills Are For

These skills extend Codex with reusable workflows, review patterns, and task-specific guidance. A skill can be invoked explicitly in a prompt with `$skill-name`, or it may be selected implicitly when a request closely matches the skill description.

Example:

```text
Use $github-repo-data-flow-review to inspect this repository and build a basic data flow model for the login flow.
```

## Repository Layout

Each top-level folder in this repo should be a standalone skill directory.

Example:

```text
github-repo-data-flow-review/
  SKILL.md
  agents/
  references/
```

## Install

### Option 1: Clone the repo and copy skills into Codex

Clone this repository:

```bash
git clone <your-repo-url>
cd <your-repo-folder>
```

Copy one or more skill folders into your local Codex skills directory:

```bash
cp -R github-repo-data-flow-review "${CODEX_HOME:-$HOME/.codex}/skills/"
```

### Option 2: Install all skills from the repo

If every top-level folder in the repo is a skill, copy them all:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R ./* "${CODEX_HOME:-$HOME/.codex}/skills/"
```

If your repo also contains files like `README.md` or `.gitignore`, copy only the skill directories you want instead of using the bulk command above.

### Option 3: Manual install

1. Open your Codex skills directory:
   `${CODEX_HOME:-$HOME/.codex}/skills`
2. Copy a skill folder into it.
3. Restart or reload Codex if the skill does not appear immediately.

## Using a Skill

Invoke a skill directly in your prompt with its `name` from `SKILL.md`.

Example:

```text
Use $github-repo-data-flow-review to map the webhook processing flow in this repository.
```

A few important rules:

- The skill folder name should match the skill `name` in `SKILL.md`.
- Skill names should use lowercase letters, digits, and hyphens only.
- If you rename a skill, update both the folder name and the `name:` field in `SKILL.md`.

## Troubleshooting

If a skill does not show up:

1. Confirm the skill folder exists under `${CODEX_HOME:-$HOME/.codex}/skills`.
2. Confirm the folder contains `SKILL.md`.
3. Confirm the `name:` field in `SKILL.md` matches the intended invocation name.
4. Reload or restart Codex or VS Code.
5. Try explicit invocation with `$skill-name` even if it does not appear in a picker.

## Example Skill

This repo includes:

- `github-repo-data-flow-review`

Use it like this:

```text
Use $github-repo-data-flow-review to inspect this repository and build a basic data flow model, including the functions involved at each step.
```
