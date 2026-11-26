# Device adaptation

Layouts follow the space SwiftUI gives the view. Feature screens do not read the device model, screen bounds constants, or orientation notifications.

## Techniques

- `ReadableScreen` caps content at 1100 points and centers it, so a wide inner display does not stretch a card edge to edge.
- `AdaptiveColumnGrid` wraps its children into columns from the container width (minimum item width 320, maximum 520). Every child stays in the view tree, including cards below the fold.
- `AdaptivePair` measures its own width with `onGeometryChange` and switches between a vertical stack and a top-aligned horizontal stack at 760 points. Explore and Travel use this for map and list. Environment uses it for the current conditions and air-quality cards.
- Below that width, Explore and Travel keep an explicit List / Map control so one surface is primary.
- Navigation is a `TabView` of `NavigationStack`s, so each tab keeps its stack when the available size changes.
- Type uses text styles (`body`, `headline`, `largeTitle`) so Dynamic Type can scale them.
- Severity and read state always include a word and an SF Symbol. Color is an extra cue.
- Forecast rows expose a combined VoiceOver label with the day, high, low, condition, and precipitation chance.
- Maps use fixture coordinates only. User location is not shown and location permission is not requested.

## iPhone Duo displays

The iPhone Duo simulator profile installed with Xcode 27.2 describes two integrated displays:

| Display | Device name | Pixel size | Scale |
| --- | --- | --- | --- |
| Outer / primary | `primary` | 1398 × 2034 | 3x |
| Inner | `primary-1` | 2007 × 2853 | 3x |

`simctl io enumerate` lists those screens. `simctl io screenshot --display` can capture each one. `simctl ui` in this Xcode does not expose a fold or posture command, and Device Hub was not driven from this session. Fold and unfold were therefore not automated. The layouts still reflow from the container width, which is what changes when the inner display is the active scene.

Point sizes are 466 × 678 for the outer display and 669 × 951 for the inner display. The 760-point side-by-side breakpoint stays a single column on both of those portrait sizes. Rotate the inner display to landscape (about 951 × 669) or use a resizable scene wider than 760 points, and Explore, Travel, and Environment place the secondary column beside the primary one. Home's adaptive grid can place two cards once the content width reaches 320 points twice.

## What was actually captured

On 25 November 2026 the iPhone Duo simulator `B4748265-E465-4507-9A04-DACEBD5BF343` (iOS 27.2, build 24B91016s) was booted. `simctl io enumerate` listed both integrated displays powered on. `bootstatus` printed `Data Migration Failed` and then returned; install and launch still succeeded.

`Documentation/Screenshots/duo-primary.png` is the outer display after launching `com.utahlife.app`. Home is visible: greeting, Salt Lake City, the sample banner, weather, the hourly row, air quality, and a trailing rail with the five tabs. The app window reported by the UI test hierarchy is 466 × 678 points. Content is inset to about 382 points, so the rail does not cover the weather card. The hourly row is a horizontal scroller, so the last hour on screen is clipped at the scroller edge.

`Documentation/Screenshots/duo-primary-1.png` is the inner display from the same moment. The framebuffer is black. The app had a single window on the outer display. `simctl ui` in this Xcode can set appearance, contrast, and content size. It has no fold, unfold, or posture command, and Device Hub was not driven. Fold, unfold, intermediate poses, and the expanded inner layout were not exercised.

## Manual Device Hub checklist

1. Open `UtahLife.xcodeproj` in Xcode 27.2 and run on iPhone Duo (iOS 27.1 or 27.2).
2. On the outer display, confirm the sample banner, five tabs, and a single-column Home. Scroll the dashboard and open the location sheet.
3. Switch to the inner display. Confirm Home still shows the same location and that cards reflow instead of stretching edge to edge.
4. Open Explore and Travel. In portrait they should stay a single column with a List / Map control. In landscape, or any width at or above 760 points, map and list should sit side by side.
5. Open a forecast day, an incident, a place, and an alert. Dismiss each sheet and confirm the previous tab and scroll position remain.
6. Fold and unfold while Home is open. The selected tab and location should stay put.
7. Switch the simulator to dark appearance and a larger content size. Text should remain readable and the sample banner should still be visible.

Recapture with:

```sh
xcrun simctl io <device> enumerate
xcrun simctl io <device> screenshot --display primary Documentation/Screenshots/duo-primary.png
xcrun simctl io <device> screenshot --display primary-1 Documentation/Screenshots/duo-primary-1.png
```
