# CrashIQ — Presentation Demo Plan
# For: Professor Rodgers CIS 4301 — UTEP
# Operator: Live demo by project lead
# Last updated: April 2026
# Verified against: SimulationManager.gd, BehaviorTracker.gd, TradePanel.gd

---

## OVERVIEW

Four live demos, one per difficulty tier, each demonstrating a distinct TPM pathway.
Same war. Same market. Same 5 cycles. Four investors — four completely different
behavioral signatures, four completely different outcomes.

Opening line to class:
"Same crisis. Same five ETFs. Four different investors.
Watch what their decisions reveal about how people actually process pressure."

Pathway arc across the four demos:
  Student    → EXPEDIENT    P→D           Panic. No information. Instant reaction.
  Young Pro  → ANALYTICAL   I→J→D         Data first. Deliberate. Information-driven.
  Mid-career → REVISIONIST  I→P→D         Contrarian. Data reshapes how they read the headline.
  Veteran    → VALUE_DRIVEN P→I→J→D       Consistent thesis. Same conviction every cycle.

---

## CODE FIXES — APPLIED (April 2026)

Fix 1 — APPLIED: BehaviorTracker.record_info_panel_opened() added to SimulationScreen.gd
  Location: SimulationScreen._on_chart_info_requested(), line after _select_ticker(ticker)
  Effect: info_panel_opened now correctly tracks when the player clicks a chart.
  Demos unblocked: Demo 2 (ANALYTICAL) and Demo 3 (REVISIONIST).

Fix 2 — APPLIED: EXPEDIENT time threshold removed from BehaviorTracker._score_cycle()
  Old: EXPEDIENT required time_to_decide < 5.0s AND no info panel
  New: EXPEDIENT scores 1.0 if no info panel opened (any speed)
  ANALYTICAL time threshold kept (> 10s for 1.0, > 5s for 0.5 partial)
  Effect: Demo 1 (EXPEDIENT) now classifies correctly without timing pressure during narration.
  Demo 4 (VALUE_DRIVEN) still works — see "Why Timing Still Matters for Demo 4" below.

---

## BUG CATALOG — Do Not Fix Yet

Bug 1: FIXED (April 2026). record_info_panel_opened() added to SimulationScreen._on_chart_info_requested().
  Was: info_panel_opened always false — ANALYTICAL and REVISIONIST could never classify.
  Now: Fixed with one line: BehaviorTracker.record_info_panel_opened(ticker).

Bug 2: CLAUDE.md cycle change values do not match ETF_DATA in SimulationManager.gd
  Impact: Documentation confusion only. Pricing at runtime is correct.
  Fix: Update CLAUDE.md cycle change table to match ETF_DATA arrays.
  Demos affected: None (runtime unaffected).

Bug 3: CrashCycle.etf_changes set in _build_cycles() does not match ETF_DATA.cycle_changes
  Impact: The CrashCycle resource carries stale/wrong etf_changes values.
  Pricing is correct because _snapshot_cycle_open_prices() uses ETF_DATA, not CrashCycle.
  Fix: Align CrashCycle.etf_changes with ETF_DATA or remove the field from _build_cycles.
  Demos affected: None (runtime unaffected).

Bug 4: FIXED (April 2026).
  EXPEDIENT time threshold removed — now scores purely on no info panel (any speed).
  ANALYTICAL time threshold kept (> 10s for 1.0, > 5s for 0.5 partial) so VALUE_DRIVEN
  can still dominate Demo 4 when the presenter stays under 10s per cycle.
  Demo 1 now narrates freely without any timing pressure.
  Demo 4 sweet spot: open CIQD panel, confirm within 8-9s → ANALYTICAL = 0.5, VALUE_DRIVEN = 1.0.

---

## BEFORE YOU START — Setup Checklist

- Both code fixes already applied (April 2026) — no pre-demo code changes needed
- Game open on StartScreen, fullscreen or maximized
- This document open on phone or second screen
- Know the flow: SPACE to open markets after headline, END CYCLE to close the cycle
- No timers exist. You control all pacing. END CYCLE is the only way to advance.
- Multiple BUY and SELL trades can be made within one cycle before END CYCLE
- SCORING NOTE: Only your FIRST confirmed trade each cycle registers with BehaviorTracker.
  Subsequent trades in the same cycle are not scored.

---

## GROUND TRUTH — ETF PRICES AT EACH CYCLE OPEN

Sourced directly from ETF_DATA.cycle_changes arrays in SimulationManager.gd.
These are the prices when the trading phase opens each cycle.

| ETF  | Start  | C1 Open | C2 Open | C3 Open | C4 Open | C5 Open |
|------|--------|---------|---------|---------|---------|---------|
| CIQM | $100   | $92.00  | $96.60  | $79.21  | $69.70  | $52.28  |
| CIQE | $80    | $89.60  | $120.96 | $145.15 | $133.54 | $186.96 |
| CIQD | $90    | $103.50 | $95.22  | $119.03 | $154.74 | $177.95 |
| CIQS | $70    | $74.20  | $83.10  | $91.41  | $98.72  | $118.46 |
| CIQG | $60    | $57.00  | $44.46  | $37.79  | $43.46  | $30.42  |

Cycle-by-cycle percent changes (authoritative — from code, not CLAUDE.md):

| ETF  | C1     | C2     | C3     | C4     | C5     |
|------|--------|--------|--------|--------|--------|
| CIQM | -8%    | +5%    | -18%   | -12%   | -25%   |
| CIQE | +12%   | +35%   | +20%   | -8%    | +40%   |
| CIQD | +15%   | -8%    | +25%   | +30%   | +15%   |
| CIQS | +6%    | +12%   | +10%   | +8%    | +20%   |
| CIQG | -5%    | -22%   | -15%   | +15%   | -30%   |

