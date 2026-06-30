# Contributing To FlowType

FlowType is a Windows desktop dictation app. Contributions should preserve the product direction:

- local transcription first
- optional cleanup with the user's own provider key
- reliable paste into the active app
- privacy-first defaults
- polished Windows UX

## Development Setup

FlowType uses [uv](https://docs.astral.sh/uv/) with Python 3.11 or 3.12 on Windows.

```powershell
uv sync                      # create the env and install deps
uv run python -m flowtype    # run the app
```

(Plain pip works too: `python -m pip install -e .[dev,build]`.)

Run the test and compile checks before opening a PR:

```powershell
uv run python -m pytest
uv run python -m compileall src tests scripts
```

## Packaging

Build the branded Windows bundle, and optionally the installer:

```powershell
uv run python scripts/build.py
uv run python scripts/build.py --installer
```

The packaged smoke checklist is in [docs/PACKAGED_SMOKE_CHECKLIST.md](docs/PACKAGED_SMOKE_CHECKLIST.md).

## Bug Fix Workflow

If you fix a bug:

1. Reproduce it first.
2. Add or update a focused test when practical.
3. Verify the app path that actually matters:
   - local transcription
   - cleanup fallback
   - paste behavior
   - tray/background lifecycle
4. Keep UI changes consistent with the current product direction.

## Updating Installed Builds

There is no auto-updater yet.

- End users install the next released installer over the previous build.
- User data remains under `%APPDATA%\FlowType`.
- Contributors running from source just pull the latest code and relaunch.

## Reporting Issues

Include:

- exact steps to reproduce
- expected behavior
- actual behavior
- target app where paste failed, if relevant
- log excerpt from `%APPDATA%\FlowType\logs`
- whether cleanup provider was configured
- whether the app was run from source or from the packaged installer
