# CrashIQ — System Architecture
# Godot 4.6 · GDScript 2.0 · Geopolitical Crisis Trading Simulator

---

## Project Directory Layout

```
crashiq/
├── autoloads/                  # Singleton autoloads (persistent across scenes)
│   ├── SimulationManager.gd    # Core state machine + all game data
│   ├── BehaviorTracker.gd      # Q-TPM scoring + pathway amplitude engine
│   ├── AudioManager.gd         # Audio stub (Session 5)
│   ├── GlobalInput.gd          # ESC key handler
│   └── DecisionManager.gd      # Legacy stub (pre-SimulationManager era, unused)
│
├── scripts/                    # Scene-attached scripts
│   ├── StartScreen.gd          # Difficulty selector (COMPLETE)
│   ├── MotivationCutscene.gd   # Academic framing cutscene (COMPLETE)
│   ├── MarketIntroCutscene.gd  # ETF intro panels (COMPLETE)
│   ├── SimulationScreen.gd     # Main simulation UI controller (ACTIVE)
│   ├── CandlestickChart.gd     # Custom chart renderer (ACTIVE)
│   ├── TradePanel.gd           # Order entry panel (WORKING)
│   ├── ProfileScreen.gd        # Post-game profile display (WORKING)
│   ├── TPMResultsScreen.gd     # Cycle summary + decisions list (WORKING)
│   ├── RadarChartControl.gd    # TPM 6-axis radar chart (WORKING)
│   ├── PLChartControl.gd       # Portfolio P&L line chart (WORKING)
│   ├── CrashCycle.gd           # Resource class for cycle data
│   ├── HeadlinePopup.gd        # Breaking news popup controller
│   ├── NewsTicker.gd           # Scrolling ticker (StartScreen)
│   ├── CrisisRing.gd           # Decorative ring (MarketIntro)
│   ├── ETFScreen.gd            # Legacy ETF panel (unused)
│   ├── DecisionPanel.gd        # Legacy decision panel (unused)
│   ├── SceneDebugLabel.gd      # Dev overlay
│   └── DebugScreenLabel.gd     # Dev overlay
│
├── scenes/                     # Scene files (.tscn)
│   ├── StartScreen.tscn
│   ├── MotivationCutscene.tscn
│   ├── MarketIntroCutscene.tscn
│   ├── SimulationScreen.tscn
│   ├── TPMResultsScreen.tscn
│   ├── ProfileScreen.tscn
│   ├── Main.tscn
│   ├── DecisionPanel.tscn      (legacy)
│   └── ETFScreen.tscn          (legacy)
│
├── CLAUDE.md                   # Codebase instructions for Claude Code
├── ARCHITECTURE.md             # This file
└── project.godot
```

---

## Scene Flow (Linear, No Branches Except Bankruptcy)

```
StartScreen.tscn
    │  Player selects difficulty tier (Student / Young Pro / Mid-career / Veteran)
    │  Sets SimulationManager cash + timer via set_difficulty()
    ▼
MotivationCutscene.tscn
    │  Academic framing — typewriter text — SPACE to continue
    ▼
MarketIntroCutscene.tscn
    │  Introduces all 4 ETFs with prices + behaviors — SPACE to continue
    ▼
SimulationScreen.tscn  ◄──────────────────────────────────────────┐
    │  5 cycles of crisis trading                                  │
    │  Each cycle: HEADLINE → TRADING → CYCLE_RESULT → repeat      │
    │                                                              │
    │  Bankruptcy path:                                            │
    │  cash + portfolio ≤ $1.00 → LiquidationOverlay shown        │
    │  Player can restart → returns to StartScreen                 │
    ▼
TPMResultsScreen.tscn
    │  Classification label, explanation, buy/sell/hold counts
    │  Per-cycle decision log
    │  CONTINUE button
    ▼
ProfileScreen.tscn
    │  Radar chart (6 TPM pathway amplitudes)
    │  P&L line chart (starting cash → cycle 1 → ... → cycle 5)
    │  Dominant pathway archetype + interpretation
    │  Learning delta (non-expedient amplitude shift across 5 cycles)
    │  PLAY AGAIN → resets SimulationManager + BehaviorTracker → StartScreen
```