KEY MOVEMENTS TO NARRATE:
- CIQM bounces +5% in C2 — the "dip buyers entered" moment
- CIQE drops -8% in C4 — energy reverses as invasion signals Hormuz may reopen
- CIQD drops -8% in C2 — profit-taking after initial shock, thesis test for Veteran
- CIQG spikes +15% in C4 — surprise upside; collapses -30% in C5

---

## BEHAVIORTRACKER SCORING REFERENCE (from BehaviorTracker._score_cycle())

EXPEDIENT (1.0):    info_panel NOT opened (any speed — time_to_decide removed)

ANALYTICAL (1.0):   info_panel WAS opened AND time_to_decide > 10.0s
                    Partial (0.5) if info opened AND time > 5.0s

VALUE_DRIVEN (1.0): Same ETF traded (BUY or SELL) as the previous cycle
                    Requires non-HOLD action with same ticker as _prev_etf_traded

RULING_GUIDE (1.0): info_panel_switches >= 2 AND all 5 ETFs opened (not used in this demo)

REVISIONIST (1.0):  info_panel opened as FIRST action (first_action == "INFO")
                    AND headline reread (click dark backdrop to close panel)
                    AND action is BUY
                    AND CIQM is falling this cycle (crash cycle)

GLOBAL (1.0):       info_panel_switches >= 3 AND traded CIQE/CIQD/CIQS when rising
                    (not used in this demo)

time_to_decide:     Real wall-clock seconds from trading_opened to first confirm_trade.
                    Measured by TradePanel._elapsed_decision_time() regardless of timer setting.

CRASH CYCLES (CIQM falling — required for REVISIONIST):
C1 YES (-8%)  |  C2 NO (+5%)  |  C3 YES (-18%)  |  C4 YES (-12%)  |  C5 YES (-25%)

HOW TO OPEN AN INFO PANEL:
Click directly on any chart. The ETFInfoPanel drawer opens.
This is what triggers BehaviorTracker.record_info_panel_opened() (after the bug fix).
To register "headline reread": click the DARK BACKGROUND behind the drawer to close it.
Any other close method does not register headline_reread.

---

## DEMO 1 — EXPEDIENT PATHWAY (P → D)
## Difficulty: STUDENT — $500

### What This Demonstrates
The panic investor. Perception collapses directly into Decision.
No information gathering. No judgment. Pure emotional reaction to headlines.
P → D. The two fastest stages. Everything in between is skipped.

### Rule: Do NOT open any chart panel. EXPEDIENT scores when no info panel is opened.
### Narrate before pressing SPACE to open markets or after pressing END CYCLE — not during.

---

### CYCLE 1 — Operation Epic Fury
Headline: US and Israel launch airstrikes on Iran.
CIQM opens at $92.00

INPUT: Action = BUY | Mode = DOLLARS | ETF = CIQM | Amount = 400 | Confirm → END CYCLE

Result: ~4.3478 shares CIQM purchased at $92.00
Cash: $100.00 | CIQM position open | Portfolio: $500.00

Say: "War starts. Broad market is already falling. No research. We buy in. P to D."

C1 score: EXPEDIENT (no panel opened)

---

### CYCLE 2 — Strait of Hormuz Closes
Headline: Iran closes Strait. 20% of global oil cut off.
CIQM opens at $96.60 (+5% bounce) | CIQE opens at $120.96 (+35%)

INPUT: No trade → END CYCLE

Result: Cash $100.00 | CIQM position @ $96.60 = $420.00 | Portfolio: $520.00

Say: "Strait closes. Too scary. We freeze. CIQE went from $89 to $121 — we missed it.
CIQM actually bounced this cycle. We did not notice."

C2 score: EXPEDIENT (no panel opened)

---

### CYCLE 3 — China Warns
Headline: China warns US. Saudi oil facilities struck.
CIQM opens at $79.21 — below the $92.00 we paid

INPUT: Action = SELL | Mode = DOLLARS | ETF = CIQM | Amount = ALL SHARES | Confirm → END CYCLE
(For a full sell, enter the full dollar value of your position shown on screen, or use shares mode and enter your share count)

Result: Full CIQM position sold at $79.21 = $344.40 received
Cash: $100.00 + $344.40 = $444.40 | Portfolio: $444.40

Say: "China enters. CIQM is below what we paid. Panic sell. Bought at $92, sold at $79.
CIQE is at $145 right now — up 62% from the start. We have none of it."

C3 score: EXPEDIENT (no panel opened)

---

### CYCLE 4 — Ground Invasion
Headline: 82nd Airborne deployed. Ground invasion begins.
CIQM opens at $69.70

INPUT: Action = BUY | Mode = DOLLARS | ETF = CIQM | Amount = 300 | Confirm → END CYCLE

Result: ~4.3042 shares CIQM purchased at $69.70
Cash: $144.40 | CIQM position open | Portfolio: $444.40

Say: "Down 31 percent from the start. Looks cheap. We buy back in.
We sold at $79. We are now buying at $69. This is the retail trap."

C4 score: EXPEDIENT (no panel opened)

---

### CYCLE 5 — Gulf Mined
Headline: Iran mines Persian Gulf. Global recession declared.
CIQM opens at $52.28 — our C4 buy was at $69.70

INPUT: Action = SELL | Mode = DOLLARS | ETF = CIQM | Amount = ALL SHARES | Confirm → END CYCLE

Result: Full CIQM position sold at $52.28 = $225.00 received
Cash: $144.40 + $225.00 = $369.40 | Portfolio: $369.40

Say: "Gulf mined. Recession. We sell again. Bought at $69, sold at $52. Second loss.
CIQE finished at $187 — up 134% from the start. We never held it once."

C5 score: EXPEDIENT (no panel opened)

