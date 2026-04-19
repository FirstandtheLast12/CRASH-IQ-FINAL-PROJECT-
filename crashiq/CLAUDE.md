# CrashIQ — CLAUDE.md
# Geopolitical Crisis Trading Simulator · Behavioral Finance · Q-TPM Framework
# Godot 4.6 · Robinhood-style UI · Matrix Terminal Aesthetic
# Last updated: April 18 2026

---

## Project Status — Read This First

Most core systems are complete and working. Do NOT rebuild things that already exist.
The game is playable end-to-end: StartScreen → Motivation → MarketIntro → SimulationScreen (5 cycles) → TPMResultsScreen → ProfileScreen.

### COMPLETE AND WORKING — DO NOT TOUCH:
- StartScreen.tscn + StartScreen.gd — keyboard nav, difficulty cards, news ticker
- MotivationCutscene.tscn + MotivationCutscene.gd — typewriter effect, SPACE to continue
- MarketIntroCutscene.tscn + MarketIntroCutscene.gd — ETF intro panels
- autoloads/SimulationManager.gd — full state machine, all 5 cycles, price history, bankruptcy
- autoloads/BehaviorTracker.gd — all 6 TPM pathway scoring, amplitudes, classification
- autoloads/AudioManager.gd — stub (Session 5)
- autoloads/GlobalInput.gd — ESC handler stub
- scripts/CrashCycle.gd — resource class for cycle data
- scripts/HeadlinePopup.gd — breaking news overlay
- scripts/NewsTicker.gd — scrolling ticker on StartScreen
- scripts/CandlestickChart.gd — custom chart renderer with pulsing dot, cycle markers
- scripts/PLChartControl.gd — portfolio P&L line chart
- scripts/TPMResultsScreen.gd — classification, explanation, decision log

### ACTIVE / RECENTLY MODIFIED:
- scripts/SimulationScreen.gd — main gameplay controller (see session history below)
- scripts/TradePanel.gd — BUY/SELL/HOLD order entry; trade math fix applied April 18 2026
- scripts/RadarChartControl.gd — 6-axis TPM spider chart; per-pathway color system added April 18 2026
- scripts/ProfileScreen.gd — radar chart, P&L chart, pathway breakdown, learning delta

### REMAINING WORK:
- Session 3: Cycle transition polish + bankruptcy edge case review
- Session 5: AudioManager full implementation (currently stub)
- Session 5: CRT scanline overlay pass
- Session 5: Export / packaging
- Bug fix pending: TPM pathway descriptions for VALUE_DRIVEN and RULING_GUIDE are swapped in CrashIQ_Project_Context.md (does not affect runtime, is a documentation error)
- Radar chart: colors defined for EXPEDIENT only. Remaining 5 pathways (ANALYTICAL, VALUE_DRIVEN, RULING_GUIDE, REVISIONIST, GLOBAL) each need a distinct color assigned in the per-pathway color system (see RadarChartControl.gd section below).

---

## Academic Framework
Implements Rodgers' Throughput Model (TPM) from:
"Quantum-enhanced throughput pathways: Integrating Rodgers' TPM with quantum
ethical frameworks for AI-driven cybersecurity" (Acta Psychologica, 2026).
Professor: Waymond Rodgers, University of Texas El Paso. CIS 4301.

### TPM Pipeline
  P (Perception)   → crash headline + chart movement shown to player
  I (Information)  → ETF price panels, portfolio value, cash balance
  J (Judgment)     → player considers which ETF to buy/sell/hold
  D (Decision)     → player confirms trade · quantum state collapses

### 6 TPM Pathways — Correct Definitions
1. EXPEDIENT      P→D           Panic seller — reacts to headline, no data consulted
2. ANALYTICAL     I→J→D         Data-first — reads numbers before acting
3. Ruling_Guide   P→J→D         Rule-follower — consistent strategy regardless of data
4. Value_Driven   P→I→J→D       Full deliberator — works through every stage before acting
5. REVISIONIST    I→P→D         Contrarian — data reshapes perception, buys during crashes
6. GLOBAL         I→P→J→D       Systems thinker — full loop, macro-aware