---

## Autoload Architecture

### SimulationManager.gd
The single source of truth for all game state. All scenes read from and write to this.

```
State Machine
─────────────
START → BRIEFING → HEADLINE → TRADING → CYCLE_RESULT
                                  │
                                  └──(repeat 5x)──► PROFILE
                                  │
                                  └──(bankrupt)──► LIQUIDATED

Key Public Data
───────────────
cash: float                     Current player cash balance
holdings: Dictionary            { ticker: shares_float }
etf_prices: Dictionary          { ticker: current_price }
price_history: Dictionary       { ticker: Array[float] }  (40 pts per cycle, grows)
cycle_open_prices: Dictionary   { ticker: open_price_at_cycle_start }
current_cycle: int              1–5
selected_difficulty: String
starting_cash: float
decision_timer: float           Per-difficulty countdown in seconds
cycle_history: Array            Per-cycle trade + portfolio snapshots

Key Signals
───────────
difficulty_set(tier, cash, timer)
cycle_started(cycle_num, cycle_data)
headline_shown(headline, subtext)
trading_opened(time_limit)
trade_confirmed(trade_data)
cycle_complete(cycle_num, portfolio_value)
liquidation_triggered(final_data)
simulation_complete(final_data)

Key Methods
───────────
set_difficulty(tier)            → initializes cash, timer, resets state
start_next_cycle()              → snapshots open prices, applies price changes, emits signals
open_trading_phase()            → transitions to TRADING, emits trading_opened
confirm_trade(trade_data)       → validates + applies trade, checks bankruptcy, advances state
validate_trade(trade_data)      → pure validation, returns {ok, message, shares, estimated_total}
get_cycle_open_price(ticker)    → open price at start of current cycle (for reference line)
get_cycle_change(ticker)        → fractional change this cycle (e.g. -0.08)
get_portfolio_value()           → cash + sum(shares * price) for all ETFs
get_order_estimate(...)         → shares/total preview for UI
reset()                         → full game state reset
```

### BehaviorTracker.gd
Records player behavior each cycle and scores it against 6 TPM pathways.

```
Inputs per cycle
────────────────
time_to_decide: float           Seconds from trading_opened to trade_confirmed
info_panel_opened: bool         Did player open the ETF info panel?
info_panel_switches: int        How many times did player switch info panels?
etfs_checked: Array[String]     Which tickers did player view?
headline_reread: bool           Did player re-read the headline?
first_action: "INFO" | "HEADLINE"
trade_action: BUY | SELL | HOLD
etf_traded: String

Scoring Logic (_score_cycle)
──────────────────────────────
EXPEDIENT:    time < 5s AND no info panel         → 1.0 (or 0.5 if time < 8s)
ANALYTICAL:   info opened AND time > 10s          → 1.0 (or 0.5 if time > 5s)
VALUE_DRIVEN: same ETF as previous cycle          → 1.0
RULING_GUIDE: switches ≥ 2 AND checked all ETFs  → 1.0
REVISIONIST:  first_action=INFO AND reread AND bought during crash → 1.0
GLOBAL:       switches ≥ 3 AND macro ETF + up cycle → 1.0

Output
──────
get_final_amplitudes()      → averaged amplitude per pathway (0.0–1.0)
get_dominant_pathway()      → highest amplitude key
get_tpm_classification()    → human label (e.g. "Impulse Trader", "Contrarian")
get_tpm_explanation()       → 2–3 sentence behavioral interpretation
get_tpm_metrics()           → buy/sell/hold counts, avg decision time, risk label
get_learning_delta()        → change in non-expedient amplitude from cycle 1 → cycle 5
get_cycle_decisions()       → ordered Array of per-cycle decision snapshots
```

### AudioManager.gd
Stub only. No-op methods: `play_headline_sting()`, `play_crash_sfx()`, `set_tension_music(level)`, `stop_music()`. Implemented in Session 5.