---

### DEMO 1 RESULT
Starting cash:   $500.00
Final portfolio: $369.40
Loss:            -$130.60 (-26.1%)
TPM Profile:     EXPEDIENT — Impulse Trader
Classification:  "You moved fast and skipped analysis. Decisions fired before
                  the full picture settled — speed dominated over deliberation."

Closing statement for Demo 1:
"The Expedient pathway. P arrow D. Five cycles, five headline reactions,
zero information consulted. We lost 26 percent not from bad luck —
from a pattern. The quantum state collapsed without deliberation every time."

---

## DEMO 2 — ANALYTICAL PATHWAY (I → J → D)
## Difficulty: YOUNG PRO — $5,000

### What This Demonstrates
Information comes before everything. Judgment follows data.
The investor who ignores the emotional framing and reads the numbers.
I → J → D. The headline is noise. The data is signal.

### Behavioral Requirements Each Cycle
- OPEN at least one chart info panel BEFORE confirming your first trade
- Wait AT LEAST 10-12 seconds after trading opens before clicking Confirm
  (use this deliberation time to narrate to the class — dual purpose)
- Open 1-2 panels per cycle maximum (3+ risks scoring GLOBAL instead)
- You can make multiple trades per cycle — only the FIRST trade is scored
- REQUIRES the info panel bug fix to classify correctly.

---

### CYCLE 1 — Operation Epic Fury
CIQE opens at $89.60. Broad market falling. Energy rising.

INFORMATION: Click the CIQE chart — panel opens.
Say while waiting 10+ seconds: "Information stage. We do not look at the headline.
We look at the data. Energy supply shock from a Middle East conflict.
Hormuz is threatened. CIQE rises when Hormuz is at risk. We have seen this before."
JUDGMENT: Energy is the right position given the event structure.
DECISION: Close panel, BUY CIQE $2,000, Confirm.

Trade: BUY CIQE $2,000 → 22.32 shares at $89.60
Cash: $3,000 | CIQE: 22.32 shares | Portfolio: $5,000
Press END CYCLE.

C1 score: ANALYTICAL (info opened + time > 10s)

---

### CYCLE 2 — Strait Closed
CIQE opens at $120.96 (+35%). CIQD opens at $95.22 (pulled back 8%).

INFORMATION: Click CIQE chart (see +35% gain). Then click CIQD chart.
Say while waiting: "CIQE is up 35 percent. Energy thesis is working.
Now Defense — it pulled back 8 percent on profit-taking. That is a buy signal.
Ground operations are coming. Defense contractors benefit from escalation."
JUDGMENT: Rotate additional capital into Defense. CIQE still held.
DECISION: BUY CIQD $1,500, Confirm.

Trade: BUY CIQD $1,500 → 15.75 shares at $95.22
Cash: $1,500 | CIQE: 22.32 | CIQD: 15.75
CIQE value: 22.32 * $120.96 = $2,699.87
Portfolio after C2: $5,699.87 (+$699.87)
Press END CYCLE.

C2 score: ANALYTICAL (info opened + time > 10s)

---

### CYCLE 3 — China Warns
CIQE opens at $145.15 (+20%). CIQD opens at $119.03 (+25%).

INFORMATION: Click CIQE chart.
Say while waiting: "Energy up another 20 percent. But China entering changes the macro.
A ground invasion is coming — that benefits Defense, not oil futures.
Energy's thesis is complete. Time to rotate out before the reversal."
JUDGMENT: Exit CIQE. Defense is next leg. Keep CIQD.
DECISION: SELL all CIQE, Confirm. Then press END CYCLE.
(Do NOT open a second panel after selling — one trade, one score.)

Trade: SELL all CIQE → 22.32 shares at $145.15 = $3,239.75
Cash: $1,500 + $3,239.75 = $4,739.75
CIQD still held: 15.75 @ $119.03 = $1,875.22
Portfolio after C3: $6,614.97 (+$915.10 this cycle)
Press END CYCLE.

C3 score: ANALYTICAL (info opened + time > 10s, SELL CIQE)

---

### CYCLE 4 — Ground Invasion
CIQD opens at $154.74 (+30%). CIQS opens at $98.72 (+8%).
Note: CIQE dropped -8% to $133.54 this cycle — confirms C3 exit was right.

INFORMATION: Click CIQD chart.
Say while waiting: "Defense up 30 percent. Ground invasion is fully priced in now.
When the event is priced, you exit. We sell Defense.
We rotate to Safe Haven — maximum fear cycle is coming in C5."
JUDGMENT: Exit Defense. Enter Safe Haven before the final escalation.
DECISION: SELL all CIQD, Confirm. Then BUY CIQS $2,000, Confirm. END CYCLE.
(SELL CIQD is the scored first trade. BUY CIQS is second — not scored but portfolio counts.)

Trade 1 (scored): SELL all CIQD → 15.75 at $154.74 = $2,437.16
Cash: $4,739.75 + $2,437.16 = $7,176.91
Trade 2 (not scored): BUY CIQS $2,000 → 20.26 shares at $98.72
Cash: $5,176.91 | CIQS: 20.26 shares
Portfolio after C4: $7,176.91 (+$561.94 this cycle)
Press END CYCLE.

C4 score: ANALYTICAL (info opened + time > 10s, SELL CIQD)

---

### CYCLE 5 — Gulf Mined
CIQS opens at $118.46 (+20%). Maximum fear environment.

INFORMATION: Click CIQS chart.
Say while waiting: "Gulf mined. Recession. Maximum fear.
Safe Haven rises in exactly this environment. The data says hold.
No action needed. The Analytical pathway does nothing when the data says stay."
JUDGMENT: Hold Safe Haven through the peak fear event.
DECISION: END CYCLE (HOLD). No trade.