NOTE: CrashIQ_Project_Context.md has VALUE_DRIVEN and RULING_GUIDE descriptions swapped.
The definitions above are correct. The code in BehaviorTracker.gd is correct.

---

## Difficulty Tiers
| Tier         | Starting Cash | Decision Timer              |
|--------------|---------------|-----------------------------|
| Student      | $500          | None (timer removed)        |
| Young Pro    | $5,000        | None (timer removed)        |
| Mid-career   | $25,000       | None (timer removed)        |
| Veteran      | $100,000      | None (timer removed)        |

Timer was removed in April 2026. All DIFFICULTY timer values in SimulationManager are 0.0.
`get_trading_time_remaining()` always returns 0.0. Player ends the cycle by pressing END CYCLE.

---

## The 5 Tradeable ETFs
NOTE: There are 5 ETFs, not 4. CIQG was added after initial design.
CLAUDE.md previously listed 4 — this is now corrected.

| Name                 | Ticker | Start | Behavior                          |
|----------------------|--------|-------|-----------------------------------|
| CIQ Broad Market     | $CIQM  | $100  | Falls in crisis                   |
| CIQ Energy Fund      | $CIQE  | $80   | Spikes on oil disruption          |
| CIQ Defense Fund     | $CIQD  | $90   | Rises with war escalation         |
| CIQ Safe Haven       | $CIQS  | $70   | Steady rise — flight to safety    |
| CIQ Global Shipping  | $CIQG  | $60   | Collapses — trade route disruption|

Player starts 100% cash. Fractional shares allowed.
Prices compound each cycle — end price of cycle N is start price of cycle N+1.

---

## The 5 Geopolitical Cycles — Iran War Escalation Arc
FULLY ESCALATORY. No stabilization. No Saudi neutrality.

Cycle 1 — "Operation Epic Fury"
Headline: "BREAKING: US & Israel launch Operation Epic Fury — airstrikes hit Iranian command, navy, and nuclear sites"
CIQM: -8%   CIQE: +12%   CIQD: +15%   CIQS: +6%   CIQG: -5%

Cycle 2 — "Strait Closed"
Headline: "BREAKING: Iran closes Strait of Hormuz — tankers under missile attack. 20% of global oil supply cut off"
CIQM: -15%   CIQE: +35%   CIQD: +8%   CIQS: +12%   CIQG: -22%

Cycle 3 — "China Warns"
Headline: "BREAKING: China warns US to stand down — Iran strikes Saudi oil facilities. Kuwait and UAE infrastructure hit"
CIQM: -22%   CIQE: +48%   CIQD: +20%   CIQS: +18%   CIQG: -25%

Cycle 4 — "Ground Invasion"
Headline: "BREAKING: US 82nd Airborne deployed — ground invasion begins to reopen Strait of Hormuz by force"
CIQM: -30%   CIQE: +60%   CIQD: +35%   CIQS: +22%   CIQG: -32%

Cycle 5 — "Gulf Mined"
Headline: "BREAKING: Iran mines Persian Gulf — global recession declared. Chinese naval vessels enter conflict zone"
CIQM: -40%   CIQE: +75%   CIQD: +28%   CIQS: +30%   CIQG: -38%

---

## Critical Architecture Rules — READ BEFORE TOUCHING ANY TRADING LOGIC

### SimulationManager.get_portfolio_value() already includes cash
Formula: total = cash + sum(holdings[ticker] * etf_prices[ticker] for all tickers)

NEVER do this:
  var total = SimulationManager.get_cash() + SimulationManager.get_portfolio_value()
  — this counts cash twice and shows wrong numbers everywhere

