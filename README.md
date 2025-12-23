# A_MiniFootball

Project Mini Football is an arcade-style mini football game built with Unreal Engine 5.5.

This document is the day-to-day operating guide: how to build, run multiplayer (listen + dedicated), generate UI Widget Blueprints, and work with the input system.

For a shorter “do this first” checklist, see [GUIDE.md](./GUIDE.md).

For Phase 11 manual checks (input init/profiles/rebinding, spectator transitions, MWCS validation), see [TESTING.md](./TESTING.md).

## Overview

- 3v3 team matches (server authoritative)
- Math-based ball movement (no UE physics simulation for the ball)
- Per-player dynamic Enhanced Input via P_MEIS
- UMG UI authored as C++ widgets + deterministic Widget Blueprint generation (MWCS)

## Repo layout

```
A_MiniFootball/
├── Source/                    # Game module
├── Content/                   # Assets
├── Config/                    # Configuration
└── Plugins/
    ├── P_MEIS/               # Input system plugin
    └── P_MiniFootball/       # Football game plugin
        └── Source/
            └── P_MiniFootball/
                └── Base/
                    ├── Core/     # Types, enums
                    ├── Player/   # Controller, character, spectator
                    ├── Ball/     # Ball physics
                    ├── Match/    # GameMode, GameState, Goal
                    ├── Interfaces/ # Team & controller interfaces
                    └── UI/       # Widget classes (13 widgets)
```

## Plugins

- P_MEIS: runtime dynamic Enhanced Input (per-player profiles + mappings)
- P_MiniFootball: gameplay + UI widgets
- P_MWCS (Editor-only): spec-driven Widget Blueprint creation/validation

Plugin docs:

- [Plugins/P_MEIS/README.md](./Plugins/P_MEIS/README.md)
- [Plugins/P_MEIS/GUIDE.md](./Plugins/P_MEIS/GUIDE.md)
- [Plugins/P_MiniFootball/README.md](./Plugins/P_MiniFootball/README.md)
- [Plugins/P_MiniFootball/GUIDE.md](./Plugins/P_MiniFootball/GUIDE.md)
- [Plugins/P_MiniFootball/UI_WIDGETS.md](./Plugins/P_MiniFootball/UI_WIDGETS.md)
- [Plugins/P_MWCS/README.md](./Plugins/P_MWCS/README.md)
- [Plugins/P_MWCS/GUIDE.md](./Plugins/P_MWCS/GUIDE.md)

## Controls (defaults)

These are defaults; they can be changed in-game (Settings → Input):

| Input                              | Action                                        |
| ---------------------------------- | --------------------------------------------- |
| WASD / Left Stick                  | Move                                          |
| Shift / Gamepad Left Trigger       | Sprint                                        |
| Space / Gamepad Face Button Bottom | Action (shoot/pass/tackle depending on state) |
| Q / Gamepad Face Button Top        | Switch player                                 |
| Esc / Gamepad Special Right        | Pause                                         |

Notes:

- This project uses P_MEIS templates persisted under `Saved/InputProfiles/`.
- On first run (if no template exists yet), the gameplay controller can auto-create and apply `Default` via `EnsureInputProfileReady("Default")` so the Settings → Input list is populated automatically.

## Build

Prereqs:

- Unreal Engine 5.5
- Visual Studio toolchain for UE (Desktop development with C++)

Open the project:

- Launch UE and open `A_MiniFootball.uproject`
- Or open the VS solution `A_MiniFootball.sln`

Build targets (typical):

- Editor: Development Editor (for day-to-day iteration)
- Game client: Development / Shipping
- Dedicated server: Development Server (or Shipping Server)

If you’re using VS Code tasks, run the provided build task (Win64 Development build) from the Task Runner.

## Run (packaged)

Once you have a packaged build or built binaries, you can launch with command-line arguments.

Common flags:

- `-log` to show logs
- `-windowed -ResX=1280 -ResY=720` for predictable window size

## Multiplayer runbook

### PIE (fastest)

- In Editor: set “Number of Players” to 2+
- Run PIE

### Listen server (packaged / standalone)

- Host: `A_MiniFootball.exe /P_MiniFootball/Maps/L_MiniFootball?listen -log`
- Client: `A_MiniFootball.exe 127.0.0.1 -log`

## Maps & UI setup (Main Menu vs Gameplay)

This project intentionally separates Main Menu vs Gameplay by using different GameModes / PlayerControllers (avoid map-name branching in code).

### L_MainMenu (menu-only)

- Map: `/P_MiniFootball/Maps/L_MainMenu`
- World Settings overrides:
  - GameMode Override: `BP_MF_MenuGameMode`
  - PlayerController Class: `BP_MF_MenuPlayerController`
- Expected root widget:
  - `/Game/UI/Widgets/WBP_MF_MainMenu`

Note: `AMF_MenuPlayerController` creates the main menu widget in `BeginPlay()` and sets UI-only input mode. The widget class is resolved via project configuration (see `UMF_WidgetClassSettings` in Project Settings, backed by `Config/DefaultGame.ini`) and can optionally be overridden via JSON.

### L_MiniFootball (gameplay)

- Map: `/P_MiniFootball/Maps/L_MiniFootball`
- World Settings overrides:
  - GameMode Override: `BP_MF_GameMode`
  - PlayerController Class: `BP_MF_PlayerController`
