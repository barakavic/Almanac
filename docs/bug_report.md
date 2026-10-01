# Cross-Platform Startup and Android Build Issues

**Status:** Resolved and verified  
**Affected targets:** Linux desktop and Android  
**Environment during diagnosis:** Flutter 3.44.6, Ubuntu 24.04, Android SDK Platform 37.0 installed

## Summary

The app initially failed to appear on Linux because startup awaited a permission plugin that has no Linux implementation. After that was bypassed, unsupported sharing and deep-link plugin channels could also throw `MissingPluginException`. Separately, Android builds failed first on Gradle configuration and then on an Android SDK platform directory mismatch.

## Symptoms and causes

### Linux desktop window did not appear

The app awaited initial camera/storage permission checks before calling `runApp()`. Linux did not have a `permission_handler` implementation registered, so the method-channel call failed before Flutter rendered the first frame. The GTK window was created but remained unmapped because the Linux runner displays it only after the first frame.

Once permission startup was guarded, `share_handler` and `app_links` also needed platform-aware initialization: the Linux generated plugin list did not contain their Linux implementations, so calls to their channels could fail at runtime.

### Android build failed

Two independent Android build issues appeared:

1. The root Gradle build used `afterEvaluate` to set Android library namespaces. Some subprojects were already evaluated when this callback was registered, causing `Cannot run Project.afterEvaluate(Action) when the project is already evaluated`.
2. The resolved `permission_handler_android` 14.1.0 required SDK 37. Gradle looked for `platforms;android-37`, while the installed SDK was registered and stored as `platforms;android-37.0`. Thus `flutter doctor` could report the installed platform while Gradle still could not resolve the path it required.

## Fixes applied

- **Platform-aware permissions:** Linux returns without invoking unsupported permission channels. Android and Windows continue to use `permission_handler`. See [app_permissions.dart](../lib/services/app_permissions.dart).
- **Platform-aware sharing and links:** Share-intent methods run only where `share_handler` is supported (not Linux or Windows). App-link setup is skipped on Linux, where the plugin is unavailable, and remains enabled on Android and Windows. See [shelf_screen.dart](../lib/widget/shelf_screen.dart).
- **Gradle namespace configuration:** Replaced the late `afterEvaluate` callback with `plugins.withId("com.android.library")`, configuring the namespace when the Android library plugin is applied. See [android/build.gradle.kts](../android/build.gradle.kts).
- **Compatible permission dependency:** Changed `permission_handler` to `^12.0.3`; dependency resolution selected `permission_handler_android` 13.0.1, which does not require SDK 37. The app uses Flutter's configured compile SDK rather than hard-coding 37. See [pubspec.yaml](../pubspec.yaml) and [android/app/build.gradle.kts](../android/app/build.gradle.kts).

These changes do not raise the app's `minSdk` or `targetSdk`. They do not change which Android OS versions the app supports or opt the app into new Android target behavior.

## Verification

- `flutter doctor -v` reported the Android toolchain and installed platform as available, but this alone did not verify Gradle's SDK path resolution.
- `flutter pub get` resolved the compatible permission-handler versions successfully.
- `flutter run` built `build/app/outputs/flutter-apk/app-debug.apk` and installed it on the connected SM A135F Android 14 device. The initial full build took about 167 seconds; later builds should benefit from Gradle's build cache.
- Linux desktop launched after unsupported permission, sharing, and app-link calls were guarded.

## Warnings versus errors

The Gradle 8.12, Android Gradle Plugin 8.9.1, Kotlin 2.1.0, and Java source/target compatibility messages were warnings during the successful Android build. They were not the cause of the earlier failures and were not changed as part of this fix. Consider updating those versions separately with a tested migration.

## Troubleshooting

- Check available device IDs with `flutter devices`; wireless ADB IDs can differ from a phone's USB serial.
- Run `flutter pub get` after changing dependency constraints.
- For Android, run `flutter run -d <device-id>` and distinguish a long first compile from an error: look for `BUILD FAILED` and the first specific Gradle exception.
- Do not rename or symlink SDK platform directories to work around an API-level naming mismatch. Prefer compatible plugin versions or a properly installed SDK platform.
