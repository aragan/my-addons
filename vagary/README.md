# Vagary Addon

Author: **Aragan**  
Addon: `vagary`

## Overview
`vagary` is a lightweight HUD tracker for Vagary objectives.

It tracks two lines:
- `Perfidien`
- `Plouton`

Each line shows:
- Current step number (`[1/3]`, `[2/3]`, `[3/3]`)
- Required `KI`

## Load / Unload
- `//lua load vagary`
- `//lua unload vagary`

## Commands
- `//vagary help`
- `//vagary reset`
- `//vagary show`
- `//vagary hide`
- `//vagary pos <x> <y>`

## HUD Commands
- `//vagary hud on`  
  Show HUD in any zone.
- `//vagary hud off`  
  Restrict HUD to Vagary zones only.
- `//vagary hud toggle`
- `//vagary hud status`
- `//vagary hud <x> <y>`  
  Move HUD and force show-anywhere mode.

## Display Modes
- `//vagary mode full`
- `//vagary mode short`

`short` mode shows:
- Monster name
- Step number
- KI only

## Text Color Modes
- `//vagary text gold`
- `//vagary text blue`
- `//vagary text purple`
- `//vagary text status`

Color mode applies to:
- Line text
- `KI:`

## Notes
- HUD is draggable with mouse.
- HUD position is auto-saved.
- Default behavior: HUD appears only in Vagary zones.
