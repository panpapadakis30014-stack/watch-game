# Ringward

## What this is

Ringward is a small, fully offline app for Apple Watch SE (40mm and 44mm, watchOS 10 or later) with two games. In **Ringward**, a glowing core sits in the middle of a round arena and shards fly in from the edge; you turn the Digital Crown to swing a shield arc and block them. In **Lanternfall**, you steer a lantern-keeper through a graveyard at night while your weapons fire on their own at the Risen; when the Grave Warden appears, defeat it to reach dawn. Best results are kept on the watch. There is no networking, no account, no ads and no tracking.

**The iPhone part is only the delivery vehicle.** Installing Ringward puts a "Ringward" icon on the iPhone. That icon never needs opening: it only says "Open Ringward on your Apple Watch to play." The game runs on the watch on its own, even when the phone is away (`WKRunsIndependentlyOfCompanionApp` is on). **Leave the iPhone icon installed**: removing it is expected to remove the watch app as well. The free-account signature also covers the watch app, so when it expires after 7 days the watch game stops opening until you re-sign it in Sideloadly (see "Every 7 days" below).

How it is built:

- `GameCore/`: all game rules in plain Swift (no Apple frameworks), with tests that run on Linux.
- `GameCore/Sources/HordeCore/`: Lanternfall's rules, also plain Swift, with tests that run on Linux.
- `RingwardWatch/`: the SwiftUI watch app. `Ringward/`: the iPhone placeholder that carries it.
- `project.yml`: the Xcode project description (XcodeGen). The `.xcodeproj` is generated, never committed.
- `.github/workflows/build.yml`: GitHub Actions builds an unsigned `Ringward-unsigned.ipa` on a Mac runner, checks it, and takes simulator screenshots.

## Games

The watch app opens on a game picker with two buttons, **Ringward** and **Lanternfall**, each showing your best result. Tap one to open it; if the list does not fit, turn the Crown to scroll. The start and end screens of both games have a **Games** button that brings you back to the picker.

The app uses a night theme with glowing game pieces and short bursts of particles. With Reduce Motion on, the particles, screen shake and zoom animations are turned off.

### Ringward

Turn the Digital Crown to swing the shield and block the shards. When the Pulse meter is full, tap anywhere to clear the screen. A shard that gets past costs one of 3 lives. The button in the top-left corner pauses.

### Lanternfall

- You always walk forward. Turn the Digital Crown to steer.
- Tap anywhere to dash: a short burst of speed during which nothing can hurt you. The ring around you fills up again while the dash recharges (3 seconds at first).
- Your weapons fire on their own. Pick up the gems the Risen drop to gain experience. Each level-up pauses the game and offers three upgrades; tap one. The choices accept taps after a short moment, so a dash tap cannot pick one by accident.
- At 5:00 the Grave Warden rises. When it is off screen, an arrow at the edge points to it. Defeat it to reach dawn and win. If it is still standing at 7:00, the Warden and the whole horde become enraged and faster.
- The button in the top-left corner pauses; from there you can resume or end the run. Lowering your wrist or leaving the app also pauses.
- The watch keeps your longest night, most kills and how many dawns you have reached. Nothing else carries over between runs.

## Build locally (Linux, logic only)

The watch app itself can only be built on a Mac (GitHub Actions does that). On Linux you can build and test the game logic. The Swift toolchain goes into your home folder with swiftly; no sudo.

```sh
mkdir -p ~/.local/share/swiftly-dl && cd ~/.local/share/swiftly-dl
curl -fsSLO https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz
tar zxf swiftly-$(uname -m).tar.gz
./swiftly init --assume-yes --skip-install --no-modify-profile --platform ubuntu24.04 --quiet-shell-followup
. "$HOME/.local/share/swiftly/env.sh"
swiftly install 6.1.2 --use --assume-yes --post-install-file "$HOME/.local/share/swiftly-dl/post-install.sh"
swift --version
```

- `--platform ubuntu24.04` is needed because swiftly does not recognise Linux Mint by name (Mint 22 is based on Ubuntu 24.04).
- Do **not** run the generated `post-install.sh`: it wants `sudo apt-get`, and the game logic builds without those packages.

Then, in every new terminal:

```sh
. "$HOME/.local/share/swiftly/env.sh"
cd ~/watch-game/GameCore && swift build && swift test
```

## Create the GitHub repo and push