ALWAYS do this:
  var total = SimulationManager.get_portfolio_value()
  var cash  = SimulationManager.get_cash()     # only for the cash label
  var pnl   = total - SimulationManager.starting_cash

### Cycle prices update BEFORE trading opens
_snapshot_cycle_open_prices() runs inside start_next_cycle() before trading_opened is emitted.
When the player sees prices during TRADING state, those prices already reflect the cycle change.
portfolio_value_before in trade_data = value WITH new prices, WITHOUT the trade. This is correct.

### trade_confirmed emits BEFORE cycle_history.append()
In confirm_trade(), trade_confirmed signal fires before cycle_history is updated.
So in any handler connected to trade_confirmed, cycle_history.back() = PREVIOUS cycle's data.
This is intentional and used by _show_cycle_result() to compute cycle P&L correctly.

### Cycle 1 P&L is always ~$0
Players start with 100% cash, zero holdings. Cycle 1 price changes don't affect a cash-only
portfolio. Buying at market price has no immediate gain or loss. Real P&L only appears from
cycle 2 onward once the player holds positions that price moves can affect.

### Portfolio label vs Cash label vs Buying Power
- Cash label:      get_cash() only — money available to spend
- Portfolio label: get_portfolio_value() only — total wealth (cash + positions)
- P/L label:       get_portfolio_value() - starting_cash
- Buying power:    get_cash() only — same as cash label, used in TradePanel

---

## SimulationScreen.gd — Current State and What Was Changed

### Cycle Result Banner (_show_cycle_result)
REWRITTEN in April 2026 session. Previous version was a narrow banner anchored to the
top of the screen, hard to see, showed only for cycles 1–4, had only a fade animation.

Current implementation:
- Positioned at exact center of viewport (get_viewport_rect().size used for centering)
- 520×130px fixed size, z_index = 10 so it renders above all UI
- Slides in from the left with cubic ease-out (0.4s), holds for 2.6s, fades out (0.4s)
- Shows for ALL 5 cycles including cycle 5
- Displays cycle P&L: current portfolio value minus previous cycle's ending portfolio value
  (or starting_cash for cycle 1)
- Border and P&L text are green for profit, red for loss
- Three lines: "CYCLE N / 5 COMPLETE" · "+$X,XXX.XX this cycle" · "Portfolio total: $X,XXX.XX"

### Cycle Timing (_on_cycle_complete)
CHANGED from: 2.5s wait for cycles 1–4, immediate transition for cycle 5
CHANGED to:   3.5s wait for ALL cycles (gives banner time to complete)
This also means cycle 5 now waits 3.5s before going to TPMResultsScreen, same as other cycles.

### _on_simulation_complete
CHANGED: removed the immediate change_scene_to_file.call_deferred() that used to fire on
cycle 5. The scene transition for cycle 5 is now handled entirely by _on_cycle_complete
after the 3.5s wait, via _finish_game(). Removing the duplicate transition prevented a race
condition between the banner and the scene change.

### Portfolio/P&L Display (_update_portfolio_display)
FIXED double-counting bug: was computing total = get_cash() + get_portfolio_value()
which counted cash twice. Now correctly uses total = get_portfolio_value() only.
pnl_label modulate colors updated to Color("00ff41") / Color("ff4444") to match project standard.

---

## TradePanel.gd — Trade Execution Math Fix (April 18 2026)

### The Bug
`_build_trade_data()` was setting `quantity = _get_quantity_value()` which returns `dollars / price`
(i.e. shares), while simultaneously setting `quantity_mode = "DOLLARS"`. SimulationManager then
treated that shares number as a dollar amount and divided by price again, resulting in a
double-division. Buying $250 of CIQM (~$92/share) only deducted ~$2.72 from cash instead of $250.

