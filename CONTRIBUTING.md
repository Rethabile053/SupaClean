# Contributing to SupaClean

## Branches

| Branch | Purpose | Who pushes |
| --- | --- | --- |
| `main` | Stable, demo-ready code only | Nobody pushes directly. Changes come in through a PR from `develop` |
| `develop` | Integration branch for finished features | Nobody pushes directly. Changes come in through PRs from feature branches |
| `dev-flutter` | Flutter app work for the whole team | **Anyone on the team pushes directly.** No pull request or review needed |
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

### Working on `dev-flutter` (Flutter team)

Everyone works on the same branch, so keep it moving:

```bash
git checkout dev-flutter
git pull --rebase origin dev-flutter   # always before you start and before you push
# ...make a small change...
git add <the files you changed>
git commit -m "feat: add notification cards"
git push origin dev-flutter
```

- Pull before you push, so you never overwrite a teammate's work.
- If the push is rejected, run `git pull --rebase origin dev-flutter` again and push.
- Run `flutter analyze` and `flutter test` before pushing, so the branch always builds.
- Merging `dev-flutter` into `develop` and `main` still goes through a PR.

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

- The team uses **Flutter 3.47.7 (stable, Dart 3.13.5)**. The version is also recorded in [`.fvmrc`](.fvmrc).
- Check yours with `flutter --version`.
  - Older? Run `flutter upgrade`.
  - Newer? Run `flutter downgrade 3.47.7`, or use [FVM](https://fvm.app): `fvm use` in the repo root picks up `.fvmrc` automatically.
- Upgrading the team's Flutter version is a decision for the whole team: one person upgrades, runs `flutter pub get`, updates `.fvmrc` and this section, and opens a PR. Everyone else upgrades after it is merged.
- Only commit changes to `pubspec.lock` together with a change to `pubspec.yaml` (i.e. when you actually add or upgrade a package).
  To throw away an accidental change: `git restore flutter/supaclean_app/pubspec.lock`

## Never commit

- `.dart_tool/`, `build/`, `bin/`, `obj/` (generated)
- `.env` files, API keys, Supabase service-role keys
- Editor files such as `*.code-workspace` or `.idea/`