1. The public repository `panpapadakis30014-stack/watch-game` already exists (you created it). It is public, which keeps GitHub's macOS build minutes free.
2. Push this folder to it:

   ```sh
   cd ~/watch-game
   git remote add origin https://github.com/panpapadakis30014-stack/watch-game.git
   git push -u origin main
   ```

   `~/.local/bin/gh` is already logged in, so git uses its credentials.
3. The push starts the "build" workflow. It takes several minutes; follow it in the repository's **Actions** tab.

## Download the build

When the "build" run is green:

- In the browser: **Actions** → the latest **build** run → **Artifacts** → download `Ringward-unsigned-ipa` (and, if you want to see the screens, `ringward-screenshots`). Each downloads as a .zip; unzip it to get `Ringward-unsigned.ipa`.
- Or from the terminal:

  ```sh
  cd ~/watch-game
  ~/.local/bin/gh run download --name Ringward-unsigned-ipa --dir ~/Downloads/ringward
  ~/.local/bin/gh run download --name ringward-screenshots --dir ~/Downloads/ringward-shots
  ```

`ringward-screenshots` contains `se40-` and `se44-` versions of `start`, `midgame`, `picker`, `picker-bottom`, `lanternfall-start`, `lanternfall-midgame` and `lanternfall-levelup`.

If the screenshot artifact is missing, the run log of the "Simulator screenshots" step says why (a missing Apple Watch SE simulator is logged as a warning and skipped, never faked).

## Install with Sideloadly (Windows VM)

1. Copy the .ipa where the VM can fetch it: `cp ~/Downloads/ringward/Ringward-unsigned.ipa ~/VMs/windows-share/`
2. Start the VM: `~/VMs/start-windows.sh`. It also starts the file server; inside Windows open `http://10.0.2.2:8000` and download `Ringward-unsigned.ipa`.
3. Hand the iPhone to the VM: `~/VMs/iphone-to-vm.sh`.
4. On the iPhone, remove **CapCut** first, to free its app slot (see "The 3-app limit").
5. In Sideloadly, drag in `Ringward-unsigned.ipa`, sign in with **the same Apple ID** as your other sideloaded apps, and press **Start**.
6. When finished, give the phone back to Linux: `~/VMs/iphone-to-vm.sh --back`.

Whether Sideloadly installs an app with an embedded watch app correctly on a free Apple ID has **not been tested**. See "Known unknowns".

## Check the watch app arrived

On the iPhone, open the **Watch** app → **My Watch** → scroll down to **Installed on Apple Watch**. Ringward should be listed there. If it appears under **Available Apps** instead, tap **Install** next to it. Then find Ringward on the watch's app list.

## Developer Mode on the watch (only if asked)

If the watch refuses to open Ringward and mentions Developer Mode: on the Apple Watch go to **Settings → Privacy & Security → Developer Mode**, turn it on and let the watch restart. That switch may only appear after a developer-signed app has been installed, so don't go looking for it unless the watch asks.

## Every 7 days

Apps signed with a free Apple ID expire after 7 days. After that Ringward (iPhone icon and watch game) won't open until you re-sign it: repeat "Install with Sideloadly" with the same .ipa and **the same Apple ID**. You don't need a new build. Your best score is stored on the watch and should survive the expiry and the re-sign, but that has not been verified.

## The 3-app limit

A free Apple ID allows only **3 active sideloaded apps** at a time, and TikTok, YouTube and CapCut already use all three. You have chosen to give CapCut's slot to Ringward: **remove CapCut from the iPhone before you press Start in Sideloadly.** Whether the embedded watch app counts as an extra app or App ID on a free account is not known.

## Known unknowns

- Sideloadly signing an app with an embedded watch app on a free Apple ID is untested. Sideloadly may add your team suffix to bundle IDs; if it changes the iPhone app's ID without updating the watch app to match, the watch install will fail. Only a real try will tell.
- The Crown speed is tuned blind: `crownDegreesPerUnit` in `GameCore/Sources/GameCore/Tuning.swift` is a guess and the first thing to adjust after playing on a real watch. All other gameplay numbers live in the same file.
- Lanternfall's numbers (steering speed, enemy speed and numbers, upgrade strength, Warden health) are in `GameCore/Sources/HordeCore/HordeTuning.swift` and have not been tried on a real watch.
- Nothing here has run on a real Apple Watch yet. CI proves it builds, packages and launches in the simulator, nothing more.
