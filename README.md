# Skycaster Weather Player — releases

Release host for **Skycaster Weather Player** (Windows). No source here — this
repo exists only to hold release assets, which
[downloads.skycaster.tv](https://downloads.skycaster.tv/weather-player) streams
to users so the github.com URL is never exposed.

## Publish a build

1. Drop the installer in `drop/` (git-ignored — installers are release assets,
   never committed).
2. Run:

   ```bash
   ./publish.sh drop/Skycaster-Weather-Player-Setup-1.0.0.exe 1.0.0
   ```

That generates `latest.yml`, creates the `v1.0.0` release, and uploads both.
Within a minute or two (worker caches the release lookup for 120s) the download
page flips from "Not released yet" to live.

## Where it shows up

| URL | |
|---|---|
| `downloads.skycaster.tv/weather-player` | download page |
| `downloads.skycaster.tv/weather-player/windows/latest` | latest installer |
| `downloads.skycaster.tv/weather-player/windows/1.0.0` | a specific version |
| `downloads.skycaster.tv/weather-player/older` | all versions |
| `downloads.skycaster.tv/weather-player/api/latest` | `{"version":"1.0.0"}` |

## Auto-update

Point the app's `electron-updater` feed at:

```js
autoUpdater.setFeedURL({
  provider: 'generic',
  url: 'https://downloads.skycaster.tv/weather-player',
});
```

`publish.sh` writes the `latest.yml` that feed reads. If the app is already
built with electron-builder, prefer letting it publish directly instead:

```json
"publish": { "provider": "github", "owner": "VeliborSimonovic", "repo": "skycaster-weather-player-releases" }
```

then `electron-builder --win --publish always` — it produces `latest.yml` itself
and `publish.sh` is unnecessary.

## Notes

- Releases must be **published**, not drafts — the worker skips drafts.
- Tags are `v<version>`; the worker strips the leading `v`.
- Max 2 GB per asset. Larger than that, switch the worker to Cloudflare R2.
