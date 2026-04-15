# CrashIQ — Full Project Context Document
# For use with any AI assistant to maintain continuity
# Last updated: April 2026

---

## What is CrashIQ?

CrashIQ is a playable Godot 4.6 game demo being built as a college group project deliverable. It is a geopolitical crisis trading simulator that teaches behavioral finance through gameplay. The game is grounded in real events — the 2026 US-Iran war — and uses a fictional market to simulate how real investors behave during a crisis.

The game has two purposes:
1. Educational — teach players how different financial instruments (ETFs) respond to geopolitical crises
2. Academic — demonstrate Professor Waymond Rodgers' Quantum-Enhanced Throughput Model (Q-TPM) by measuring the player's decision-making pathway across 5 trading cycles

---

## Academic Framework — Professor Rodgers' Q-TPM

The game is built for CIS 4301 at the University of Texas El Paso, taught by Professor Waymond Rodgers, the co-author of:

"Quantum-enhanced throughput pathways: Integrating Rodgers' TPM with quantum ethical frameworks for AI-driven cybersecurity" (Acta Psychologica, 2026)

### Rodgers' Throughput Model (TPM)
Every decision cycle in the game runs the player through 4 cognitive stages:
- P (Perception) — the crash headline and chart movement shown to the player
- I (Information) — ETF price panels, portfolio value, cash balance
- J (Judgment) — player considers which ETF to buy/sell/hold
- D (Decision) — player confirms trade — quantum state collapses

There is also a bidirectional P-I recursive feedback loop — the player can toggle between the headline and data panels before deciding, and the game tracks this behavior.

### The 6 TPM Pathways (mapped to investor archetypes)

1. EXPEDIENT      P-D           Panic seller — reacts to headline immediately, no data consulted
2. ANALYTICAL     I-J-D         Data-first — ignores framing, reads numbers before acting
3. VALUE_DRIVEN   P-J-D         Rule-follower — consistent strategy regardless of data
4. RULING_GUIDE   P-I-J-D       Full deliberator — works through every stage before acting
5. REVISIONIST    I-P-D         Contrarian — data reshapes perception, buys during crashes
6. GLOBAL         I-P-J-D       Systems thinker — full loop, macro-aware decisions

### Quantum Superposition Mechanic
Before the player acts, their behavioral state is modeled as a superposition of all 6 pathways. When the player confirms a trade, the state collapses into a measured pathway based on WHAT they traded and HOW they decided (speed, info consulted, consistency).

### PRIMARY REQUIREMENT: Expedient Pathway (P-D)
The game specifically showcases Pathway 1 (Expedient) as the primary academic focus. A player acting Expedient sees the crash headline and immediately confirms a panic sell WITHOUT opening any info panels, decides in under 5 seconds, and does not consult portfolio data.

---

## The Game Scenario — Iran War 2026

The game is set during the real 2026 US-Iran war which began February 28, 2026 with Operation Epic Fury. This is not fictional — it is a real ongoing conflict at the time of development.

### The 5 Escalatory Cycles (fully escalatory — no stabilization, no Saudi neutrality)

Cycle 1 — "Operation Epic Fury"
Headline: "BREAKING: US and Israel launch Operation Epic Fury — airstrikes hit Iranian command, navy, and nuclear sites"
CIQM: -8%   CIQE: +12%   CIQD: +15%   CIQS: +6%

Cycle 2 — "Strait Closed"
Headline: "BREAKING: Iran closes Strait of Hormuz — tankers under missile attack. 20% of global oil supply cut off"
CIQM: -15%   CIQE: +35%   CIQD: +8%   CIQS: +12%

Cycle 3 — "China Warns"
Headline: "BREAKING: China warns US to stand down — Iran strikes Saudi oil facilities. Kuwait and UAE infrastructure hit"
CIQM: -22%   CIQE: +48%   CIQD: +20%   CIQS: +18%

Cycle 4 — "Ground Invasion"
Headline: "BREAKING: US 82nd Airborne deployed — ground invasion begins to reopen Strait of Hormuz by force"
CIQM: -30%   CIQE: +60%   CIQD: +35%   CIQS: +22%

Cycle 5 — "Gulf Mined"
Headline: "BREAKING: Iran mines Persian Gulf — global recession declared. Chinese naval vessels enter conflict zone"
CIQM: -40%   CIQE: +75%   CIQD: +28%   CIQS: +30%

---

## The 4 Tradeable ETFs

