# Technical report

**Engine:** Godot 4.8, GDScript, Compatibility renderer. The 3D environment, models, UI and sound are generated at runtime. The game uses Godot's high-level multiplayer API over ENet.

## A. Networking model

The host creates the ENet server and also plays as peer 1; up to seven clients join by IPv4 address and UDP port. After connection, each client sends its name to peer 1. Only the server assigns a free spawn slot, records the player, and calls `MultiplayerSpawner.spawn()`. Spawn data contains peer ID, name and slot. The spawner reproduces the same named player nodes on clients and supplies existing spawns to a late joiner. Disconnect removes the server's player node and roster entry; clients return to the menu if the host leaves. Every networked node uses its own `multiplayer` property, which also permits separate `SceneMultiplayer` instances in the two-viewport test.

## B. Player synchronisation

The player's `MultiplayerSynchronizer` continuously replicates `sync_position`, `sync_yaw` and `sync_speed` (see `scenes/player.tscn`). Its owning peer reads input, runs `move_and_slide()` each physics frame, and writes those properties. Remote copies interpolate position and model yaw each physics frame (`delta × 12` blend), snapping when the positional gap exceeds 5 m. Synced speed drives local walk animation without sending limb poses. The synchronizer's continuous mode transmits changes according to Godot's replication scheduling; the project does not promise a fixed packet rate. Match timer corrections are sent about once per second, while each client counts down locally between them.

## C. Ownership and authority

Player node names equal their peer IDs. `RacePlayer.setup()` sets multiplayer authority to that peer before entry into the scene tree, including the `Sync` child. Only the owner creates a player camera and processes keyboard/mouse movement. The server owns `MatchController`, the spawner and all rules: ready/start eligibility, light cycle, red-light judging, finish order, timeouts, wins and shoves. Requests identify the sender from the multiplayer RPC context and are checked against the roster and phase. The server validates shove reach and cooldown, then sends the impulse to the target owner. Owner-authoritative movement is responsive on a LAN and avoids waiting for every input round trip. It lets a modified client falsify position; anti-cheat movement validation is outside this LAN prototype.

## D. Shared game state

The server reliably broadcasts full roster snapshots (name, slot, ready, status, place, elapsed finish time, wins), phase, light, reset and gameplay events. The clock correction RPC is unreliable because the next update replaces a lost one. On a mid-round join, `sync_to_peer()` sends that client the current roster, phase, remaining time and light; the new runner is marked `SPECTATING` until the next round. For red-light judging, the server waits 0.3 s, captures alive runners' synced positions, and eliminates a runner that moves more than 0.4 m horizontally from its snapshot. Vertical movement alone is ignored, and a client's first arriving pose can establish its snapshot. Results last eight seconds before a reset to the lobby.

| Replicated or server shared | Kept local |
| --- | --- |
| Runner position, model yaw and speed | Raw input, camera yaw/pitch and active camera |
| Roster, ready state, status, place, time and wins | UI layout, interpolation and limb animation |
| Phase, light and periodic clock corrections | Mouse capture and audio playback |
| Shove, finish and elimination events | Target owner's application of shove velocity |

## E. Problems encountered and solutions

| Problem | Solution |
| --- | --- |
| Duplicate player creation | Only the server calls the spawner; clients receive its spawn data. |
| Wrong camera or remote response to local input | Only the authority builds a camera and reads input; remote copies interpolate. |
| Uneven pose arrivals look jittery | Interpolate remote pose and snap after a large gap. |
| Server cannot directly teleport an owner-controlled runner | Reliable `_reset_positions` RPC asks each owner to reset its own runner. |
| Red-light transition can penalise in-flight movement or network delay | Reaction grace precedes a server snapshot; a 0.4 m horizontal tolerance filters small changes, and first-arrival poses get a fresh baseline. |
| Testing two real peers in one process | Put each `Main` in its own SubViewport and bind a `SceneMultiplayer` to that path. |
| Localhost test port can be occupied | `RLBL_TEST_PORT` selects a separate ENet port for each test run. |
| Godot `Node.request_ready()` name conflict | The ready request is called `request_player_ready(bool)`. |

The trade-off in the red-light check is that the tolerance can forgive a small genuine move. It is chosen to favor reliable LAN play over strict anti-cheat enforcement.
