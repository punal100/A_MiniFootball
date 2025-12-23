# A_MiniFootball Guide

This is the quick checklist for building and running the project.

## 1) Open + build

- Open `A_MiniFootball.uproject` in Unreal Engine 5.5.
- Build the **Development Editor** target (from UE or Visual Studio).

If you’re using VS Code, run the provided build task (Win64 Development).

## 2) Play In Editor (PIE)

- For menu flow: open `/P_MiniFootball/Maps/L_MainMenu` and press Play.
- For gameplay-only: open `/P_MiniFootball/Maps/L_MiniFootball` and press Play.

Map setup (recommended):

- `L_MainMenu`: GameMode `BP_MF_MenuGameMode`, PlayerController `BP_MF_MenuPlayerController` (spawns the configured Main Menu widget).
- `L_MiniFootball`: GameMode `BP_MF_GameMode`, PlayerController `BP_MF_PlayerController` (gameplay PC is responsible for spawning `WBP_MF_HUD`).

## 3) Multiplayer (fastest route)

- In the Editor, set “Number of Players” to 2+.
- Run PIE.

## 4) Dedicated server (local)

- Ensure `ServerDefaultMap` is set to `/P_MiniFootball/Maps/L_MiniFootball` in `Config/DefaultEngine.ini`.
- Launch a server build on that map, then connect a client.

## 5) Input + UI notes

- Gameplay listens to P_MEIS events.
- Mobile UI (virtual joystick/buttons) injects into P_MEIS so keyboard/gamepad and UI share the same gameplay path.
- User input profiles persist to `Saved/InputProfiles/` as JSON.

Critical init order (prevents empty Input Settings list):

- Initialize P_MEIS for the local PlayerController and load/apply a template (typically `Default`) **before** opening Settings → Input.
- If you are creating UI manually, do it after input initialization so the widget can enumerate bindings.

In this project, the gameplay player controller (`AMF_PlayerController`) exposes a one-call helper:

- `EnsureInputProfileReady("Default")`

It will:

- Register the local player with P_MEIS (if needed)
- Create `Saved/InputProfiles/Default.json` if it doesn't exist yet
- Apply the template to the local player (and apply to Enhanced Input)

Troubleshooting (Settings → Input list is empty):

- Confirm P_MEIS integration initialized for that PlayerController.
- Use the Profile dropdown and select `Default` (or click DEFAULT).
- Check `Saved/InputProfiles/` exists and contains your templates.

## 6) Widget Blueprint generation (MWCS)

- Widget Blueprints (`WBP_*`) are generated from each widget’s `GetWidgetSpec()` JSON.
- Run MWCS “create/validate widgets” tools inside the Unreal Editor to regenerate assets after changing specs.

Headless / CI examples (Windows):

```bat
Engine\Binaries\Win64\UnrealEditor-Cmd.exe "D:\Projects\UE\A_MiniFootball\A_MiniFootball.uproject" -run=MWCS_CreateWidgets -Mode=ForceRecreate -FailOnErrors -FailOnWarnings -unattended -nop4 -NullRHI -stdout -FullStdOutLogOutput

Engine\Binaries\Win64\UnrealEditor-Cmd.exe "D:\Projects\UE\A_MiniFootball\A_MiniFootball.uproject" -run=MWCS_ValidateWidgets -FailOnErrors -FailOnWarnings -unattended -nop4 -NullRHI -stdout -FullStdOutLogOutput
```

Reports are written to `Saved/MWCS/Reports/`.

Spec helper (optional):

- In **Tools → MWCS**, use **Extract Selected WBP** to export a selected Widget Blueprint’s hierarchy to JSON.
- Output is written to `Saved/MWCS/ExtractedSpecs/` and copied to clipboard.

MWCS parity note:

- MWCS build + extract + validate are aligned around the supported parity set: `DesignerPreview`, `Hierarchy`, `Design`, and best-effort `Dependencies`.
- Sections like `Bindings`, `Delegates`, `Comments`, and `PythonSnippets` are treated as write-only / non-extractable.

## 7) Manual testing (Phase 11)

For a consolidated manual test checklist (input init, profiles, spectator/team transitions, rebinding, multiplayer), see [TESTING.md](./TESTING.md).

## Where to read more

- P_MEIS: [Plugins/P_MEIS/GUIDE.md](./Plugins/P_MEIS/GUIDE.md) and [Plugins/P_MEIS/README.md](./Plugins/P_MEIS/README.md)
- P_MiniFootball: [Plugins/P_MiniFootball/GUIDE.md](./Plugins/P_MiniFootball/GUIDE.md) and [Plugins/P_MiniFootball/README.md](./Plugins/P_MiniFootball/README.md)
- P_MWCS: [Plugins/P_MWCS/GUIDE.md](./Plugins/P_MWCS/GUIDE.md) and [Plugins/P_MWCS/README.md](./Plugins/P_MWCS/README.md)
