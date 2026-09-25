<!-- gf-brief source=0d5d6de9a1b45095b3d1c5f1d64a824ad20f71ff53aea0db30cc50f7d25c9c3d written=2026-09-25T04:33:50+03:00 -->
# Spoonerism

## What it is
Spoonerism is a quiet art quiz for people who want to keep Prado paintings on this device and play with their maker or title words. It spooners a line so two first letters trade places, then asks you to tap a word that swapped. Hits file the painting; misses stay with the kept works.

## Launch and onboarding
1. Cold launch shows a full-screen splash image while the app boots (no text).
2. The system may ask for notification permission at this point.
3. If onboarding is not finished, a three-page cover appears (light interface). Top-right **"Skip"** (pages 1–2 only; accessibility **"Skip onboarding"**). Bottom full-width **"Continue"**. Page dots read as **"Page 1 of 3"** through **"Page 3 of 3"**.
   - Page 1: **"Save a painting."** / **"Keep Prado works on this device. Home is the line, not a museum walk."**
   - Page 2: **"Tap a swapped word."** / **"Two first letters trade. Word order stays. Tap a word that swapped its first letter."**
   - Page 3: **"File the painting."** / **"A true tap shelves it. Misses stay with kept paintings."** — **"Continue"** finishes onboarding.
4. **"Skip"** or finishing page 3 opens the main Quiz. On later launches, onboarding is skipped until **"Re-run onboarding"** or **"Reset all data"** in Settings.

## Screens

### Quiz (home — no tab bar)
Locked home. Job line and next-tap line change with state:
- Waiting: **"Save a painting"** / **"Then you can tap a swapped word."**
- Ready: **"Pick a painting"** / **"Maker or title will paint as words."**
- Live: **"Tap the swapped word"** / **"A first letter moved. Tap that word."**
- Filed: **"This painting is set"** / **"Pick another saved painting."**

Empty (no playable painting): art, then **"Save a painting first."** and **"Then you can tap a swapped word."** (or, if the save could not be read, **"The save could not be read."** and **"The save could not be read. A quiet start is up."**). **"Browse"** opens Browse.

With a painting: photo tile; under it title (fallback **"Painting"**), artist (fallback **"Maker"**), and a caption like **"<date> · Waiting|Ready|Live|Filed"**. Optional fault banner with **"Retry"**. Optional recover note: **"The save could not be read. A quiet start is up."**

Word line: field chip **"Maker"** or **"Title"**; each word is tappable when live. Idle cue: **"Maker or title will paint as words."** A brief success mark appears when a painting files.

Controls:
- **"Spoon"** — paints a new swapped line from a kept painting that is not filed yet. Hidden while Live; disabled while Waiting or busy.
- Undo (arrow; accessibility **"Undo"**) — removes the newest hit or miss. Disabled when there is nothing to undo.
- Tapping a live word — if it swapped, both letters right and the painting files; if not, that word greys as a miss and the line stays.
- **"How it works"** → How it works sheet.
- **"Browse"** → Browse sheet.
- **"Kept"** → Kept sheet.
- **"Settings"** → Settings sheet.
- **"Recent hits"** chips (or **"None yet"**) and **"Misses"** / count / **"kept"** → Kept.

### Browse
Sheet titled **"Browse"**. Close (accessibility **"Close"**). Credit **"Museo Nacional del Prado"**. Field **"Search a work"**. Keyboard **"Done"**. Notes **"Kept."** or **"Already kept."** Search faults may show with **"Retry"** / **"Retry search"**. Empty: **"The shelf is quiet."** / **"Search Prado, then save a work."** / **"Retry"**. Full error: **"Search could not finish."** plus a seek message / **"Retry"**. List rows show title and artist; tap saves on this device; already-saved rows show a check (accessibility **"Already saved"**).

### Kept
Sheet titled **"Kept"**. Close. Empty: **"Nothing filed yet."** / **"Tap a word that swapped its first letter."** / **"Open Quiz"** (dismisses). Load fault: **"Kept paintings could not load."** / fault / **"Close"**. Populated: tally **"Filed"**, **"Hits"**, **"N misses"**; sections **"Filed"** and **"Hits and misses"**; rows like **"Hit <letter>"** / **"Miss <word>"** with painting title and date; fault may offer **"Return to Quiz"**.

### How it works
Sheet titled **"How it works"**. Close. Empty Quiz: **"Save a painting first."** / **"Save a painting, then play."** / **"Browse"**. Otherwise: **"How it works"** plus **"Maker or title paints as words. Two first letters trade. Word order stays. Tap a word that swapped its first letter. A miss greys that word and keeps the rest up."**; current painting title, artist, and status; **"Try a word"** closes back to Quiz.

