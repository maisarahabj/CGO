# CampusGO Development Cheat Sheet

Keep this file in the **project root**, beside `pubspec.yaml` and `README.md`.
Run all commands below from that same project root.

```text
cs_go/
├── android/
├── ios/
├── lib/
├── test/
├── DEVELOPMENT_CHEATSHEET.md
├── pubspec.yaml
└── README.md
```

## The normal development cycle

The safest routine after completing a group of code changes is:

```bash
dart format .
flutter analyze
flutter test
flutter run
```

These commands do different jobs:

| Command | Purpose | When to run it |
|---|---|---|
| `dart format .` | Corrects Dart formatting throughout the project. The `.` means the current project folder. | After changing Dart files and before committing. |
| `flutter analyze` | Finds code errors, invalid imports, type problems, and warnings without launching the app. | After formatting and before testing. |
| `flutter test` | Runs the automated tests inside `test/`. | After analysis passes and before committing. |
| `flutter run` | Builds and launches the application on a selected emulator, simulator, or device. | When you need to inspect or manually test the app. |

Do not type only `dart format`. Give it a target:

```bash
dart format .
```

To format only the application code:

```bash
dart format lib
```

## When to run `flutter pub get`

`pubspec.yaml` is the project's dependency and asset configuration file.
`flutter pub get` reads that file, downloads the required packages, resolves
compatible versions, and updates Flutter's local package information.

Run it after:

- cloning the project for the first time;
- pulling changes that modified `pubspec.yaml` or `pubspec.lock`;
- adding, removing, or changing a dependency;
- adding or changing asset or font declarations in `pubspec.yaml`;
- running `flutter clean`.

```bash
flutter pub get
```

You usually do **not** need it after changing only Dart layout, colours, text,
navigation callbacks, models, controllers, or ordinary application logic.

The message below is a success:

```text
Got dependencies!
```

A notice saying that newer package versions exist does not mean the command
failed. Do not upgrade packages only to remove that notice.

### Adding a package

Prefer letting Flutter update `pubspec.yaml` for you:

```bash
flutter pub add package_name
```

Example:

```bash
flutter pub add flutter_svg
```

Then import and use the package in Dart. Do not edit `pubspec.lock` manually.

### Removing a package

```bash
flutter pub remove package_name
```

## What to run after each kind of change

| What changed? | Commands to run next |
|---|---|
| Dart UI, navigation, model, controller, or service code | `dart format .` → `flutter analyze` → `flutter test` |
| `pubspec.yaml` dependency | `flutter pub get` → `dart format .` → `flutter analyze` → `flutter test` |
| Asset or font files and their `pubspec.yaml` declarations | `flutter pub get` → stop and rerun the app |
| Native Android or iOS configuration | Stop the app → rebuild with `flutter run` |
| Test files only | `dart format test` → `flutter test` |
| Changes pulled from another branch | Check whether `pubspec.yaml` changed; if it did, run `flutter pub get`, then analyze and test |
| Strange stale build problem | `flutter clean` → `flutter pub get` → `flutter run` |

`flutter clean` is not part of the everyday routine. It deletes generated build
files, so the next build will take longer. Use it only when Flutter appears to
be using stale generated files or a normal rebuild does not solve a build issue.

## While `flutter run` is active

The terminal running Flutter accepts these keys:

| Key | Meaning | Best use |
|---|---|---|
| `r` | Hot reload | Small Dart UI or logic changes while preserving the current app state |
| `R` | Hot restart | Changes to startup code, state initialization, dependency injection, or when hot reload does not update correctly |
| `q` | Quit | Stops the running application |
| `h` | Help | Shows all available run commands |

Use `Ctrl + C` if you need to stop the running terminal process directly.

A full stop and rerun is safer after changing:

- `pubspec.yaml`;
- assets or fonts;
- `main.dart` initialization;
- Supabase initialization;
- Android or iOS native configuration;
- packages with native platform code.

## Running on a particular device

List available devices:

```bash
flutter devices
```

Run on a selected device:

```bash
flutter run -d DEVICE_ID
```

General environment check:

```bash
flutter doctor
```

`flutter doctor` diagnoses the Flutter installation. It does not test CampusGO's
application logic.

## Git: start of a work session

Each CampusGO team member should work on their assigned feature branch, not
directly on `main`.

First, enter the project folder and confirm the current branch:

```bash
cd /path/to/cs_go
git status
git branch --show-current
```

Switch to your own branch:

```bash
git switch your-branch-name
```

