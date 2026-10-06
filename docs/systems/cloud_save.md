# System: Cloud save

> **Status:** 🔄 built and tested with stand-ins; waits for Play Console (Play Games project ID) before
> it can run on a phone · **Last updated:** 2026-10-05 · **GDD section:** §12, §14 #84 ·
> **ADR:** [0030](../decisions/0030-play-billing-and-play-games-cloud-save.md) ·
> **Guide:** [play_console_setup.md](../guides/play_console_setup.md)

## Purpose
Keep the save on the player's Google account (owner 2026-10-05), so progress and everything bought —
Rift Points included — survive a reinstall or a new phone. Google Play Games Saved Games on Android;
iOS later.

## Files
| Path | Role |
|---|---|
| `res://scripts/autoload/cloud_save_service.gd` | `CloudSaveService` (autoload `CloudSave`): the provider seam, the sync rules, the upload timing, the bookkeeping file |
| `res://scripts/cloud/play_games_cloud_provider.gd` | The Play Games provider: the plugin's Android singleton (`initialize`, `isAuthenticated`, `signIn`, `loadGame`, `saveGame` and their signals) |
| `res://addons/GodotPlayGameServices/` | Play Games Services plugin v3.4.0 (MIT), **disabled** until the Games project ID is set |
| `res://scripts/autoload/save_manager.gd` | `export_cloud_save()` / `import_cloud_save(bytes)` |
| `res://scenes/screens/settings_screen.gd` | The CLOUD SAVE card |
| `res://scenes/main/main.gd` | Rebuilds Home when a cloud save replaced the save |
| `user://cloud_sync.json` | This phone's bookkeeping: when it last synced, when it last really changed, a fingerprint of the save |
| `res://tools/godot/test_cloud_save.gd` | The sync rules through a stand-in cloud |

## Public API
| Member | Kind | Description |
|---|---|---|
| `save_restored` / `state_changed` | signal | The cloud copy replaced this phone's save / signed in, out, or a sync started or ended. |
| `set_provider(provider)` · `set_save_manager(save)` · `configure_meta_path(path)` | method | Injection for Android and tests. |
| `is_supported()` · `is_signed_in()` · `is_syncing()` | method | For Settings. |
| `start()` · `sign_in()` · `sync()` · `upload_if_changed()` | coroutine | Silent sign-in + sync; the Settings sign-in; one sync; an upload when something really changed. |
| `CloudSaveService.Provider` | class | `start`, `sign_in`, `is_signed_in`, `load_save(name)` → {`found`, `bytes`, `modified_ms`} or {} when unreachable, `write_save(name, bytes, description, progress)`. |

## Data & tuning
| Value | Setting |
|---|---|
| Snapshot name | `wisp_rush_save` (the whole save as JSON) |
| Upload delay after a real change | 5 s (`UPLOAD_DELAY_SECONDS`); at once when the app is paused |
| Request time-out | 20 s (the provider's `TIMEOUT_SECONDS`) |
| Fields that do not count as a change | `consent_state`, `play_time_seconds`, `schema_version` |

## Rules & behaviour
- **The newest save wins** (owner, 2026-10-05), by the time of the last real change on each side:
  - a phone that has **never synced** takes the cloud save when there is one (a reinstall or a new
    phone), so a fresh install cannot overwrite the player's progress (Claude's rule);
  - the cloud changed since this phone's last sync and this phone has nothing newer → the cloud wins;
  - this phone changed after the cloud's last change → this phone's save uploads;
  - no cloud save yet → this phone's save uploads;
  - the cloud could not be reached → nothing changes; bytes that are not a save are refused.
- Sign-in is silent at launch; Settings shows ON, or OFF with SIGN IN WITH GOOGLE PLAY GAMES.
  The card exists only on a build with a cloud, at Home level.
- Imported saves go through SaveManager's validation and migration, like a file on disk.
- Reset Progress counts as a real change, so it reaches the cloud too.

## How to test
- `tools/run_tests.sh cloud_save`.
- On the phone, after Play Console (guide §4–§5): sign-in at launch, the Settings card, a reinstall
  that brings progress back, two phones (the newer save wins).

## Known issues / TODO
- Not run against Google yet: needs the Games project ID and credentials (guide).
- Android ↔ iPhone progress does not cross; iOS is later.

## Change history
| Date | Change |
|---|---|
| 2026-10-05 | Created (owner, GDD §14 #84, ADR-0030): `CloudSave`, the Play Games provider, SaveManager export/import, the Settings card, `test_cloud_save` |
