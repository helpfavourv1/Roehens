# Visual QA (Gate 2)

Gate 2 compares a screenshot from the cheapest supported device with the reference-tier app for weight, spacing and clarity.

| Item | Value |
|---|---|
| Cheapest Android device | Model code `25028RN03A`, Android 15, about 3.7 GiB RAM |
| Android reference app | Google Home |
| iOS reference app | Apple Home |
| iOS test device | none available; iOS visual checks wait for a borrowed device |

A screen is implemented after Gate 1 (analyze, guard, tests) and done only after Gate 2. A screen that has not passed Gate 2 is listed under Open and blocks the end gate.

## Checkpoint A1: component library on the Redmi 25028RN03A

Two rounds of screenshots (37 in all) from the owner's phone, plus screenshots taken by the `emulator_check` workflow.

### Passed on the device
- Icon weights beside text; Title 2, Body and Footnote sizes.
- Buttons (all kinds), chips, badges, icon buttons, the settings-style list group, switch, segmented control, card, slider, spinner and bar, and the four banner tones, in dark and light.
- Text fields: label, hint, helper, error, password with show/hide, address field in monospace and left-to-right.
- Video tile at 360, 180 and 97 wide; the 2x2 and 4x4 grids; the layout picker. Status shown as icon, text and color.
- PTZ pad, zoom buttons, speed slider; fullscreen controls (close, name, status, mute, snapshot, PTZ toggle).
- Sticky letter headers and search in the brand list; the keyboard collapsing the bottom bar; right-to-left mirroring including the Arabic section.
- Copy and paste: the cut/copy/paste/select-all bar and the selection handles (seen on the phone for the bar and on the emulator for the handles).

### Found and fixed after the first look
Copy and paste did not work (no menu on Android; no tap or long-press handling on a bare text field); light-mode status bar icons invisible; 4x4 tiles overflowed; status icons too dark on the dark plates in light mode; nav bar brand and title ran together; count badge covered the bottom bar icon; selected PTZ toggle invisible over video; spinner ring invisible on a filled button. Ad slot, bottom stack and storage banner threw a layout error with animations switched off (found by the emulator).

### Found and fixed after the second look (large text, 200 percent)
Nav bar wordmark squeezed the title; bottom bar count badge grew over its label; "System" broke inside the word in the three-way segmented control (now stacks); banner and error icons sat above the first line of text; fullscreen status bar icons were dark over the picture in the light theme; selection handles were built but never shown (found by reading the handle opacity); selection highlight too faint.

### Open (needs the owner's eye on a phone)
- Selection handles are plain circles under the ends of the selection, not the Android teardrop; judge whether that reads as a handle.
- Overall weight, spacing and clarity against Google Home: the owner's verdict is still wanted.
- Light-theme banner tints (the warning banner reads slightly muddy).
- 310 percent text on every screen: checked at 200 percent only so far.

### Not testable on the available hardware
Picture-in-picture (the test phone does not support it) and anything on iOS (no device).