- Expected root widget:
  - `/Game/UI/Widgets/WBP_MF_HUD`

Gameplay UI is intended to be spawned by the gameplay PlayerController (Blueprint or C++ subclass). Menu and gameplay UI should not be created from the same controller.

## Run (single player / PIE)

- Open the map `/P_MiniFootball/Maps/L_MiniFootball`
- Play In Editor

Goal setup (if placing goals manually):

- Place `MF_Goal` actors at each end
- Set `GoalTeam` to TeamA / TeamB

## Run (multiplayer listen server)

Two common workflows:

1. PIE multiple clients

- In Editor: set “Number of Players” to 2+
- Run PIE

2. Packaged + launch args

- Start a host instance with `-listen`
- Start clients with `-ExecCmds="open <host_ip>"`

## Run (dedicated server)

The dedicated server should start directly on the gameplay map so clients spawn correctly.

Server map is configured in [Config/DefaultEngine.ini](./Config/DefaultEngine.ini) via `ServerDefaultMap`.

Example commands (adjust exe names/paths to your local build output):

- Server: `A_MiniFootballServer.exe /P_MiniFootball/Maps/L_MiniFootball?listen -log`
- Client: `A_MiniFootball.exe 127.0.0.1 -log`

## Settings → Input (player preferences)

The in-game Settings menu includes a small Input section:

- Toggle vs hold semantics are profile-driven (see `ToggleModeActions`).
- Rebinding is supported via the Input Settings overlay.

Input Settings UX:

- A profile dropdown lets you switch the active template for the local player.
- The **DEFAULT** button resets to the `Default` template.

Implementation note:

- P_MEIS stays generic and does not special-case any action names.
- Action semantics like “this action is toggle-style” are driven by the active input profile data.

## Input system (P_MEIS)

P_MEIS provides per-player input profiles and runtime Enhanced Input objects.

Key points:

- Each local player/controller has its own profile and integration instance.
- UI input (mobile buttons/joystick) injects into P_MEIS so gameplay listens to one unified pipeline.
- Profiles are persisted as JSON under `Saved/InputProfiles/`.

Critical init order (prevents empty Input Settings list):

1. Register/initialize P_MEIS for the local PlayerController.
2. Load/apply a template (typically `Default`) and apply it to Enhanced Input.
3. Only then create Settings UI / open the Input Settings overlay.

Troubleshooting (Settings → Input list is empty):

- Ensure P_MEIS was initialized for that PlayerController.
- In the Input Settings overlay, select a profile (try `Default`) or click **DEFAULT**.
- Verify `Saved/InputProfiles/` contains templates/mappings for the action names your project uses.

Architecture boundary:

- P_MEIS should remain action-name-agnostic. Game/UI code decides which action names exist.
- Profile data includes:
  - `ToggleModeActions`: list of action names that should behave as toggle instead of hold.
  - `ToggleActionStates`: persisted per-action ON/OFF state (map from action name → bool).

## UI widgets (MWCS)

UI Widget Blueprints are generated/validated from C++ widget “specs” (JSON returned by each widget’s `GetWidgetSpec()`).

Typical workflow:

- Edit/implement a widget C++ class (layout spec lives in code)
- Run MWCS validate/create commands in the UE Editor to generate/repair corresponding `WBP_*` assets

Spec parity notes:

- MWCS specs support `Hierarchy`, `DesignerPreview`, `Design` (per-widget properties), and `Dependencies` for round-trip parity (within the supported widget/property set).
- Some `DesignerPreview` values (like zoom/grid) are treated as best-effort editor UX hints and may not persist in all engine versions.

### MWCS commandlets (CI / headless)

P_MWCS provides two commandlets:

- `MWCS_CreateWidgets` (modes: `CreateMissing|Repair|ForceRecreate`)
- `MWCS_ValidateWidgets`

Recommended invocations (Windows):

```bat
Engine\Binaries\Win64\UnrealEditor-Cmd.exe "D:\Projects\UE\A_MiniFootball\A_MiniFootball.uproject" -run=MWCS_CreateWidgets -Mode=ForceRecreate -FailOnErrors -FailOnWarnings -unattended -nop4 -NullRHI -stdout -FullStdOutLogOutput

Engine\Binaries\Win64\UnrealEditor-Cmd.exe "D:\Projects\UE\A_MiniFootball\A_MiniFootball.uproject" -run=MWCS_ValidateWidgets -FailOnErrors -FailOnWarnings -unattended -nop4 -NullRHI -stdout -FullStdOutLogOutput
```

Reports:

- MWCS writes reports to `Saved/MWCS/Reports/MWCS_<Label>_<Timestamp>.json`

If you add a new spec provider class, ensure it’s registered in [Config/DefaultEditor.ini](./Config/DefaultEditor.ini) under `[/Script/P_MWCS.MWCS_Settings] +SpecProviderClasses=...`.

## Troubleshooting

- MWCS creates assets but you don’t see `.uasset` files
  - Run `MWCS_ValidateWidgets` and check the report under `Saved/MWCS/Reports/`.
  - Unsupported widget `Type` values in specs will fail generation.
- Dedicated server starts on the wrong map
  - Confirm `ServerDefaultMap` in [Config/DefaultEngine.ini](./Config/DefaultEngine.ini).
- Input settings aren’t persisting
  - Check the JSON files under `Saved/InputProfiles/` and confirm the profile is being saved.

## License

This project is for educational and personal use.
