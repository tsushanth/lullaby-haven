# Lullaby Haven (com.kreativekoala.lullabyhaven) Play releases

## 1.2.0 (4), 2026-11-16, production at 20%
- Built from origin/main 20073584551153532cc781a0c94e79784d496a00 (tag play/1.2.0-4), `LullabyHavenAndroid/`, `:app:bundleRelease`, unminified.
- AAB sha256 7694d98ef58a039cba5843e63e1c7b7c13c00f8dc3c24dcb179dceedc0d6969d
- Unit tests: 12 pass. Lint: 1 error, pre-existing (NewApi: FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK in SoundService.kt:57, API 29 vs minSdk 26; code from the original sound service commit). MissingTranslation for app_name fixed in this release (translatable="false").
- Track after commit: production 1.2.0 [4] inProgress 0.2; 1.1.0 [3] completed.
- Content: UI in 27 languages + per-app language list. Stories and narration remain English.
- Rollback: halt the rollout, or re-upload versionCode 3 as the completed release via the Play API.
