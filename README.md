# Flowdo

A focus timer with custom time blocks and breaks. Set a duration and go, or
build a list of tasks that each carry their own focus and break lengths and run
them as one session.

Flutter app, targeting Android and iOS, with macOS and web builds in the tree.

## The two modes

**Quick timer** — pick a focus length, a break length, and how many times to
repeat. No setup, no task list.

**Tasks & breaks** — add tasks with their own focus and break durations,
reorder them, then run the whole list as a session. The list can be repeated up
to 5× in one go.

Either mode can be switched off in Settings; the mode picker adapts, and the
app opens straight into the remaining one.

## Features

- Circular countdown with a visual last-few-seconds warning (3–10 s, configurable)
- Chimes at phase transitions, synthesised at runtime rather than shipped as
  assets — `SoundService` generates the WAVs in Dart on first launch
- Local notifications when a focus block or break ends, scheduled so they fire
  with the app backgrounded
- Sessions survive an app restart for up to 24 hours, resuming with the elapsed
  time already deducted
- Session history and a running streak
- Light/dark/system themes, haptics throughout
- Onboarding flow and a privacy policy screen

## Getting started

```sh
flutter pub get
flutter run
```

Requires the Flutter SDK on a Dart `^3.11.5` toolchain (developed against
Flutter 3.41 stable).

Run the tests with:

```sh
flutter test
```

## Project layout

```
lib/
  main.dart            App root; ProviderScope + MaterialApp.router
  router.dart          go_router routes and the shared slide transition
  theme.dart           Light and dark ThemeData, amber seed colour
  extensions.dart      Duration formatting and theme-aware surface colours
  models/              Task, SessionRecord
  providers/           Riverpod StateNotifiers, one per concern
  screens/             One file per route
  services/            Notification scheduling, sound synthesis
  widgets/             DurationPicker, TaskCard, AddTaskSheet
```

## How it fits together

State is Riverpod `StateNotifier`s, one per concern, each persisting itself to
`shared_preferences`. There is no database and no network.

`SessionNotifier` (`lib/providers/session_provider.dart`) is the core. It holds
the task list, the current index, the phase (focus / break / done) and the
seconds remaining, and drives everything through `_advance`.

Two details worth knowing before changing it:

- **The countdown is derived from the wall clock, not from tick counting.** The
  periodic timer recomputes `remaining` as `initialRemaining - elapsed` on every
  fire, so a throttled or suspended timer self-corrects instead of drifting.
- **`skip()` and timer expiry share the same `_advance` path**, which is what
  makes the phase machine testable without waiting on real time.

Session state is written to `shared_preferences` on every tick under
`persisted_session`, and restored in a post-frame callback when the notifier is
constructed. Anything saved more than 24 hours ago is discarded.

Other keys: `feature_timer`, `feature_tasks`, `theme_mode`, `default_focus_s`,
`default_break_s`, `countdown_s`, `sounds_enabled`, `notifications_enabled`,
`tasks_v1`, `stats_total`, `stats_streak`, `stats_last_day`, `session_history`,
`onboarding_done`, `notification_prompted`.

## Testing notes

`SessionNotifier` calls the static `NotificationService` directly, and
`flutter_local_notifications` never registers a platform instance under a test
binding — so any call throws `LateInitializationError` out of the box.
`test/support/notification_stub.dart` works around this by registering the
Android implementation and stubbing its method channel, which both neutralises
the calls and gives the tests a log of what the engine tried to send. Call
`stubNotificationPlugin()` from any test that touches the session engine or the
Settings screen.

Two traps if you extend those tests: `pumpEventQueue()` deadlocks inside
`testWidgets` while a periodic timer is pending, and the post-frame restore
callback has to be fired while its notifier is still alive or a later test will
fire it against a disposed one.

`test/accessibility_test.dart` runs Flutter's built-in
`androidTapTargetGuideline`, `iOSTapTargetGuideline` and
`labeledTapTargetGuideline` against each main screen. Add new screens to that
group — the guidelines catch unlabelled icon buttons and undersized tap targets,
which are otherwise invisible until someone tries the app with a screen reader.

The one-second tick itself is not covered — it reads `DateTime.now()`, which
`fakeAsync` does not control, so testing it would mean real sleeps. Injecting a
clock would fix that.

## Platform notes

**Android.** Scheduled notifications need the receivers and permissions declared
in `android/app/src/main/AndroidManifest.xml`, and the build needs core library
desugaring — both are already set up. Exact alarms are requested via
`SCHEDULE_EXACT_ALARM`; when the user declines, scheduling falls back to inexact
and Settings shows a row offering to grant it.

Release builds are signed from `android/key.properties` when that file exists,
and fall back to the debug keys when it does not — see Release signing below.

**Web.** Sounds are held in memory rather than written to a temp file, and
notifications are skipped entirely.

### Release signing

Play will not accept a build signed with the debug keys, so you need your own
upload keystore. Generate one, keeping it outside the repo:

```sh
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`keytool` asks for a password and a few name fields. Then copy
`android/key.properties.example` to `android/key.properties` and fill in the
password you chose, the alias (`upload`), and the absolute path to the `.jks`.

`key.properties` and `*.jks` are gitignored — keep them that way. Neither the
keystore nor its password belongs in this repo, and losing the keystore means
you can no longer update the app on Play.

With that in place, `flutter build appbundle --release` produces an upload-ready
bundle. Without it the release build still signs with the debug keys, so
`flutter run --release` works on a fresh clone.
