# Maintained source patches

Pinned base: 2 Ship 2 Harkinian **5.0.1 "Battler Bravo"** (see `scripts/pins.sh`).

Apply in this order with `scripts/apply-patches.sh`:

1. `2ship-ios.patch` at the pinned 2S2H root;
2. `libultraship-ios.patch` in its pinned submodule. It is the libultraship iOS
   patch shared with HarkinianPad. It includes SDL 2.32.10 UIKit scene startup
   and scene orientation (apps built with the iOS 27 SDK need it to open), the
   controller slot reconciliation, lifecycle pause/resume, cached Metal
   depth-stencil states, the iOS effective refresh-rate report used to cap
   frame interpolation, and the opt-in native-resolution path;
3. `zapdtr-ios.patch` in its pinned submodule;
4. copy `port/CMake/ios.cmake` and `ios/` as new source overlays.

The release verifier requires every patch to reverse-apply against the tested
checkout and every overlay file to match byte-for-byte.
