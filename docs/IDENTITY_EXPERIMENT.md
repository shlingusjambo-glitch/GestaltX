# Siri Identity Lab — experimental build 1.0.5 (2026110902)

This build tests whether cached device identity affects Siri Expressive Voices
eligibility on an iPhone 17 running iOS 27. It does not claim a successful voice
unlock. Build, transaction and rollback tests cannot verify Siri functionality.

## Observed result and recovery

The first iPhone 17 / iOS 27.0.1 product-only test did **not** expose Expressive
Voices. It changed ProductType to `iPhone19,2`, while audio identity queries still
returned `iPhone18,3` / `V57AP`. The public Foundation Models API reported
`available` and selected `core3` / AFM 3 Core. The phone still reported 8 GiB via
MobileGestalt. The tester reported a camera recognition warning and nonresponding
spoken Siri while typed Siri worked. These are regressions, not success criteria.

Restore the original identity and restart before continuing. Version 1.0.5 adds
**Check Selected AI Model** and **Share Model Diagnostics**. The diagnostic path
does not acquire the MobileGestalt write exploit, change settings, generate text,
request downloads or remove model assets. It queries only allowlisted capability
values and the public Foundation Models API. Device-unique identifiers are excluded.

The default API's variant does not enumerate installed Siri voice assets or prove
which model a Siri conversation uses. `modelNotReady` is not proof of a stuck
download; `DeviceSupportsAudioIntelligence` is not established as the Expressive
Voices gate. The precise advanced-model selection gate and a working bypass have
not been established. There is no verified model-reset or force-download fix in
this build, and neither RAM spoofing nor unverified capability overrides is applied.

The host can request the same read-only report with the launch argument
`--siri-model-diagnostics`; that path writes a report in the app's own Documents
directory and exits, without loading the main editor or writing a system cache.

## Using the experiment

1. Keep a device backup and export the original MobileGestalt plist from GestaltX.
   Keep this app installed: its original-value journal and backups live in its
   application container. An app reinstall that deletes data loses that journal.
2. Open **Tools → Read MobileGestalt**, then **Intelligence → Siri Identity Lab**.
3. Select **iPhone 18 Pro** (or **iPhone 17 Pro** for a same-generation comparison).
   Start with **Product identifier only**. The AI capability toggle is off by
   default because a standard iPhone 17 already supports Apple Intelligence.
4. Tap **Stage Selected Identity**, then **Review Changes**. Only the selected
   identity fields should change. Apply, then restart the iPhone manually.
5. Reopen GestaltX and read again. Share Identity Report records the cached values
   and excludes serial numbers, UDIDs and the rest of the system plist.
6. Check Siri settings for Expressive Voices/pace/expressiveness controls. Record
   separately whether controls appear, assets download, and speech actually works.
   A changed model name, new Siri animation, or successful write proves none of
   those three outcomes.
7. If product-only has no effect, first restore the original identity and restart.
   A second experiment can use **Product, board and platform**. Those are reported
   identity values; changing them does not change the chip or available memory.

To undo: **Stage Original Identity → Review Changes → Apply → restart manually**.
The durable original-value journal restores the exact previous values and plist
types, including removing fields that were originally absent. It survives app
relaunch and deletion of visible backup files. Unrelated pending edits remain
staged, so inspect the review before applying. For a complete rollback, use the
original backup in Backups. Never import another phone's complete plist.

Changing scope modifies only the selected fields; it does not undo hardware
identifiers from an earlier applied experiment. Restore between experiments.
Neither staging nor installation automatically modifies MobileGestalt or restarts
the phone. Hardware spoofing may disrupt Face ID and model downloads. A failed
boot may require a device restore; the in-app rollback cannot run if iOS cannot boot.

## Implementation and limits

The iOS app independently implements a small, allowlisted mutation using
GestaltX's existing transaction store. There is no Nugget restore implementation
in this build. Nugget itself warns against restoring on iOS 27.

| Logical field | MobileGestalt key |
|---|---|
| ProductType | `h9jDsbgj7xIVeIQ8S3/X3Q` |
| TargetSubType (Nugget's board-spoof field) | `oYicEKzVTz4/CxxE05pEgQ` |
| HardwarePlatform | `5pYKlGnYYBzGvAlIU8RjEQ` |
| Generative-model capability | `A62OafQ85EJAiiqKn4agtg` |

No RAM values, device-unique identifiers, region flags, eligibility databases,
feature-flag files or display geometry are changed by this experiment. It does
not reproduce Nugget's separate eligibility-file override, and model assets or
server eligibility may reject the spoof. We have not established which checks
govern AFM Core Advanced on iOS 27.

Targets (verified metadata on 2026-11-09):

| Target | Product | Board | Platform |
|---|---|---|---|
| iPhone 17 Pro | iPhone18,1 | V53AP | t8150 |
| iPhone 18 Pro | iPhone19,2 | V63AP | t8160 |

Sources:

- Nugget's key mapping: https://github.com/leminlimez/Nugget/blob/main/src/tweaks/tweak_loader.py
- Device catalog: https://api.ipsw.me/v4/devices
- Apple's installed Xcode 27.2 metadata:
  `/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 18 Pro.simdevicetype/Contents/Resources/profile.plist`
  confirms `modelIdentifier=iPhone19,2`, `productClass=V63`, and iOS 27 minimum.
- Apple's voice eligibility: https://support.apple.com/en-us/127893
- The companion Nugget fork exports only factual target declarations:
  https://github.com/shlingusjambo-glitch/Nugget/tree/experiment/gestaltx-identity/experiments

Nugget application code is AGPL-3.0 and is not bundled. GestaltX and this
independent implementation remain GPL-3.0. Existing notices remain intact.

## Reproduce the build

```sh
bash scripts/test_identity.sh
bash scripts/build_identity_ipa.sh
```

The build script produces an ad-hoc-signed IPA with App Group requests embedded
in both binaries so Impactor can discover them before provisioning. This IPA
requires Apple-account signing before installation. Keep the share extension,
disable single-profile mode, and clear custom entitlement overrides. Both final
profiles must authorize a common App Group and match their own bundle IDs.

The original bundle identifiers are retained to preserve the installed app's
backups and original-value journal. This is an update to GestaltX, not a second
independent installation. It is labeled **GestaltX Lab** on the Home Screen.