Download the latest remote information and update that branch:

```bash
git fetch origin
git pull origin your-branch-name
```

If `git status` shows uncommitted work, do not switch branches or pull blindly.
Commit the work, or ask the team how it should be handled first.

## Creating a feature branch for the first time

Begin from an updated `main`:

```bash
git switch main
git pull origin main
git switch -c feature/feature-name
git push -u origin feature/feature-name
```

Examples:

```text
feature/home-navigation
feature/timetable
feature/bookings
feature/notifications
feature/settings
```

The `-u` connects the local branch to its matching remote branch. After the
first push, ordinary `git push` and `git pull` will know which branch to use.

## Git: after making changes

Before saving changes to Git, verify the code:

```bash
dart format .
flutter analyze
flutter test
```

Then inspect what will be committed:

```bash
git status
git diff
```

Stage the intended files:

```bash
git add .
```

Commit with a short description of the completed change:

```bash
git commit -m "Connect sidebar routes"
```

Push the branch:

```bash
git push
```

The complete routine is:

```bash
dart format .
flutter analyze
flutter test
git status
git diff
git add .
git commit -m "Describe the completed change"
git push
```

Do not commit simply because the app launches. Formatting, analysis, and tests
check different kinds of problems.

## Bringing the newest `main` into your feature branch

Do this on your feature branch before opening the final pull request, especially
if other features have recently been merged:

```bash
git status
git fetch origin
git merge origin/main
```

Then run:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

`flutter pub get` is included here because another team member may have changed
the dependencies. If Git reports a merge conflict, do not guess or delete one
side automatically. Open each conflicted file, decide how both features should
coexist, then test the combined code before committing the merge.

## Pull request and merge flow

The recommended team flow is:

```text
main
  └── feature/member-feature
        ├── develop and test
        ├── commit and push
        ├── open a pull request into main
        ├── review and resolve conflicts
        └── merge after checks pass
```

After the pull request is merged, every other team member should update their
own feature branch from the new `main` before continuing integration work.

## Useful inspection commands

Show the current status:

```bash
git status
```

Show the current branch:

```bash
git branch --show-current
```

Show local branches:

```bash
git branch
```

Show recent commits:

```bash
git log --oneline --decorate -10
```

Show unstaged code differences:

```bash
git diff
```

Show staged differences:

```bash
git diff --staged
```

## Common situations

### Opening CampusGO again tomorrow

```bash
cd /path/to/cs_go
git switch your-branch-name
git status
git pull
flutter run
```

Run `flutter pub get` first only if dependencies or `pubspec.yaml` changed, or
if Flutter tells you that packages need to be resolved.

### You changed ordinary Dart code

```bash
dart format .
flutter analyze
flutter test
```

If the app is already running, use `r` or `R`. Otherwise use `flutter run`.

### You added an SVG or image

1. Put the file in the correct `assets/` feature folder.
2. Declare its folder or exact path under `flutter: assets:` in `pubspec.yaml`.
3. Run:

```bash
flutter pub get
flutter run
```

If an asset is declared but Flutter cannot find it, check spelling, uppercase
and lowercase letters, indentation in `pubspec.yaml`, and the exact file path.

### `flutter analyze` reports an error

Read the first error, fix it, and run `flutter analyze` again. Later errors can
be consequences of the first one.

### `flutter test` fails but `flutter run` works

The app and the tests start in different environments. For example, the real
app initializes Supabase in `main.dart`, while a widget test may construct
`CampusGoApp` directly. A test should use controlled fake or mock services
instead of relying on an authenticated simulator session. Do not ignore the
test failure merely because the application launches.

### Flutter appears stuck on `Running Xcode build`

The first iOS build, a build after package changes, or a build after cleaning
can take several minutes. If the terminal is still producing normal build
output and has not displayed an error, let it continue.

## Files that normally belong in Git

Commit application source and project configuration, including:

```text
lib/
test/
assets/
pubspec.yaml
pubspec.lock
README.md
DEVELOPMENT_CHEATSHEET.md
```

Do not commit generated build folders, temporary files, IDE caches, passwords,
private keys, or unprotected secret files. Follow the project's `.gitignore`.

## Short version to remember

For an ordinary completed code change:

```bash
dart format .
flutter analyze
flutter test
git add .
git commit -m "Describe the change"
git push
```

Add `flutter pub get` before those commands when `pubspec.yaml`,
`pubspec.lock`, dependencies, assets, or fonts changed. Use `flutter run` when
you want to launch and manually inspect the app.