CIQS: 20.26 * $118.46 = $2,400.00
Portfolio after C5: $5,176.91 + $2,400.00 = $7,576.91
Press END CYCLE.

C5 score: ANALYTICAL (info opened + time > 10s, HOLD)

---

### DEMO 2 RESULT
Starting cash:   $5,000.00
Final portfolio: $7,576.91
Gain:            +$2,576.91 (+51.5%)
TPM Profile:     ANALYTICAL — Strategic
Classification:  "You checked the data before acting and took your time.
                  Your pattern points to calculated positioning driven
                  by information rather than panic."

Closing statement for Demo 2:
"The Analytical pathway. I arrow J arrow D. Information before every decision.
Judgment before every trade. The broad market fell 25 percent.
We made 51 percent — by reading data instead of headlines."

---

## DEMO 3 — REVISIONIST PATHWAY (I → P → D)
## Difficulty: MID-CAREER — $25,000

### What This Demonstrates
Data comes first and reshapes how the investor reads the headline.
Where others see disaster, the Revisionist sees signal.
I → P → D. Information reframes perception. Then the decision follows.

### Behavioral Requirements Each Cycle
- REVISIONIST requires ALL of these simultaneously:
  1. Click a chart as your ABSOLUTE FIRST ACTION when trading opens
     (before clicking anything else — this sets first_action = INFO)
  2. Action must be BUY (not SELL or HOLD)
- All 5 cycles are BUY + info-first → REVISIONIST scores 5/5 = 1.0
- ANALYTICAL also fires each cycle (info panel opened) but only averages 1.0 too — REVISIONIST
  wins the tie because it is the last key in the amplitude dictionary.

---

### CYCLE 1 — Operation Epic Fury
CIQM opens at $92.00 (-8%). CIQE opens at $89.60. CIQS opens at $74.20. Crash cycle.

INFORMATION FIRST: Immediately click the CIQM chart when trading opens — before anything else.
Say while looking at panel: "Before reading the headline — we check the data.
Broad market is already down. Let us read the signal before the crowd interprets the headline."
PERCEPTION REFRAMED: "The headline confirms what the data already told us."
DECISION: BUY CIQM $3,000, Confirm. Then BUY CIQE $8,000, Confirm. Then BUY CIQS $4,000, Confirm. END CYCLE.

Trade 1 (scored): BUY CIQM $3,000 → 32.61 shares at $92.00
Trade 2 (not scored): BUY CIQE $8,000 → 89.29 shares at $89.60
Trade 3 (not scored): BUY CIQS $4,000 → 53.91 shares at $74.20
Cash: $10,000 | CIQM: 32.61 | CIQE: 89.29 | CIQS: 53.91 | Portfolio: $25,000
Press END CYCLE.

C1 score: REVISIONIST (info first — CIQM chart, BUY CIQM during crash cycle) = 1.0

---

### CYCLE 2 — Strait Closed
CIQM opens at $96.60 — it BOUNCED (+5%). NOT a crash cycle.
CIQE at $120.96 (+35%). CIQS at $83.10 (+12%).

INFORMATION FIRST: Immediately click the CIQD chart when trading opens — before anything else.
Say while looking: "Strait closes. Naval conflict accelerates defense contracts. Before reading
the headline — we check CIQD. The data confirms the thesis."
PERCEPTION REFRAMED: "We read the defense signal before the headline told us to."
DECISION: BUY CIQD $2,000, Confirm. Then SELL all CIQM, Confirm. END CYCLE.
(BUY CIQD is scored. SELL CIQM is unscored — clears the position after the first trade registers.)

Trade 1 (scored): BUY CIQD $2,000 → 21.00 shares at $95.22
Trade 2 (unscored): SELL all CIQM → 32.61 shares at $96.60 = $3,150
Cash: $11,150 | CIQD: 21.00 | CIQE: 89.29 | CIQS: 53.91
CIQE value: $10,800 | CIQS value: $4,480 | CIQD value: $2,000
Portfolio after C2: $28,430 (+$3,430 this cycle)
Press END CYCLE.

C2 score: REVISIONIST (info first — CIQD chart, BUY CIQD, first_action = INFO) = 1.0

---

### CYCLE 3 — China Warns
CIQD opens at $119.03 (+25%). CIQM at $79.21. Crash cycle (CIQM -18%).

INFORMATION FIRST: Immediately click the CIQD chart when trading opens — before anything else.
Say while looking: "China enters. Saudi oil facilities hit. Defense contracts accelerate.
CIQD is up 25 percent this cycle — the data shows the thesis before the headline confirms it."
PERCEPTION REFRAMED: "We read the signal before reading the headline. Data first."
DECISION: BUY CIQD $5,000, Confirm. END CYCLE.

Trade (scored): BUY CIQD $5,000 → 42.01 shares at $119.03
Cash: $6,150 | CIQD: 63.01 (21.00 + 42.01) | CIQE: 89.29 | CIQS: 53.91
CIQE: 89.29 * $145.15 = $12,960 | CIQS: 53.91 * $91.41 = $4,928 | CIQD: 63.01 * $119.03 = $7,501
Portfolio after C3: $31,539 (+$3,109 this cycle)
Press END CYCLE.

C3 score: REVISIONIST (info first — CIQD chart, BUY CIQD during crash cycle) = 1.0

---

### CYCLE 4 — Ground Invasion
CIQG opens at $43.46 — surprise +15% spike. Crash cycle (CIQM -12%).
Note: CIQE dropped -8% to $133.54. CIQD now at $154.74 (+30%).

