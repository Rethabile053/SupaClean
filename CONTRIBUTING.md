# Contributing to SupaClean

## Branches

| Branch | Purpose | Who pushes |
| --- | --- | --- |
| `main` | Stable, demo-ready code only | Nobody pushes directly. Changes come in through a PR from `develop` |
| `develop` | Integration branch for finished features | Nobody pushes directly. Changes come in through PRs from feature branches |
| `feature/<short-name>` | One feature, e.g. `feature/profile-screen` | The feature owner |
| `fix/<short-name>` | A bug fix | The person fixing it |
| `chore/<short-name>` | Repo housekeeping, docs, config | Anyone |

## Workflow

1. Update your local `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   ```
2. Create your branch from it:
   ```bash
   git checkout -b feature/order-tracking
   ```
3. Commit small, focused changes (see the commit message rules below).
4. Before pushing, **check what you are committing**:
   ```bash
   git status
   git diff --staged --stat
   ```
   If you see files deleted that you did not mean to delete, or anything inside `.dart_tool/`, `build/`, `bin/` or `obj/`, stop and fix it before committing.
5. Push and open a Pull Request **into `develop`** (not `main`).
6. At least one other team member reviews before merging.
7. Delete the feature branch after it is merged.

## Commit messages

Use the form `<type>: <what changed>`, written in the imperative:

```
feat: add profile screen
fix: show error when login email is invalid
docs: update README tech stack table
chore: ignore .dart_tool folders
```

Avoid messages like `first commit`, `update`, or `profiles`.

## Flutter version

Everyone must use the same Flutter version, otherwise `pubspec.lock` changes every time someone runs `flutter pub get`.

- The project was created with Flutter **stable**, framework revision `9f455d2486` (see `flutter/supaclean_app/.metadata`).
- Check yours with `flutter --version`.
- Only commit changes to `pubspec.lock` together with a change to `pubspec.yaml` (i.e. when you actually add or upgrade a package).
  To throw away an accidental change: `git restore flutter/supaclean_app/pubspec.lock`

## Never commit

- `.dart_tool/`, `build/`, `bin/`, `obj/` (generated)
- `.env` files, API keys, Supabase service-role keys
- Editor files such as `*.code-workspace` or `.idea/`