### GlobalInput.gd
Handles ESC key globally. Currently prints and takes no action.

### DecisionManager.gd
Legacy autoload from pre-SimulationManager prototype. Maintains an old `profile` dict with coarse behavior labels. Not used by any active scene.

---

## SimulationScreen — Scene Structure

```
SimulationScreen.tscn
├── OuterMargin
│   └── MainColumn
│       ├── TopBarWrapper               Cycle label, headline, timer, cash, portfolio
│       ├── BodyRow
│       │   ├── LeftPanel (70%)
│       │   │   ├── ETF Tab Row         [CIQM] [CIQE] [CIQD] [CIQS] [CIQG]
│       │   │   ├── ActiveETFHeader     Large ticker + price + % change
│       │   │   ├── ActiveContextLabel  ETF behavior description (RichTextLabel)
│       │   │   ├── ChartArea           CandlestickChart node (active ETF)
│       │   │   ├── TimeRangeRow        [1D][1W][1M][3M][YTD][1Y][5Y][MAX] (cosmetic)
│       │   │   └── MiniCardRow         4 mini price cards for non-active ETFs
│       │   └── TradePanel (30%)        TradePanel.gd — order entry
│       └── HintLabel                   "SPACE to advance" hint text
├── HeadlinePopup                       HeadlinePopup.gd — breaking news overlay
│   ├── BreakingLabel                   "BREAKING" pulsing text
│   ├── HeadlineText                    Typewriter RichTextLabel
│   ├── SubtextText                     Subtext label
│   └── CountdownLabel                  "SPACE to trade" blink
├── ETFInfoPanel                        Modal info drawer
│   ├── InfoModalBG                     Clickable overlay to close
│   ├── InfoTickerLabel
│   ├── InfoNameLabel
│   ├── InfoDescLabel
│   └── InfoContextLabel
├── TransitionOverlay                   Cycle transition fade (2s)
└── LiquidationOverlay                  Bankruptcy end-state
    ├── LiquidationValueLabel
    ├── LiquidationCycleLabel
    └── RestartButton
```

---

## CandlestickChart.gd — Rendering Pipeline

```
Data Sources (priority order)
──────────────────────────────
1. full_data[]          If set via set_data(), chart renders this with reveal animation
2. _override_prices[]   Static price array override
3. SimulationManager    price_history + current price (live fallback)

Rendered Layers (draw order)
──────────────────────────────
1. Background fill              color_bg (#0d0d0d)
2. Border rect                  color_border (1px)
3. Focus highlight              color_up tint if _is_focused
4. Grid lines (3)               Horizontal at 25%/50%/75% with price labels
5. Fill polygon                 color_up or color_down at 13% alpha
6. Price polyline               1.5px colored line
7. Cycle boundary markers       Vertical red lines at each 40-point cycle boundary
8. Cycle labels (C1–C4)         Bottom-anchored red text + price at boundary
9. Open price reference line    Dashed horizontal line at cycle open price
10. Pulsing dot                 3-layer concentric circles at latest price point

Signals
───────
chart_info_requested(ticker)    Emitted on left-click → SimulationScreen opens info panel
                                + BehaviorTracker.record_info_panel_opened() called
```

---

## TradePanel.gd — Order Entry Flow

```
States
──────
Hidden:     Before trading_opened signal
Visible:    During TRADING state
Hidden:     After trade_confirmed / cycle_complete / liquidation

Order Entry
───────────
1. Select ETF      (driven by SimulationScreen._on_etf_selected)
2. Choose action   BUY | SELL tabs
3. Choose mode     DOLLARS | SHARES toggle
4. Enter quantity  LineEdit — live estimate updates
5. Review Order    Opens ReviewPopup (inline modal)
   ├── Shows: ETF name, shares, price, total
   ├── CONFIRM → SimulationManager.confirm_trade()
   └── CANCEL  → closes popup
6. HOLD button     Submits a HOLD trade directly (no review)

Validation
──────────
- BUY:  estimated_total ≤ cash
- SELL: shares_requested ≤ holdings[ticker]
- Zero quantity or zero price → invalid

Input attention pulse: quantity input border blinks yellow until player types
```