INFORMATION FIRST: Immediately click the CIQG chart when trading opens — before anything else.
Say while looking: "Shipping has been falling all war. But look — up 15 percent.
Ground invasion signals Hormuz may reopen. Shipping rerouting creates demand.
The data shows a counterintuitive signal the crowd is not positioned for."
PERCEPTION REFRAMED: Others see a collapsing sector. Revisionist sees reopening thesis.
DECISION: BUY CIQG $5,000, Confirm. END CYCLE.

Trade (scored): BUY CIQG $5,000 → 115.05 shares at $43.46
Cash: $1,150 | CIQG: 115.05 | CIQD: 63.01 | CIQE: 89.29 | CIQS: 53.91
CIQE: 89.29 * $133.54 = $11,924 | CIQS: 53.91 * $98.72 = $5,323 | CIQD: 63.01 * $154.74 = $9,751
Portfolio after C4: $33,148 (+$1,609 this cycle)
Press END CYCLE.

C4 score: REVISIONIST (info first — CIQG chart, BUY CIQG during crash cycle) = 1.0

---

### CYCLE 5 — Gulf Mined
CIQG opens at $30.42 — down -30%. CIQE at $186.96 (+40%). CIQS at $118.46 (+20%). CIQD at $177.95 (+15%).

INFORMATION FIRST: Immediately click the CIQE chart when trading opens — before anything else.
Say while looking: "Gulf mined. Everything halted. But energy spikes under supply shock.
CIQE is up 40 percent this cycle — the data shows the move before the crowd reacts."
PERCEPTION REFRAMED: "Others see collapse. We read energy supply disruption — same thesis, new data."
DECISION: BUY CIQE $1,000, Confirm. END CYCLE.

Trade (scored): BUY CIQE $1,000 → 5.35 shares at $186.96
Cash: $150 | CIQE: 94.64 | CIQD: 63.01 | CIQS: 53.91 | CIQG: 115.05
CIQE: 94.64 * $186.96 = $17,700 | CIQS: 53.91 * $118.46 = $6,388
CIQD: 63.01 * $177.95 = $11,213 | CIQG: 115.05 * $30.42 = $3,499
Portfolio after C5: $150 + $17,700 + $6,388 + $11,213 + $3,499 = $38,950
Press END CYCLE.

C5 score: REVISIONIST (info first — CIQE chart, BUY CIQE during crash cycle) = 1.0

---

### DEMO 3 RESULT
Starting cash:   $25,000.00
Final portfolio: $38,950.00
Gain:            +$13,950.00 (+55.8%)
TPM Profile:     REVISIONIST — Methodical
Classification:  "You checked the data before the headline settled. Where others read
                  crisis, you read signal — then let the data reshape what the headline
                  meant. Information reframes perception before every decision.
                  That is the Methodical — Revisionist pathway."

REVISIONIST scoring breakdown:
C1: 1.0 (info first, BUY CIQM) | C2: 1.0 (info first, BUY CIQD) | C3: 1.0 (info first, BUY CIQD)
C4: 1.0 (info first, BUY CIQG) | C5: 1.0 (info first, BUY CIQE)
Average REVISIONIST: 5/5 = 1.0 — dominant pathway

Closing statement for Demo 3:
"The Revisionist pathway. I arrow P arrow D.
Every single cycle — data before perception. Chart before headline.
Five for five. The behavioral signature never wavered."

---


## DEMO 4 — VALUE_DRIVEN PATHWAY (P → I → J → D)
## Difficulty: VETERAN — $100,000

### What This Demonstrates
The full deliberator with $100,000. Sees the headline, checks the data, applies judgment,
then executes — every cycle, same sequence, same conclusion.
P → I → J → D. The most complete throughput pathway.
The Veteran builds a diversified crisis portfolio across three ETFs,
but the PRIMARY trade each cycle is always CIQE — the same first action every time.
That consistency is the VALUE_DRIVEN behavioral signature.

### Why CIQE Is Always the First Trade
VALUE_DRIVEN scores in BehaviorTracker when the first confirmed trade each cycle
uses the same ETF as the previous cycle's first confirmed trade.
The Veteran's thesis: energy supply shock is the driving force of this entire crisis.
Every headline confirms it. CIQE is traded first every cycle — BUY in C1-C3,
SELL partial in C4 (rotate into CIQD surge), SELL all in C5.
BUY and SELL both count — action != HOLD is the only requirement.

### Multi-ETF Strategy
The Veteran does not put $100,000 into one ETF. They read the macro:
- CIQE (Energy): Primary thesis. Oil disruption is the engine of this conflict.
- CIQD (Defense): War escalation means defense contracts — secondary position.
- CIQS (Safe Haven): Steady flight-to-safety gains in every crisis cycle.
- Avoid CIQM (market panic) and CIQG (trade routes collapse).

This is a $100,000 professional position — diversified, structured, fully deliberated.

### Behavioral Requirements Each Cycle
- See the headline first (P — first_action = HEADLINE)
- Open CIQE panel first (I — information check on primary thesis ETF)
- CIQE is always the FIRST confirmed trade (sets VALUE_DRIVEN scoring)
- Additional trades after CIQE are financially applied but not pathway-scored
- Open only CIQE panel per cycle (avoids GLOBAL which requires 3+ panels)

---

### CYCLE 1 — Operation Epic Fury
CIQE opens at $89.60 (+12%). CIQD opens at $103.50 (+15%). CIQS opens at $74.20 (+6%).
Crash cycle (CIQM -8%).

PERCEPTION: US and Israel launch Operation Epic Fury. War starts.
INFORMATION: Click CIQE tab. Energy up 12%. Oil supply under immediate threat.
JUDGMENT: "Energy is the primary lever. Defense and Safe Haven follow the escalation.
We build three positions — CIQE leads, CIQD and CIQS support.
$100,000 deployed strategically across the crisis thesis."
DECISION:
  1. BUY CIQE $20,000. Confirm.  ← VALUE_DRIVEN scorer (sets prev = CIQE)
  2. BUY CIQD $25,000. Confirm.
  3. BUY CIQS $10,000. Confirm.
  END CYCLE.

