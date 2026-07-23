# Skycaster Weather Player — releases

Release host for **Skycaster Weather Player** (Windows). No source here — this
repo exists only to hold release assets, which
[downloads.skycaster.tv](https://downloads.skycaster.tv/weather-player) streams
to users so the github.com URL is never exposed.

The app has **no auto-updater**. Users get new versions by re-downloading from
the page, so releases only ever contain the installer.

## Publish a build

1. Drop the installer in `drop/` (git-ignored — installers are release assets,
   never committed; git rejects files over 100 MB).
2. Run:

   ```bash
   ./publish.sh drop/Skycaster-Weather-Player-Setup-1.0.0.exe 1.0.0
   ```

   Needs `gh auth login`, or `GH_TOKEN` set to a PAT with `repo` scope.

3. Nothing else. `/windows/latest` always resolves to the newest published
   release, so the worker needs no change between versions.

## Where it shows up

| URL | |
|---|---|
| `downloads.skycaster.tv/weather-player` | download page |
| `downloads.skycaster.tv/weather-player/windows/latest` | latest installer |
| `downloads.skycaster.tv/weather-player/windows/1.0.0` | a specific version |
| `downloads.skycaster.tv/weather-player/older` | all versions |
| `downloads.skycaster.tv/weather-player/api/latest` | `{"version":"1.0.0"}` |

## Notes

- Releases must be **published**, not drafts — the worker skips drafts.
- Tags are `v<version>`; the worker strips the leading `v`.
- The worker caches release lookups for 120s, so a new upload can take up to two
  minutes to appear.
- Max 2 GB per asset. Larger than that, switch the worker to Cloudflare R2.