CIQ Broad Market  | $CIQM | $100.00 start | Falls in crisis    | SPY / S&P 500 analog
CIQ Energy Fund   | $CIQE | $80.00 start  | Spikes in crisis   | XLE / USO / oil futures
CIQ Defense Fund  | $CIQD | $90.00 start  | Rises with war     | ITA / Lockheed / RTX
CIQ Safe Haven    | $CIQS | $70.00 start  | Rises with fear    | GLD / gold

Player starts 100% cash. Fractional shares allowed. Prices compound across cycles.

---

## Difficulty Tiers — Phase of Life

Student     | $500    | 30 second timer | First Robinhood account, learning basics
Young Pro   | $5,000  | 20 second timer | First job savings, real but limited risk
Mid-career  | $25,000 | 15 second timer | Family financial pressure, real stakes
Veteran     | $100,000| 10 second timer | Most to lose, maximum panic pressure

The timer gets shorter as stakes increase — creates more pressure to collapse into Expedient pathway (panic behavior) at higher difficulty levels.

---

## Player Actions (Robinhood-style)

BUY       — enter dollar amount or share count, confirm
SELL      — enter dollar amount or share count, confirm
HOLD      — skip cycle, do nothing
STOP-LOSS — set price floor before buying (advanced)

---

## Game Flow — Chronological Order

1. START SCREEN
   Keyboard navigation: LEFT/RIGHT arrows cycle difficulty cards, ENTER confirms
   Matrix terminal aesthetic: DEFCON TRADING SYSTEM v2.6 header
   CrashIQ title: "Crash" yellow, "IQ" green, blinking cursor
   4 difficulty cards with colored borders and hover glow effects
   News ticker scrolling real Iran war headlines in yellow at bottom
   SYSTEM READY label bottom right
   Card colors: Student=green, YoungPro=blue, MidCareer=yellow, Veteran=red

2. MOTIVATION CUTSCENE
   Personalized narrative based on selected difficulty
   Student: "The US just launched airstrikes on Iran. The Strait of Hormuz is closing.
   You have $500 in your Robinhood account and one thought: if there is going to be
   a war — you are going to profit from it."
   Yellow bold text, red dollar amounts, black background, typewriter effect
   PRESS SPACE TO CONTINUE (green flickering)

3. MARKET INTRO CUTSCENE
   Introduces all 4 ETFs with starting prices
   Explains what each ETF is and how it behaves during the Iran war
   Shows how many shares the player can afford at their difficulty tier
   Clickable cards show deeper explanation popup
   PRESS SPACE TO CONTINUE

4. SIMULATION SCREEN (5 CYCLES) — needs rebuild
   Robinhood-style two-column layout:
   Left 70%: active ETF chart with tab switcher, 3 mini charts below
   Right 30%: ORDER PANEL with BUY/SELL tabs, quantity input, estimated cost, HOLD button
   Countdown timer creates pressure
   BREAKING headline at top in red
   Charts: line chart with pulsing dot, green if rising red if falling
   Review Order popup before confirming trade
   Bankruptcy if portfolio reaches $0

5. PROFILE SCREEN
   Dominant TPM pathway archetype name
   Radar/spider chart of all 6 pathway amplitudes
   Cycle-by-cycle P&L line chart
   Behavioral interpretation paragraph
   Learning delta: did discipline improve across cycles?

---

## Visual Theme — Matrix Terminal + WarGames (1983)

Background:        #000000 pure black
Primary text:      #00FF41 matrix green
Data/numbers:      #FFFFFF white
Headlines/accents: #FFD700 yellow
Falling lines:     #FF0000 red
Rising lines:      #00FF41 green
BUY button:        #00FF41 bright green
SELL button:       #FF4444 red
HOLD button:       #FFD700 yellow
Font:              monospace throughout
Effects:           CRT scanlines 10% opacity, screen flicker, blinking cursor, pulsing dot on charts

---

## Technical Stack

Engine:          Godot 4.6.1 stable
Language:        GDScript 2.0
Platform:        Windows
Project folder:  C:\Users\great\Documents\crashiq

### Project Structure
crashiq/
  CLAUDE.md                    AI assistant context file
  project.godot
  autoloads/
    SimulationManager.gd       game state machine, 5 cycles, difficulty — COMPLETE
    BehaviorTracker.gd         Q-TPM scoring, pathway amplitudes — COMPLETE
    AudioManager.gd            music and sound effects — COMPLETE
  scenes/
    Main.tscn                  root scene — COMPLETE
    StartScreen.tscn           difficulty selector — COMPLETE
    MotivationCutscene.tscn    narrative intro — COMPLETE
    MarketIntroCutscene.tscn   ETF introduction — COMPLETE
    SimulationScreen.tscn      main gameplay — NEEDS REBUILD
    ProfileScreen.tscn         results screen — NEEDS TESTING
  scripts/
    CrashCycle.gd              data resource — COMPLETE
    HeadlinePopup.gd           COMPLETE
    TradePanel.gd              BUY/SELL not functional — NEEDS FIX
    NewsTicker.gd              COMPLETE
    ProfileScreen.gd           NEEDS TESTING
    RadarChartController.gd    NEEDS TESTING
    PLChartController.gd       NEEDS TESTING
    StartScreen.gd             COMPLETE
    MotivationCutscene.gd      COMPLETE
    MarketIntroCutscene.gd     COMPLETE
    SimulationScreen.gd        NEEDS REBUILD
  assets/
    fonts/
    sounds/
    videos/                    planned for background videos (not yet added)