Trades:
  BUY CIQE $20,000 → 223.21 shares at $89.60
  BUY CIQD $25,000 → 241.55 shares at $103.50
  BUY CIQS $10,000 → 134.77 shares at $74.20
  Cash remaining: $45,000

Portfolio after C1: $100,000
(Positions bought at open price — gain shows next cycle)

Say: "Headline in. CIQE panel checked. Thesis confirmed: energy, defense, safe haven.
Three positions. Same framework the Veteran applies every time.
P arrow I arrow J arrow D."

C1 score: VALUE_DRIVEN = 0 (no previous ETF to match), sets _prev_etf_traded = "CIQE"

---

### CYCLE 2 — Strait Closed
CIQE opens at $120.96 (+35%). CIQD opens at $95.22 (-8%). CIQS opens at $83.10 (+12%).
Not a crash cycle (CIQM +5% — dip buyers entered).

Portfolio at C2 open (before trades):
  Cash: $45,000
  CIQE: 223.21 × $120.96 = $27,001
  CIQD: 241.55 × $95.22  = $22,999
  CIQS: 134.77 × $83.10  = $11,199
  Total: $106,199 (+$6,199 this cycle)

PERCEPTION: Iran closes the Strait. CIQE surges 35%. CIQD dips on profit-taking.
INFORMATION: Click CIQE tab. Up 35% — thesis accelerating.
JUDGMENT: "Strait closure is maximum energy disruption. Add more CIQE.
CIQD dipped — that is profit-taking, not thesis change. Add on the dip.
Cash deployed: $25K to CIQE, $15K to CIQD."
DECISION:
  1. BUY CIQE $25,000. Confirm.  ← VALUE_DRIVEN scorer (CIQE = prev CIQE)
  2. BUY CIQD $15,000. Confirm.
  END CYCLE.

Trades:
  BUY CIQE $25,000 → 206.68 shares at $120.96
  BUY CIQD $15,000 → 157.53 shares at $95.22
  Cash remaining: $5,000

Holdings after C2 trades:
  CIQE: 429.89 shares | CIQD: 399.08 shares | CIQS: 134.77 shares
  Cash: $5,000

Say: "CIQE up 35%. Thesis confirmed. CIQD dipped — we buy the dip.
Same process. Same conclusion. P arrow I arrow J arrow D."

C2 score: VALUE_DRIVEN = 1.0 (BUY CIQE = prev CIQE) — DOMINANT starts here

---

### CYCLE 3 — China Warns
CIQE opens at $145.15 (+20%). CIQD opens at $119.03 (+25%). CIQS opens at $91.41 (+10%).
Crash cycle (CIQM -18%).

Portfolio at C3 open (before trades):
  Cash: $5,000
  CIQE: 429.89 × $145.15 = $62,399
  CIQD: 399.08 × $119.03 = $47,500
  CIQS: 134.77 × $91.41  = $12,319
  Total: $127,218 (+$21,019 this cycle)

PERCEPTION: China enters. Multi-front conflict confirmed.
INFORMATION: Click CIQE tab. Up 20% — energy thesis holding under maximum escalation.
JUDGMENT: "China entering means this is no longer a regional conflict.
Energy demand destruction accelerates. CIQE and CIQD both rising.
Deploy remaining $5,000 cash into CIQE."
DECISION:
  1. BUY CIQE $5,000. Confirm.  ← VALUE_DRIVEN scorer (CIQE = prev CIQE)
  END CYCLE.

Trades:
  BUY CIQE $5,000 → 34.45 shares at $145.15
  Cash remaining: $0

Holdings after C3 trades:
  CIQE: 464.34 shares | CIQD: 399.08 shares | CIQS: 134.77 shares
  Cash: $0

Say: "China in. Three ETFs all rising. Portfolio up over $27,000 in two cycles.
Same sequence every cycle. Thesis is not noise — it is signal."

C3 score: VALUE_DRIVEN = 1.0 (BUY CIQE = prev CIQE)

---

### CYCLE 4 — Ground Invasion
CIQE opens at $133.54 (-8%). CIQD opens at $154.74 (+30%). CIQS opens at $98.72 (+8%).
Crash cycle (CIQM -12%).

Portfolio at C4 open (before trades):
  Cash: $0
  CIQE: 464.34 × $133.54 = $62,017
  CIQD: 399.08 × $154.74 = $61,739
  CIQS: 134.77 × $98.72  = $13,305
  Total: $137,061 (+$9,843 this cycle)

PERCEPTION: 82nd Airborne deployed. Ground invasion begins.
INFORMATION: Click CIQE tab. Down 8% — temporary. CIQD surging 30% on ground war demand.
JUDGMENT: "CIQE dipped on demand uncertainty — the market fears a ceasefire.
CIQD is surging on ground invasion logistics and contracts.
Tactical rotation: trim 100 CIQE shares, rotate proceeds into CIQD.
First trade stays CIQE — framework intact."
DECISION:
  1. SELL 100 Shares CIQE. Confirm.     ← VALUE_DRIVEN scorer (SELL CIQE = prev CIQE, action != HOLD)
  2. BUY CIQD $13,000. Confirm.
  END CYCLE.

Trades:
  SELL 100 CIQE @ $133.54 → $13,354 cash
  BUY CIQD $13,000 → 84.01 shares at $154.74
  Cash remaining: $354

Holdings after C4 trades:
  CIQE: 364.34 shares | CIQD: 483.09 shares | CIQS: 134.77 shares
  Cash: $354

