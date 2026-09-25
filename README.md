# Spoonerism

Tap a word that swapped its first letter on a saved painting's maker or title. Spoonerism is for people who keep Museo Nacional del Prado works on this device and want to mend those openings here, not walk a museum site.

Home is the onset. A live Line of Heads waits on Quiz. Explore, Saved, and Settings arrive as sheets. There is no tab bar.

## Architecture

The onset is one Codable algebraic fold over Works: Idle, Spooned, and Mended. Every user verb is a total function on that crate.

- **Spoon** samples one saved Work that is not Mended whose chosen field has two or more tokens with unlike first letters. It writes a Line that is artist XOR title, exchanges the first letters of two Heads, and folds Idle to Spooned.
- **Mend** writes a MendMark when the tapped Head is one of the swapped pair, rights both letters, and folds Spooned to Mended. A miss writes a MuffMark, greys that Head, and keeps the Line.
- **Mend on Idle is refused.** A second Spoon while Spooned is refused. Spoon on a thin field is refused. An onset with no usable painting writes Fluent.

This pattern fits because the quiz is a fold, not a list. The Line, the marks, and the Work fold have to move together or the crate lies. Persistence is one Onset document. The UI never reads UserDefaults.

## Spoon-then-mend

This is why someone would pick this app. Nearby folds move or reverse whole words. Spoonerism leaves word order alone and swaps only the first letter of two Heads on maker or title, never both fields at once.

Launch already paints a live Line, so the first Head tap can file. Hitting a swapped Head rights both openings, records a MendMark, and moves the painting to Mended so it leaves the Spoon pool. Hitting any other Head records a MuffMark and leaves the Line up. Saved lists MendMarks together with MuffMarks. Settings names Museo Nacional del Prado.

## Design

Soft card daylight. Warm, hospitable, photography-first. One large painting tile, caption under the tile, the spoonered Line as the mechanic, a recent MendMark rail, and one MuffMark count. Pill CTA. Soft shadow only on the hero. SF Pro through Font.system. Colours live in the asset catalog and are reached through `MarrowInk`.

Art style: 3D glass render glassmorphism. Base prompt, reused and extended for every asset:

```
3D glass render, glassmorphism, frosted translucent volumes with solid opaque cores, soft museum daylight, shallow depth, clean studio backdrop, marrow and swapped-letter still life, no text, no words, no invented palette
```

Exact prompt used for every image set:

**spn_AppIcon**

```
3D glass render, glassmorphism, a solid marrow spoon crossing two frosted letter blocks that have traded faces, emblem centred, filling the canvas edge to edge, no text, no words, no rounded corners, no drop shadow outside the canvas, opaque
```

**spn_Splash**

```
3D glass render, glassmorphism, a vertical lectern and hanging painting in frosted glass, calm uncluttered centre band, middle third quiet, fill the canvas, no text
```

**spn_Onboarding1**

```
3D glass render, glassmorphism, a lecturer reaching toward one hanging painting tile, solid opaque glass subject, isolated
```

**spn_Onboarding2**

```
3D glass render, glassmorphism, two solid glass word tiles mid tap with first faces traded, primary verb mid-gesture, isolated
```

**spn_Onboarding3**

```
3D glass render, glassmorphism, a saved painting tile with both openings righted and a quiet marrow token beside it, later meaning, isolated
```

**spn_EmptyHome**

```
a solid closed ceramic marrow bowl waiting to be used, fully opaque ceramic, not glass, not wire, not hollow, inviting
```

**spn_EmptyList**

```
a solid empty wooden folio board with no rows, fully opaque wood, not glass, not wire
```

**spn_CardBackdrop**

```
abstract 3D glass daylight field, low contrast frosted planes, fill the canvas, no text, quiet enough for type on top
```

**spn_ControlFace**

```
the face of one Head chip, a single solid frosted glass word tile, physical control, opaque core
```

**spn_TwistHero**

```
two solid glass heads exchanging first letter faces, spoon-then-mend emblem, opaque centres, isolated
```

**spn_SuccessMark**

```
a solid glass knot of two righted letter faces, quiet confirmation, opaque core, isolated
```

**spn_HeaderDecor**

```
a wide decorative glass marrow band, ornament only, fill the width, no text
```

## How this is not a repeat

This is not a reskin of Anastrophe, Hyperbaton, or Boustrophedon. Those folds move or reverse whole words. Home here swaps only the first letter of two Heads. Explore, Saved, and Settings are sheets on an onset-locked Quiz. Prado is the collection voice. Onset, Head, MendMark, MuffMark, Fluent, and marrowsky do not appear on nearby folds.

## Build

```bash
cd Spoonerism
xcodegen generate
xcodebuild -scheme Spoonerism -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Spoonerism -destination 'platform=iOS Simulator,id=<UDID>' test
```

Simulator seed sits behind `spn.demo.v1` and is never written on a device. Review shots use `-ReviewScreen today`, `-ReviewScreen log`, `-ReviewScreen goals`, and `-ReviewScreen explore` after onboarding.