---

## BehaviorTracker — Q-TPM Scoring

Per cycle records:
  time_to_decide: float          seconds from headline to CONFIRM
  info_panel_opened: bool        did player check any ETF data panel
  info_panel_switches: int       toggles between headline and data
  etfs_checked: Array            which ETF panels were opened
  trade_action: String           BUY / SELL / HOLD
  etf_traded: String             which ETF ticker
  stop_loss_set: bool
  perception_severity: float     how severe was the crash this cycle
  portfolio_value_before: float
  portfolio_value_after: float

Pathway amplitude rules:
  expedient:    time_to_decide < 5.0 AND NOT info_panel_opened
  analytical:   info_panel_opened AND time_to_decide > 10.0
  value_driven: same ETF traded as previous cycle
  ruling_guide: info_panel_switches >= 2 AND all 4 ETFs checked
  revisionist:  info_panel_opened BEFORE headline AND bought during crash
  global:       info_panel_switches >= 3 AND macro-aware trade

Final profile = average amplitude across all 5 cycles.

---

## Profile Screen Archetype Interpretations

EXPEDIENT:
"You reacted before you reflected. Every headline sent you to the confirm button before
your data panel. Under real market conditions this pattern costs investors 2-4% per
crash cycle. That is the Expedient pathway — perception collapsed directly into decision."

ANALYTICAL:
"You ignored the noise and read the numbers. Your decisions lagged the headline but led
the data — the hallmark of the Analytical pathway. In the 2026 Iran crisis traders who
held Energy and Defense outperformed the market by over 40%."

VALUE_DRIVEN:
"You had a rule and you stuck to it. Regardless of what the data showed your strategy
was consistent cycle over cycle. The Value-Driven pathway is rigid under chaos —
sometimes right, sometimes costly."

RULING_GUIDE:
"You worked every stage before committing. Headline, data, judgment, decision — in order,
every time. The Ruling Guide pathway is the most deliberate. Under a 10-second timer it
is nearly impossible. You did it."

REVISIONIST:
"You let data reshape your worldview before acting. Where others saw disaster you saw
information — then reframed the headline as signal. The Revisionist pathway is the
contrarian investor's cognitive signature."

GLOBAL:
"You thought in systems. Every trade accounted for the macro picture — not just one ETF
but how the whole portfolio responded to the crisis arc. The Global pathway is rare under
time pressure. You demonstrated it."

---

## Known Bugs and Gotchas (Godot 4.6)

1. NEVER use class_name on autoload scripts — causes "hides autoload singleton" error
2. Use var not const for Arrays and Dictionaries in GDScript 2.0
3. visible=true/false inside VBoxContainer causes layout shift — use modulate.a instead
4. RichTextLabel typewriter: use visible_characters property, not manual indexing
5. Mouse hover flickering: set mouse_filter=MOUSE_FILTER_IGNORE on child nodes
6. Blinking elements must NOT be inside layout containers — use absolute positioning
7. Claude Code token limit: break large prompts into chunks, set CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000
8. Scene nodes referenced in script must also exist in .tscn file

---

## Remaining Work Priority

1. SimulationScreen Robinhood UI layout rebuild
2. Trading mechanics — buy/sell execution with cash/portfolio updates
3. All 5 cycles advancing correctly
4. Bankruptcy condition — game over at $0
5. Profile screen radar chart validation
6. ETF intro screen polish
7. Video backgrounds (assets/videos/ folder created, awaiting .ogv files)
8. Export as playable demo

---

## How to Start a New AI Session on This Project

Paste the CLAUDE.md file contents as context, then state ONE focused task.
Keep prompts small — one feature per session.
Always reload from disk in Godot after Claude Code finishes.

Claude Code launch:
  cd C:\Users\great\Documents\crashiq
  claude

To increase token limit for large sessions:
  $env:CLAUDE_CODE_MAX_OUTPUT_TOKENS = "64000"
  claude