Say: "CIQE pulled back. CIQD is surging on the ground invasion.
We trim CIQE, rotate into CIQD — but CIQE is still the first trade.
The framework does not break. P arrow I arrow J arrow D."

C4 score: VALUE_DRIVEN = 1.0 (SELL CIQE = prev CIQE — BUY and SELL both score)

---

### CYCLE 5 — Gulf Mined
CIQE opens at $186.96 (+40%). CIQD opens at $177.95 (+15%). CIQS opens at $118.46 (+20%).
Crash cycle (CIQM -25%).

Portfolio at C5 open (before trades):
  Cash: $354
  CIQE: 364.34 × $186.96 = $68,117
  CIQD: 483.09 × $177.95 = $85,964
  CIQS: 134.77 × $118.46 = $15,969
  Total: $170,404 (+$33,343 this cycle)

PERCEPTION: Gulf mined. Global recession declared.
INFORMATION: Click CIQE tab. Up 40% — the crisis arc has reached its terminal escalation.
JUDGMENT: "CIQE ran from $89 to $186. CIQD from $95 to $177. CIQS from $74 to $118.
The thesis is fully realized. Recession is declared — sell everything.
Rule says: execute the exit."
DECISION:
  1. SELL all CIQE (364.34 shares). Confirm.  ← VALUE_DRIVEN scorer (CIQE = prev CIQE)
  2. SELL all CIQD (483.09 shares). Confirm.
  3. SELL all CIQS (134.77 shares). Confirm.
  END CYCLE.

Trades:
  SELL 364.34 CIQE @ $186.96 = $68,117
  SELL 483.09 CIQD @ $177.95 = $85,964
  SELL 134.77 CIQS @ $118.46 = $15,969
  Cash: $354 + $68,117 + $85,964 + $15,969 = $170,404

Say: "Thesis complete. Three ETFs. Five cycles. Same first trade every time.
CIQE opened every cycle — checked the data, confirmed the thesis, executed.
P arrow I arrow J arrow D — start to finish.
The value-driven investor does not panic out and does not chase noise.
They build the thesis, hold the framework, and let conviction compound."

C5 score: VALUE_DRIVEN = 1.0 (SELL CIQE = prev CIQE)

---

### DEMO 4 RESULT
Starting cash:    $100,000.00
Final portfolio:  $170,404.00
Gain:             +$70,404 (+70.4%)
TPM Profile:      VALUE_DRIVEN — Systematic
Classification:   "You returned to the same ETF cycle after cycle. Consistency
                   under pressure is a signal of rule-based conviction rather
                   than emotional reaction."

VALUE_DRIVEN scoring:
C1: 0.0 (no prev) | C2: 1.0 | C3: 1.0 | C4: 1.0 | C5: 1.0
Average VALUE_DRIVEN: 0.80 — dominant pathway

ETF performance across 5 cycles:
  CIQE: $89.60 → $186.96 (+108.7%) — primary thesis ETF
  CIQD: $103.50 → $177.95 (+71.9%) — secondary position, added on C2 dip
  CIQS: $74.20 → $118.46 (+59.6%) — steady safe haven throughout

Portfolio cycle-by-cycle:
  After C1: $100,000 (positions opened at cycle 1 prices)
  After C2: $106,199 (+$6,199)
  After C3: $127,218 (+$21,019)
  After C4: $137,061 (+$9,843)
  After C5: $170,404 (+$33,343)

Closing statement for Demo 4:
"The Value-Driven pathway. P arrow I arrow J arrow D. All four stages, every cycle.
The Veteran saw the headline, checked the energy data, applied their framework,
and executed — same first trade every time.
Not because they ignored new data, but because every new data point
kept confirming the same thesis across three ETFs.
One hundred thousand dollars. Three positions. Seventy percent return.
That is what value-driven conviction looks like under maximum pressure."

---
---

## CLOSING THE DEMO — Connecting to Professor Rodgers' Model

Show all four profile screens. Connect to the Q-TPM framework:

"Four investors. Same war. Same five cycles. Same five ETFs.
Same geopolitical crisis unfolding in real time.

The Student lost 26 percent reacting to every headline in under three seconds.
The Young Professional made 51 percent by reading data before every trade.
The Mid-career investor read data before every headline — five for five — up 55 percent.
The Veteran applied the same thesis every cycle with consistent discipline — up 48 percent.

Each profile is a distinct quantum state collapse pattern.
P arrow D. I arrow J arrow D. I arrow P arrow D. P arrow I arrow J arrow D.

These are not just investing styles. They are cognitive throughput pathways —
the sequence in which perception, information, judgment, and decision interact.

Professor Rodgers' model predicts these patterns. This game measures them.
That is the Q-TPM framework applied to behavioral finance under real market pressure."

---

## FINAL PORTFOLIO SUMMARY

| Demo | Pathway      | Sequence    | Difficulty  | Start     | End         | Return  |
|------|-------------|-------------|-------------|-----------|-------------|---------|
| 1    | Expedient   | P→D         | Student     | $500      | $369        | -26.2%  |
| 2    | Analytical  | I→J→D       | Young Pro   | $5,000    | $7,577      | +51.5%  |
| 3    | Revisionist | I→P→D       | Mid-career  | $25,000   | $38,950     | +55.8%  |
| 4    | Value_Driven| P→I→J→D     | Veteran     | $100,000  | $147,867    | +47.9%  |

---

## TIMING GUIDE

Demo 1 (Expedient):    3 minutes — fast decisions, minimal deliberation shown
Demo 2 (Analytical):   4 minutes — 10+ second pauses built in each cycle for narration
Demo 3 (Revisionist):  4 minutes — panel-first sequence, dramatic C4/C5
Demo 4 (Value_Driven): 3-4 minutes — 5-8 second pauses, consistent rhythm each cycle
Closing:               2 minutes
Total:                 ~16-17 minutes

