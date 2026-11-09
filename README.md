# Foldable split view for Forkgram (Telegram Android)

Draggable divider between the chat list and the chat pane on foldables and tablets.
Built for **OPPO Find N5** (ColorOS, unfolded 2248×2180, 520 dpi), works on any device where
Forkgram itself switches to the two-pane tablet layout.

Before: the panes were locked to `max(320dp, 35% of width)` — on a 6.9" foldable that is almost
half the screen and cannot be changed.
After: drag the boundary with your finger, 80dp…(width − 300dp). The chat list can be squeezed
down to bare avatars, the chat takes the rest. The position is stored in `SharedConfig` and
restored on the next launch. The stock "Disable tablet mode" toggle in Forkgram settings still
gives a single-pane layout.

## What the patch changes

| File | Change |
|---|---|
| `TMessagesProj/.../messenger/AndroidUtilities.java` | `getTabletLeftFragmentSize()` uses a fraction from prefs; min 80dp left, 300dp right |
| `TMessagesProj/.../messenger/SharedConfig.java` | `tabletSplitFraction` (0.05…0.85), load/save, `setTabletSplitFraction()` |
| `TMessagesProj/.../ui/LaunchActivity.java` | `onInterceptTouchEvent`/`onTouchEvent` in the root `FrameLayout` of the tablet layout: touch within ±24dp of the divider starts a drag, `requestLayout()` on move, `saveConfig()` on release |
| `TMessagesProj/build.gradle`, `TMessagesProj_App/build.gradle` | arm64-v8a only (APK below the 50 MB upload limit, faster native build) |

## Apply

```bash
git clone --recurse-submodules https://github.com/forkgram/TelegramAndroid.git tg
cd tg
git apply /path/to/0001-foldable-split-panels.patch
```

## Build

Needs a Linux host with Docker and ≥8 GB RAM (native deps: BoringSSL, FFmpeg, TDLib, librust…).
Build in the image from the repo's own `Dockerfile` plus the missing tools:

```dockerfile
FROM <image built from ./Dockerfile>
RUN apt-get update && apt-get install -y --no-install-recommends \
      ninja-build meson nasm yasm gperf pkg-config make automake libtool \
      build-essential zlib1g-dev libssl-dev
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable \
 && rustup default stable \
 && rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
RUN yes | sdkmanager --sdk_root=$ANDROID_HOME "build-tools;35.0.0" "platforms;android-36"
ENV PATH=/root/.cargo/bin:$ANDROID_HOME/cmake/3.22.1/bin:$PATH
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
```

Then `./build.sh` (see the script) — it mounts the source tree into the container and runs

```
gradle --parallel -Parm64-v8a :TMessagesProj_App:assembleAfatRelease
```

Output: `TMessagesProj_App/build/outputs/apk/afat/release/app.apk` (~42 MB).

Put your own `APP_ID` / `APP_HASH` (my.telegram.org) and your keystore in `gradle.properties`
before building, otherwise the APK is signed with the upstream test key and cannot log in
with your own API identity.

## Known limits

- Only the left pane is dragged; the right pane takes the remaining width.
- Narrow widths (<120dp) clip chat titles — that is the intended "avatars only" state.
- Landmarks: no visible handle, the grab zone is ±24dp around the seam.

## License

Patch is published under GPL-2.0, same as Telegram Android / Forkgram sources it applies to.
No API keys, keystores or binaries are included.