### The Fix (line 204)
```gdscript
# BEFORE (wrong — double-divides):
var quantity_value: float = _get_quantity_value() if use_dollars else maxf(_quantity_input.text.to_float(), 0.0)

# AFTER (correct — raw user input, SimulationManager handles the conversion):
var quantity_value: float = maxf(_quantity_input.text.to_float(), 0.0)
```

`quantity` now equals the raw user input: dollars in DOLLARS mode, share count in SHARES mode.
SimulationManager's `get_order_estimate()` and `_apply_trade()` already correctly interpret
`quantity` based on `quantity_mode`. Fix applies to all ETFs, all cycles, all difficulty tiers.

---

## RadarChartControl.gd — Per-Pathway Color System (April 18 2026)

### What Was Added
`RadarChartControl` now supports per-dominant-pathway coloring with pulse animation.
Call `set_dominant(pathway: String)` after `set_amplitudes()` to activate.

### New API
```gdscript
func set_dominant(pathway: String) -> void   # call from ProfileScreen after set_amplitudes()
```

### How It Works
- `_dominant: String` stores the classified pathway name (e.g. "EXPEDIENT")
- `_pulse_t: float` accumulates in `_process()` only when dominant pathway is active
- `_draw()` computes `exp_active` and `color_exp` (pulsing RGBA) at the top, then:
  - Spoke for the dominant axis → colored and pulsing
  - Two polygon edges touching the dominant vertex → colored and thicker (2.5px)
  - Vertex dot at dominant axis → pulsing radius
  - Axis label for dominant pathway → same color
  - Center dot → dominant color, pulsing radius (drawn last, on top of everything)
  - All other elements draw normally in standard green

### EXPEDIENT Color (currently the only pathway with a custom color)
```gdscript
Color(1.0, 0.267, 0.267, pulse_alpha)   # red, pulsing alpha 0.60–1.00 at 3 rad/s
```
Chosen to signal "danger / panic decision" — red + pulsing communicates urgency.

### Extending to Other Pathways
To add colors for ANALYTICAL, VALUE_DRIVEN, RULING_GUIDE, REVISIONIST, GLOBAL:
1. Replace the `exp_idx` / `exp_active` / `color_exp` locals with a lookup from a
   `PATHWAY_COLORS: Dictionary` keyed by pathway name.
2. Each entry needs a Color. Pulse can be shared or per-pathway.
3. The drawing logic (spokes, edges, dots, label, center) already uses those locals —
   changing the lookup is the only structural change needed.

### ProfileScreen.gd Change
One line added after `_radar.set_amplitudes(amplitudes)`:
```gdscript
_radar.set_dominant(dominant)
```

---

## Known Bugs (BUGS-Found file)

1. FIXED (April 2026): Cycle result banner was at top of screen, hard to see, only showed
   for cycles 1-4. Now centered, slide-in animation, shows for all 5 cycles.

2. OPEN: "Press space to continue" label is flashing/glitching — not supposed to look like that.
   Likely a blink loop not stopping cleanly when advancing. Investigate _blink_headline_cta
   and _countdown_blinking flag in SimulationScreen.gd.

3. OPEN: Results screen (TPMResultsScreen) after cycle 5 only appears on certain pathways or
   via pause button. Should always appear after cycle 5 completes.
   Note: _on_simulation_complete change in April 2026 session may have affected this —
   verify the cycle 5 → TPMResultsScreen transition works correctly after session changes.

4. OPEN (documentation only): In CrashIQ_Project_Context.md, under 6 TPM pathways,
   RULING_GUIDE is described as "P-J-D Rule-follower" (belongs to VALUE_DRIVEN) and
   VALUE_DRIVEN is described as "P-I-J-D Full deliberator" (belongs to RULING_GUIDE).
   The two descriptions are swapped. Code is correct. Only the context doc needs fixing.

---

## SimulationScreen — Layout Reference (Current)