---

## ETF Data Table

| Ticker | Name               | Start  | Cycle Changes (1→5)                          | Behavior           |
|--------|--------------------|--------|----------------------------------------------|--------------------|
| CIQM   | CIQ Broad Market   | $100   | -8%, +5%, -18%, -12%, -25%                   | Falls in crisis    |
| CIQE   | CIQ Energy Fund    | $80    | +12%, +35%, +20%, -8%, +40%                  | Spikes on oil      |
| CIQD   | CIQ Defense Fund   | $90    | +15%, -8%, +25%, +30%, +15%                  | Rises with war     |
| CIQS   | CIQ Safe Haven     | $70    | +6%, +12%, +10%, +8%, +20%                   | Flight to safety   |
| CIQG   | CIQ Global Shipping| $60    | -5%, -22%, -15%, +15%, -30%                  | Collapse then pop  |

> Note: CIQG was added after initial design. CLAUDE.md documents 4 ETFs but 5 are active in code.
> CIQE cycle 4 is -8% (reversal) — energy dips when invasion signals Hormuz may reopen.
> CIQD cycle 2 is -8% (profit-taking) — defense pulls back between shock waves.

---

## 5-Cycle Escalation Arc

```
Cycle 1 — "Operation Epic Fury"
  CIQM -8%  CIQE +12%  CIQD +15%  CIQS +6%   CIQG -5%
  "Initial shock. Energy and defense lead. Watch for dip buyers."

Cycle 2 — "Strait Closed"
  CIQM -15%  CIQE +35%  CIQD -8%  CIQS +12%  CIQG -22%
  "Hormuz closes. Oil explodes. Defense profit-takes. Did you sell too early?"

Cycle 3 — "China Warns"
  CIQM -22%  CIQE +48%  CIQD +20%  CIQS +18%  CIQG -25%
  "China enters. Broad market resumes its fall. Defense surges on ground war expectations."

Cycle 4 — "Ground Invasion"
  CIQM -30%  CIQE +60%  CIQD +35%  CIQS +22%  CIQG -32%
  "Boots on the ground. Defense peaks. Shipping surprises to the upside."

Cycle 5 — "Gulf Mined"
  CIQM -40%  CIQE +75%  CIQD +28%  CIQS +30%  CIQG -38%
  "Gulf mined. Recession confirmed. Maximum fear. Every decision you made led here."
```

---

## ProfileScreen — Results Architecture

```
TPMResultsScreen.tscn  (first stop after SimulationScreen)
  ├── ClassificationLabel     e.g. "Contrarian"
  ├── ExplanationLabel        BehaviorTracker.get_tpm_explanation()
  ├── MetricsLabel            Risk tolerance / Reaction speed / Buy-Sell-Hold counts
  ├── DecisionsList           Per-cycle action log (color-coded BUY/SELL/HOLD)
  └── ContinueButton → ProfileScreen.tscn

ProfileScreen.tscn  (deep results)
  ├── RadarChartNode          RadarChartControl — 6-axis spider chart
  ├── PLChartNode             PLChartControl — portfolio value S→C1→C2→C3→C4→C5
  ├── ArchetypeLabel          Dominant pathway name
  ├── PathwaySignatureLabel   e.g. "I -> P -> D"
  ├── DifficultyLabel         Difficulty + starting cash
  ├── InterpLabel             Long interpretation paragraph
  ├── DeltaLabel              Learning delta (positive = grew more deliberate)
  ├── PathwayBreakdown        6-row bar chart (VBoxContainer, built in code)
  └── PlayAgainButton → SimulationManager.reset() + BehaviorTracker.reset() → StartScreen
```

---

## Signal Flow Diagram