### Settings
Sheet titled **"Settings"**. Close. Load fault: **"Settings could not load."** / **"Close"**. If nothing kept: **"Nothing kept yet."** / **"Save a painting, then play."** / **"Browse"**.

- **"This device"**: **"Works"**, **"Hits"**, **"Misses"** counts; **"Undo"** (same as home; disabled when empty).
- **"Collection"**: **"Museo Nacional del Prado"** / **"museodelprado.es"**; **"Prado English"** / **"museodelprado.es/en"**; note **"Paintings hang from the Museo Nacional del Prado collection."**
- **"Support"**: **"Contact"** / **"spoonerism-marrow.pro/contact-us"** (opens support in the browser); **"How it works"** / **"A first letter moved. Tap that word."**
- **"Re-run onboarding"** — returns to the three-page cover.
- **"Reset all data"** → confirm **"Reset all data?"** / **"This removes works, hits, and misses on this device."** / destructive **"Reset all data"** / **"Cancel"**. Reset clears local data and shows onboarding again.
- Fault section may show **"Write failed. Try that tap again."** (or other faults) with **"Retry"**.

## Features
- Keep Prado paintings on this device from Browse (search or bundled shelf)
- Spoon a maker or title line so two first letters trade; word order stays
- Tap the swapped word to file a hit; wrong taps record misses and grey that word
- Home Quiz stays up; Browse, Kept, Settings, and How it works open over it
- Recent hits and miss counts on Quiz; full Filed / Hits and misses lists in Kept
- Undo newest hit or miss from Quiz or Settings
- Three-page onboarding; re-run or full reset from Settings
- Prado collection credit links and Contact support link
- Light portrait UI; day stamp on the painting caption

## Behaviours that can look like bugs
- Quiz empty with **"Save a painting first."** until at least one painting is kept via **"Browse"** (or after every kept painting is filed and none can spoon — same empty state).
- **"Spoon"** disabled while Waiting, while a spoon is running, or hidden while Live (**"Tap the swapped word"**); finish or undo, or keep another painting, before spooning again.
- **"Spoon"** can refuse with **"Finish this painting first."**, **"Need two unlike first letters."**, or leave you Waiting if no kept painting qualifies.
- Word taps refuse with **"Tap a live word first."**, **"That word is not on this painting."**, **"Those first letters are already right."**, **"That word already missed."** Missed/filed words stay disabled (strikethrough on misses).
- Undo disabled / **"Nothing to undo."** until a hit or miss exists.
- Browse rows disabled while a save is in progress; **"Already kept."** if tapped again.
- Search may show **"Prado had no match. The bundled shelf is here."** (and similar reach/refuse/read messages) while still listing the bundled shelf — not a blank failure.
- **"Reset all data"** clears works, hits, and misses and loops back to onboarding on purpose.
- Recover banner **"The save could not be read. A quiet start is up."** after a bad save; continue with **"Browse"** / **"Retry"** as shown.

## Starter content and resume
Bundled Browse shelf includes Prado works such as Las Meninas, The Third of May 1808, The Garden of Earthly Delights, The Surrender of Breda, Saturn Devouring His Son, The Nude Maja, The Nobleman with his Hand on his Chest, The Descent from the Cross, The Spinners, and Equestrian Portrait of Charles V (shown when search is empty or fails).

On the iOS Simulator only, first launch can plant sample kept works, a live spoonered Las Meninas line, and sample hits/misses (onboarding already complete). On a physical device there is no planted play state — start from onboarding and Browse.

Kept works, live or filed lines, hits, misses, focus, and onboarding completion resume after relaunch. Backgrounding saves progress.

## Permissions
- Notifications: asked at cold launch via the system permission dialog (no custom usage-description string in the app).
- Camera is not requested. (A usage string **"This app does not use the camera."** is present in build settings but no camera prompt appears.)

## Absent
Absent: login or accounts, in-app purchase, ads, analytics, user-generated content (no posting or sharing of user-created media), account deletion flow, App Tracking Transparency prompt.

## Data and support
Works, hits, and misses stay on this device (Settings **"This device"**; onboarding **"Keep Prado works on this device."**). Browse may reach the Prado collection for search and images. Support: Settings → **"Contact"** (detail **"spoonerism-marrow.pro/contact-us"**), which opens the support page.

## Scanning and health
None.

## Platform
English UI only (no other localizations). Counts and day stamps (e.g. **2026.09.25**) use the device locale’s number formatting. Portrait only on iPhone and iPad. Light appearance. Minimum iOS 17.0.

## Category
Education
