# Thiruvasagam Pro — project notes

Flutter app, Android-first, published as `com.dftacademy.thiruvasagampro`.
Tamil devotional reader (Thiruvasagam) with TTS, audio streaming, bookmarks,
daily reminder notifications, AdMob.

## Non-negotiables

- **Never touch `server/`.** Kesava handles the songs server himself.
- **Never break working functions.** Smallest change that does the job, and say
  explicitly what was left alone.
- Kesava wants evidence, not assurances: run the build, read the artefact,
  screenshot the device, quote the number.

## Build commands

Release builds MUST include the decrypt keys or the app crashes at startup
(`DatabaseService.seedDatabaseIfEmpty` throws if they are empty):

```bash
flutter build appbundle --release \
  --dart-define=DECRYPT_KEY=rajakavidragonfistsiva1934569690 \
  --dart-define=DECRYPT_IV=dragonfistkavi39
```

`android/app/build.gradle.kts` sets `isMinifyEnabled = true` +
`isShrinkResources = true`. `android/app/proguard-rules.pro` MUST stay wired in
via `proguardFiles(...)` — omitting it once caused a release-only crash
(`Failed to create an instance of androidx.work.impl.WorkDatabase`).

Any new native plugin needs keep rules added to `proguard-rules.pro`, or the
release build will crash while debug works fine. This is the single most likely
way to break a release.

## Architecture

- `lib/models/chapter.dart`, `lib/services/database_service.dart` — songs are
  AES-encrypted into `assets/data_secure.txt`, decrypted at first run with keys
  from `--dart-define`, then seeded into sqflite.
- `lib/viewmodels/reading_provider.dart` — one big ChangeNotifier for reading
  state, settings, TTS, and ad orchestration.
- `lib/utils/responsive_theme.dart` — `Responsive` / `ResponsiveText` helpers.
  **Gotcha:** `scale()` keys off screen *width*, `height()` off screen *height*.
  In landscape on a phone that inflates text to 1.6x while collapsing vertical
  spacing to 0.5x. For anything inside a bounded container (dialogs especially),
  derive scale from the container's own width instead.
- Audio streams from `https://thiruvasagam.dftacademy.in/song<N>.mp3`.
  The same domain is used for the update manifest.

## Conventions

- Visual language: parchment / temple-gold / vintage-ink. Use
  `AppColors.vintageInk`, `AppColors.templeGold`, `AppAssets.templeDivider`,
  `AppAssets.parchmentBg`. Tamil copy is written in Tamil first, with an English
  gloss in parentheses where helpful.
- No global `ThemeData` is set on `MaterialApp`; screens style themselves.
- AdMob unit IDs live in `lib/utils/ad_helper.dart`. Kesava is careful about
  AdMob policy and does not want to risk the account.

## Running tests — always unset the proxy

`flutter test` and `flutter run` fail with
`Unable to connect to flutter_tester process: WebSocketException: Invalid WebSocket upgrade request`
because Dart's `HttpClient` honours `http_proxy`/`https_proxy` from the environment and routes
the runner's loopback WebSocket through the proxy. Always run tests like this:

```bash
env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u all_proxy -u ALL_PROXY \
  NO_PROXY=127.0.0.1,localhost no_proxy=127.0.0.1,localhost flutter test
```

Same reason `curl http://127.0.0.1:PORT` can report success against a dead local server — use
`curl --noproxy '*'` and `lsof -nP -i:PORT` to check.

`flutter analyze` is not affected.

## Testing the app on the device

- `adb shell pm clear` then launching does NOT reliably reset onboarding: Android auto-backup
  (`allowBackup` defaults true, not overridden) restores `shared_prefs` on reinstall. This is
  desired behaviour, not a bug.
- `adb shell run-as <pkg>` only works on **debug** builds — the release APK is not debuggable,
  so its prefs cannot be inspected.
- Device in use: `2311DRK48I` (Android 16, API 36), logical screen 407x904, dpr 3.
  `adb shell input tap` takes **physical** pixels.
- Xiaomi/Redmi blocks `adb install` unless `-t` is passed (`INSTALL_FAILED_USER_RESTRICTED`).
- Rotating for layout tests: `settings put system accelerometer_rotation 0` +
  `settings put system user_rotation 1`. `pm clear` can reset these — re-apply after clearing.

## Name collisions to remember

`in_app_update` exports `AppUpdateInfo` — the project's own model of the same
concept is named `PendingUpdate` to avoid an ambiguous import.