```
SimulationScreen.tscn
├── OuterMargin > MainColumn
│   ├── TopBarWrapper        Cycle label · headline · timer · Cash · Portfolio · P/L
│   ├── BodyRow
│   │   ├── LeftPanel (70%)
│   │   │   ├── ETF Tab Row  [CIQM] [CIQE] [CIQD] [CIQS] [CIQG] — 5 tabs
│   │   │   ├── ActiveETFHeader  ticker · price · % change this cycle
│   │   │   ├── ActiveContextLabel  PRIMARY EFFECT / INVESTOR BEHAVIOR (RichTextLabel)
│   │   │   ├── ChartArea    CandlestickChart for active ETF
│   │   │   ├── TimeRangeRow [1D][1W][1M][3M][YTD][1Y][5Y][MAX] (cosmetic only)
│   │   │   └── MiniCardRow  4 mini price cards for non-active ETFs
│   │   └── TradePanel (30%) BUY/SELL/HOLD order entry
│   └── HintLabel            "SPACE to advance" hint text
├── HeadlinePopup            Breaking news overlay with typewriter
├── ETFInfoPanel             Modal info drawer (click chart to open)
├── TransitionOverlay        Cycle transition fade
└── LiquidationOverlay       Bankruptcy end-state with restart button
```

---

## Visual Theme — Matrix Terminal
- Background:      #000000 pure black
- Primary text:    #00FF41 matrix green
- Data/numbers:    #FFFFFF white
- Headlines:       #FFD700 yellow
- Falling/loss:    #FF4444 red  (use Color("ff4444") in code)
- Rising/profit:   #00FF41 green (use Color("00ff41") in code)
- BUY button:      #00FF41
- SELL button:     #FF4444
- HOLD button:     #FFD700
- Font:            monospace throughout
- Effects:         CRT scanlines 10% opacity, screen flicker, blinking cursor

---

## Game Flow
1. StartScreen        → ENTER to select difficulty → sets SimulationManager via set_difficulty()
2. MotivationCutscene → SPACE to continue
3. MarketIntroCutscene → SPACE to continue
4. SimulationScreen   → 5 cycles: HEADLINE → TRADING → cycle result banner → repeat
5. TPMResultsScreen   → classification, explanation, decision log, CONTINUE button
6. ProfileScreen      → radar chart, P&L chart, pathway breakdown, PLAY AGAIN

---

## Godot 4.6 Critical Rules
- GDScript 2.0 only
- NO class_name on autoload scripts — causes "hides autoload singleton" error
- Access autoloads by registered name only (SimulationManager, BehaviorTracker, etc.)
- var not const for Arrays/Dictionaries
- visible=true/false inside VBoxContainer causes layout shift — use modulate.a instead
- RichTextLabel typewriter: use visible_characters property, not manual text slicing
- mouse_filter = MOUSE_FILTER_IGNORE on decorative child nodes to prevent hover flicker
- Blinking/pulsing elements must NOT be inside layout containers — use absolute positioning
- When adding dynamic Control nodes for overlay effects (banners, popups), set z_index and
  use set_anchors_preset(PRESET_TOP_LEFT) with explicit position and size for predictable layout
- Use is_instance_valid(node) before queue_free() on nodes created in async coroutines

## BehaviorTracker Scoring Per Cycle
expedient:    time_to_decide < 5.0 AND NOT info_panel_opened
analytical:   info_panel_opened AND time_to_decide > 10.0
value_driven: same ETF as previous cycle (not HOLD)
ruling_guide: info_panel_switches >= 2 AND all 5 ETFs checked
revisionist:  info_panel_opened FIRST AND reread headline AND bought during crash
global:       info_panel_switches >= 3 AND macro-positive ETF (CIQE/CIQD/CIQS going up)

## Do NOT Rebuild — These Work
StartScreen, MotivationCutscene, MarketIntroCutscene, all autoloads,
TradePanel, CandlestickChart, RadarChartControl, PLChartControl,
HeadlinePopup, TPMResultsScreen, ProfileScreen
