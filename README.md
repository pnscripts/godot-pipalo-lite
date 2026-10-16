# Pipalo Lite by PN Scripts

Free touch controls for Godot 4 (MIT): a **virtual joystick**, **multi-touch buttons** and a
**safe area** for notches. They press your existing input actions, so your game code keeps using
`Input.get_vector()` and `is_action_pressed()`. They show themselves only to touch players and
release every action they hold when they hide.

![The demo in a web export: joystick held while Jump is pressed](https://raw.githubusercontent.com/pnscripts/godot-pipalo-lite/main/listing/preview-touch-1280x720.png)

## Quick start

1. Copy `addons/pipalo_lite` into your project (or install "Pipalo Lite" from the Godot Asset
   Library) and enable **Pipalo Lite** in Project Settings > Plugins. This adds the autoload
   `PipaloLite`, which tracks the device in use.
2. Add a full-rect **PipaloLiteSafeArea** to a CanvasLayer, a plain Control inside it, and in that
   Control a **PipaloLiteJoystick** (bottom left) and **PipaloLiteButton** nodes (bottom right).
3. Set the joystick's four actions (`move_left`, `move_right`, ...) and each button's `action`.

The demo (`demo/main.tscn`, the project's main scene) is a small runner set up exactly like this.
It turns on Emulate Touch From Mouse, so on a desktop you can click and drag to try it.

## Nodes

- **PipaloLiteDevice** (autoload `PipaloLite`): the last device used, `keyboard`, `gamepad` or
  `touch`, and the controller family (`xbox`, `playstation`, `nintendo`, `steam`,
  `generic`). Small stick drift and mouse copies of touches do not count. Signal
  `device_changed(kind, family)`.
- **PipaloLiteJoystick**: fixed, floating (appears under the finger) or following (slides along
  when the finger goes past the edge); deadzone, response curve, optional 8 directions. Presses four
  actions with analog strength and gives the vector through `output` and `moved`.
- **PipaloLiteButton**: holds an action while touched; several buttons at once with several
  fingers; a finger sliding from one button to another moves the press; toggle mode; circle or
  rounded rectangle; text or icon.
- **PipaloLiteSafeArea**: margins from the display's safe area plus a minimum margin (on the web the
  browser keeps the page inside the safe area).

## Tested

- Godot **4.7.1** (standard build, Linux): 12 tests, 81 checks (`make test`); the repository
  archive as the Asset Library downloads it, installed into a fresh project with the plugin enabled
  (`make buyer-check`).
- **Web export** in Google Chrome 155.0.8059.79 (headless, SwiftShader WebGL) with real multi-touch events:
  one finger holds the joystick while another presses Jump, 0 console errors (`make web-check`).
- Not tested on a real phone, tablet or touch screen, with real gamepads, or in Android, iOS,
  Windows and macOS exports.

## Pipalo (full edition)

Pipalo adds **gestures** (tap, double tap, long press, swipe, pinch, rotate, two-finger pan) and
**button prompts that follow the player's device** (key caps, Xbox, PlayStation, Nintendo and touch
glyphs inline in your text): https://pnscripts.com/marketplace/godot-pipalo. Lite is complete for
touch controls and never asks for payment.

## Licence

MIT, see LICENSE.md. Copyright (c) 2026 ПН СКРИПТС ЕООД (PN Scripts).