If time is short — cut Demo 4. Run Demos 1, 2, 3.
The contrast between -26% (Expedient) and +51% (Analytical) anchors the presentation.
Demo 3 adds the contrarian narrative and the "wrong call" teaching moment.

---

## DEMO DAY BEHAVIORAL CHEAT SHEET

EXPEDIENT (Student): No panels. Confirm at any speed (no timing pressure).
ANALYTICAL (Young Pro): Open panel. Wait 10+ seconds. Confirm. 1-2 panels max.
REVISIONIST (Mid-career): Click chart FIRST before EVERY cycle's first trade — all 5 cycles.
VALUE_DRIVEN (Veteran): See headline first. THEN open CIQD panel. Confirm within 9s. Always CIQD.

REVISIONIST "info first" needed in: ALL 5 cycles (C1 CIQM, C2 CIQD, C3 CIQD, C4 CIQG, C5 CIQE)
NOTE: In C2 also SELL all CIQM as the 2nd (unscored) trade after the BUY CIQD is confirmed.
VALUE_DRIVEN same-ETF rule:         CIQD in every cycle — BUY C1 through C4, SELL C5

---

## CONTINGENCY PLAN

If the game freezes between cycles:
  Press SPACE once and wait 3 seconds. Press again if needed.
  If still frozen: "Let me restart this pathway" — reload from StartScreen.

If a trade fails to execute:
  Verify dollar amount is greater than zero.
  Verify cash is sufficient for BUY.
  Verify shares are held before SELL.

If profile screen shows wrong pathway:
  Check: did you follow the behavioral sequence precisely?
  For Demo 4 (VALUE_DRIVEN): did each cycle stay under 9 seconds? (Info panel + >10s = ANALYTICAL wins)
  Frame positively: "The detection is sensitive — it caught a real deviation.
  That is the system working as designed."

---

## FOR FUTURE CLAUDE SESSIONS — Architecture Reference

TIMERS: Removed. All difficulty timer values = 0.0.
  Cycles advance ONLY when player presses END CYCLE (the HOLD button in TradePanel).
  get_trading_time_remaining() always returns 0.0.

TIME_TO_DECIDE: Still measured in real wall-clock seconds.
  TradePanel._elapsed_decision_time() uses Time.get_ticks_usec() from trading_opened
  to the moment of first confirm_trade. Scoring thresholds still apply.

SCORING: Only the FIRST confirm_trade per cycle registers with BehaviorTracker.
  After first trade: _current = {}, subsequent trades find empty _current and skip scoring.
  BehaviorTracker._on_trading_opened() initializes _current once per cycle.

PATHWAY MAPPING (confirmed):
  Student    $500      → EXPEDIENT    P→D         (no info panel, fast decisions)
  Young Pro  $5,000    → ANALYTICAL   I→J→D       (info panel + 10s+ per cycle)
  Mid-career $25,000   → REVISIONIST  I→P→D       (info first + backdrop + BUY in crash)
  Veteran    $100,000  → VALUE_DRIVEN P→I→J→D     (same ETF CIQD every cycle, 5-8s)

ETF_DATA CYCLE CHANGES (authoritative — from SimulationManager.gd):
  CIQM: [-0.08, +0.05, -0.18, -0.12, -0.25]
  CIQE: [+0.12, +0.35, +0.20, -0.08, +0.40]
  CIQD: [+0.15, -0.08, +0.25, +0.30, +0.15]
  CIQS: [+0.06, +0.12, +0.10, +0.08, +0.20]
  CIQG: [-0.05, -0.22, -0.15, +0.15, -0.30]

DEMO TRADE SEQUENCES (exact inputs for each difficulty):
  EXPEDIENT ($500):
    C1: BUY CIQM $400 → END CYCLE
    C2: HOLD → END CYCLE
    C3: SELL CIQM all → END CYCLE
    C4: BUY CIQM $300 → END CYCLE
    C5: SELL CIQM all → END CYCLE
    Final: ~$369 (-26.2%)

  ANALYTICAL ($5,000):
    C1: BUY CIQE $2,000 → END CYCLE
    C2: BUY CIQD $1,500 → END CYCLE
    C3: SELL CIQE all → END CYCLE
    C4: SELL CIQD all → BUY CIQS $2,000 → END CYCLE
    C5: HOLD → END CYCLE
    Final: ~$7,577 (+51.5%)

  REVISIONIST ($25,000):
    C1: BUY CIQM $3,000 → BUY CIQE $8,000 → BUY CIQS $4,000 → END CYCLE  [CIQM chart FIRST]
    C2: BUY CIQD $2,000 → SELL all CIQM → END CYCLE  [CIQD chart FIRST — REVISIONIST=1.0]
    C3: BUY CIQD $5,000 → END CYCLE  [CIQD chart FIRST — crash cycle, REVISIONIST=1.0]
    C4: BUY CIQG $5,000 → END CYCLE  [CIQG chart FIRST — crash cycle, REVISIONIST=1.0]
    C5: BUY CIQE $1,000 → END CYCLE  [CIQE chart FIRST — crash cycle, REVISIONIST=1.0]
    REVISIONIST: 5/5 = 1.0 — dominant
    Final: ~$38,950 (+55.8%)

  VALUE_DRIVEN ($100,000):
    C1: BUY CIQD $30,000 → END CYCLE  [headline first, then open CIQD panel, 5-8s]
    C2: BUY CIQD $20,000 → END CYCLE  [same sequence]
    C3: BUY CIQD $15,000 → END CYCLE  [same sequence]
    C4: BUY CIQD $10,000 → END CYCLE  [same sequence]
    C5: SELL CIQD all → END CYCLE     [same sequence, take profits]
    Final: ~$147,867 (+47.9%)