```
Player selects difficulty
        │
        ▼
SimulationManager.set_difficulty()
        │ emits: difficulty_set
        ▼
SimulationScreen._on_difficulty_set()
        │
        │ (auto-calls start_next_cycle on BRIEFING state)
        ▼
SimulationManager.start_next_cycle()
        │ _snapshot_cycle_open_prices() — saves open, applies % change to etf_prices
        │ emits: cycle_started(cycle_num, CrashCycle)
        │ emits: headline_shown(headline, subtext)
        ▼
SimulationScreen._on_cycle_started()
        │ Plays headline typewriter animation (HeadlinePopup)
        │ Player presses SPACE
        ▼
SimulationScreen._handle_space_press()
        │ → _start_market_phase() → start_trading_phase()
        ▼
SimulationManager.open_trading_phase()
        │ emits: trading_opened(time_limit)
        ▼
TradePanel._on_trading_opened()          BehaviorTracker._on_trading_opened()
        │ (shows panel, starts timer)     │ (opens _current tracking dict)
        │                                 │
Player enters order + confirms
        │
        ▼
TradePanel._confirm_review()
        │ → SimulationManager.confirm_trade(trade_data)
        ▼
SimulationManager.confirm_trade()
        │ Validates + applies trade
        │ Checks bankruptcy (≤ $1.00)
        │ emits: trade_confirmed(normalized_trade)
        │ emits: cycle_complete(cycle_num, portfolio_value)  [if not bankrupt]
        │ emits: liquidation_triggered(final_data)           [if bankrupt]
        │ emits: simulation_complete(final_data)             [if cycle 5]
        ▼
BehaviorTracker._on_trade_confirmed()
        │ _score_cycle() → appends to _cycle_amplitudes
        │ emits: pathway_updated(amplitudes)
        ▼
SimulationScreen._on_cycle_complete()
        │ Waits 2.5s → SimulationManager.start_next_cycle()  [cycles 1–4]
        │ OR → TPMResultsScreen.tscn                          [after cycle 5]
```

---

## Key GDScript Patterns Used

| Pattern | Where | Purpose |
|---------|-------|---------|
| `queue_redraw()` every frame | CandlestickChart, RadarChartControl, PLChartControl | Custom `_draw()` canvas rendering |
| `await get_tree().create_timer(n).timeout` | SimulationScreen | Non-blocking delays between phases |
| Signal-driven state machine | SimulationManager → all scenes | Decoupled scene communication |
| Cancellation tokens (`_headline_reveal_token`) | SimulationScreen | Prevents stale async callbacks |
| `full_data[] + visible_points` reveal | CandlestickChart | Animated chart data reveal on cycle start |
| `modulate.a` visibility | SimulationScreen | Hides elements without layout shift in VBoxContainers |
| `%NodeName` unique name shorthand | All scripts | Scene node access without full paths |
| `randf_range() * base_price` noise | SimulationScreen._process() | Price label flicker during TRADING (display only, not data) |

---

## What Is Complete vs. Remaining

### Complete and working
- StartScreen — keyboard nav, difficulty cards, news ticker
- MotivationCutscene — typewriter, SPACE to advance
- MarketIntroCutscene — ETF intro panels
- SimulationScreen — layout, headline animation, tab switching, info panel, mini cards, cycle advance, liquidation overlay, price flicker, chart rendering
- CandlestickChart — polyline chart, pulsing dot, cycle boundary markers (C1–C4), open price reference line, animated reveal
- TradePanel — BUY/SELL/HOLD, review popup, order validation, fractional shares, input attention pulse
- SimulationManager — full state machine, all 5 cycles, price history, open price snapshotting, bankruptcy check
- BehaviorTracker — all 6 pathway scoring, amplitudes, classification, metrics, learning delta
- TPMResultsScreen — decision log, classification, explanation, metrics
- ProfileScreen — radar chart, P&L chart, pathway breakdown bars, learning delta
- RadarChartControl — 6-axis spider chart with custom _draw()
- PLChartControl — P&L line chart with starting cash reference line

### Remaining (per CLAUDE.md session plan)
- Session 3: Cycle transitions polish + bankruptcy edge cases
- Session 4: ProfileScreen radar chart tuning (already functional, may need visual pass)
- Session 5: AudioManager full implementation (currently stub)
- Session 5: CRT scanline overlay pass
- Session 5: Export / packaging
