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

## CRITICAL: ONE CODE FIX REQUIRED BEFORE DEMOS 2 AND 3

BehaviorTracker.record_info_panel_opened() is never called from SimulationScreen.gd.
Without this fix, info_panel_opened is always false — ANALYTICAL and REVISIONIST
pathways cannot classify correctly.

Fix location: SimulationScreen.gd, function _on_chart_info_requested()
Add ONE LINE after _select_ticker(ticker):

    func _on_chart_info_requested(ticker: String) -> void:
        _select_ticker(ticker)
        BehaviorTracker.record_info_panel_opened(ticker)   # ADD THIS LINE
        _info_ticker_label.text = "$" + ticker
        ...

Demo 1 (Expedient) and Demo 4 (Value_Driven) work WITHOUT this fix.
Demo 2 (Analytical) and Demo 3 (Revisionist) require this fix to classify correctly.

---

## BUG CATALOG — Do Not Fix Yet

Bug 1: record_info_panel_opened() missing from SimulationScreen._on_chart_info_requested()
  Impact: Analytical and Revisionist pathways never classify. info_panel_opened always false.
  Fix: One line — see CRITICAL section above.
  Demos affected: Demo 2, Demo 3.

Bug 2: CLAUDE.md cycle change values do not match ETF_DATA in SimulationManager.gd
  Impact: Documentation confusion only. Pricing at runtime is correct.
  Fix: Update CLAUDE.md cycle change table to match ETF_DATA arrays.
  Demos affected: None (runtime unaffected).

Bug 3: CrashCycle.etf_changes set in _build_cycles() does not match ETF_DATA.cycle_changes
  Impact: The CrashCycle resource carries stale/wrong etf_changes values.
  Pricing is correct because _snapshot_cycle_open_prices() uses ETF_DATA, not CrashCycle.
  Fix: Align CrashCycle.etf_changes with ETF_DATA or remove the field from _build_cycles.
  Demos affected: None (runtime unaffected).

Bug 4: EXPEDIENT and ANALYTICAL scoring thresholds rely on time_to_decide but timer was removed.
  Location: BehaviorTracker._score_cycle()
  Detail: EXPEDIENT requires time_to_decide < 5.0s. ANALYTICAL requires time_to_decide > 10.0s.
  These thresholds were calibrated for a timed game (30s/20s/15s/10s per difficulty).
  Timer was removed April 2026 — all decisions are now wall-clock timed from trading_opened
  to first confirm_trade. During a live presentation with narration, the presenter will
  naturally exceed 8 seconds, making EXPEDIENT unscorable (scores 0) and ANALYTICAL
  trivially satisfied by any slow pace regardless of intent.
  Fix when ready: Remove time_to_decide from EXPEDIENT/ANALYTICAL conditions. Use
  info_panel_opened as the sole differentiator — EXPEDIENT = no panel, ANALYTICAL = panel.
  Demos affected: Demo 1 (Expedient will not classify if presenter narrates during trading).
  Workaround for demo: Presenter must click Confirm within 5 seconds during Expedient cycles.
  No narration during trading phase — narrate before SPACE is pressed or after END CYCLE.

---

## BEFORE YOU START — Setup Checklist

- Bug 1 fix applied (required for Demo 2 and Demo 3)
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

EXPEDIENT (1.0):    time_to_decide < 5.0s AND info_panel NOT opened
                    Partial (0.5) if time < 8.0s and no info panel

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

### Behavioral Requirements Each Cycle
- Do NOT click any chart to open info panels
- Confirm every trade or press END CYCLE within 3 seconds of trading opening
  (scoring threshold is 5s — stay well under it)
- React to the headline alone. No deliberation visible to the audience.
- Works WITHOUT the info panel bug fix.

---

### CYCLE 1 — Operation Epic Fury
Headline: US and Israel launch airstrikes on Iran.
CIQM opens at $92.00 (was $100 — already down 8%).

PERCEPTION: War started. Market already falling.
DECISION: BUY CIQM $400 — within 3 seconds. No chart opened.

Trade: BUY CIQM $400 → 4.35 shares at $92.00
Cash: $100.00 | CIQM: 4.35 shares | Portfolio: $500.00
Press END CYCLE.

Say: "The headline hits. Broad market is falling. No research.
We buy in immediately. P arrow D. That is all this investor does."

C1 score: EXPEDIENT (time < 3s, no info panel)

---

### CYCLE 2 — Strait of Hormuz Closes
Headline: Iran closes Strait. 20% of global oil cut off.
CIQM opens at $96.60 — it BOUNCED. Energy (CIQE) is at $120.96, up 35%.

PERCEPTION: Scary headline. Paralysis.
DECISION: HOLD — press END CYCLE within 3 seconds.

Say: "Strait closes. Panic. We freeze. We do nothing.
Energy went from $89 to $121 — up 35% — and we missed all of it.
Our CIQM actually bounced this cycle. We did not notice."

Cash: $100.00 | CIQM: 4.35 shares @ $96.60 = $420.00
Portfolio after C2: $520.00 (+$20 paper gain, not realized)
C2 score: EXPEDIENT (END CYCLE within 3s, no info panel)

---

### CYCLE 3 — China Warns
Headline: China warns US. Saudi oil facilities struck.
CIQM opens at $79.21 — now BELOW our $92 buy price.

PERCEPTION: China entering. Market below cost. Panic.
DECISION: SELL all CIQM — within 3 seconds.

Trade: SELL all CIQM → 4.35 shares at $79.21 = $344.38
Cash: $100 + $344.38 = $444.38 | Portfolio: $444.38

Say: "China enters. CIQM is below what we paid.
Panic sell. We locked in a loss. Bought at $92, sold at $79.
CIQE is at $145 right now — up 62% from the start. We have none of it."

C3 P&L: -$75.62 (loss realized)
C3 score: EXPEDIENT (SELL within 3s, no info panel)

---

### CYCLE 4 — Ground Invasion
Headline: 82nd Airborne deployed. Ground invasion begins.
CIQM opens at $69.70 — still falling.

PERCEPTION: CIQM is down from $100 to $69. Looks cheap.
DECISION: BUY CIQM $300 — within 3 seconds.

Trade: BUY CIQM $300 → 4.30 shares at $69.70
Cash: $144.38 | CIQM: 4.30 shares | Portfolio: $444.38

Say: "It has dropped 31 percent from the start. Looks cheap.
We buy back in — the same ETF we just panic sold at $79.
We sold at $79. We are now buying at $69. This is the retail trap."

C4 score: EXPEDIENT (BUY within 3s, no info panel)

---

### CYCLE 5 — Gulf Mined
Headline: Iran mines Persian Gulf. Global recession declared.
CIQM opens at $52.28 — still falling. We are holding at $69.70 cost.

PERCEPTION: Gulf mined. Recession. Panic.
DECISION: SELL all CIQM — within 3 seconds.

Trade: SELL all CIQM → 4.30 shares at $52.28 = $224.80
Cash: $144.38 + $224.80 = $369.18
Press END CYCLE.

Say: "Gulf mined. Recession. We sell again.
Bought at $69. Sold at $52. Second loss locked in.
CIQE finished at $187 — up 134% from the start. We never held it once."

C5 P&L: -$75.20 (second realized loss)
C5 score: EXPEDIENT

---

### DEMO 1 RESULT
Starting cash:   $500.00
Final portfolio: $369.18
Loss:            -$130.82 (-26.2%)
TPM Profile:     EXPEDIENT — Impulse Trader
Classification:  "You moved fast and skipped analysis. Decisions fired before
                  the full picture settled — speed dominated over deliberation."

Closing statement for Demo 1:
"The Expedient pathway. P arrow D. Five cycles, five headline reactions,
zero information consulted. We lost 26 percent not from bad luck —
from a pattern. The quantum state collapsed at maximum speed every time."

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
- REVISIONIST requires ALL of these simultaneously (crash cycles only):
  1. Click a chart as your ABSOLUTE FIRST ACTION when trading opens
     (before clicking anything else — this sets first_action = INFO)
  2. Click the DARK BACKGROUND to close the panel
     (this registers headline_reread = true)
  3. Action must be BUY (not SELL or HOLD)
  4. CIQM must be falling this cycle (C1, C3, C4, C5 — not C2)
- For C2 (CIQM bounces — not a crash cycle): open panel, wait 10+ seconds, then BUY
  (this scores ANALYTICAL for C2, which is fine — VALUE doesn't depend on every cycle)
- For C3 (SELL action): REVISIONIST won't score — this is expected
- REQUIRES the info panel bug fix to classify correctly.

---

### CYCLE 1 — Operation Epic Fury
CIQE opens at $89.60. CIQS opens at $74.20. Crash cycle (CIQM -8%).

INFORMATION FIRST: Immediately click the CIQE chart when trading opens — before anything else.
Say while looking at panel: "Before reading the headline — we check the data.
Energy supply shock from a Middle East conflict. CIQE benefits.
Safe Haven rises in fear environments. CIQS benefits."
Click dark BACKGROUND to close panel (registers headline reread).
PERCEPTION REFRAMED: "The headline confirms what the data already told us."
DECISION: BUY CIQE $8,000, Confirm. Then BUY CIQS $4,000, Confirm. END CYCLE.

Trade 1 (scored): BUY CIQE $8,000 → 89.29 shares at $89.60
Trade 2 (not scored): BUY CIQS $4,000 → 53.91 shares at $74.20
Cash: $13,000 | CIQE: 89.29 | CIQS: 53.91 | Portfolio: $25,000
Press END CYCLE.

C1 score: REVISIONIST (info first, backdrop closed, BUY during crash cycle)

---

### CYCLE 2 — Strait Closed
CIQM opens at $96.60 — it BOUNCED (+5%). NOT a crash cycle.
CIQE at $120.96 (+35%). CIQS at $83.10 (+12%).

INFORMATION: Click CIQM chart — panel opens.
Say while waiting 10+ seconds: "Strait closes. Everyone is selling CIQM.
But the data shows dip buyers entering. CIQM bounced this cycle.
The crowd is fleeing. The data says someone is buying the dip."
PERCEPTION REFRAMED: Others see disaster. Revisionist sees contrarian opportunity.
DECISION: BUY CIQM $5,000, Confirm. END CYCLE.
(Not a crash cycle — REVISIONIST won't score. This scores neutral or partial ANALYTICAL.)

Trade: BUY CIQM $5,000 → 51.76 shares at $96.60
Cash: $8,000 | CIQM: 51.76 | CIQE: 89.29 | CIQS: 53.91
CIQE value: $10,800 | CIQS value: $4,480
Portfolio after C2: $28,280 (+$3,280 this cycle)
Press END CYCLE.

C2 score: Not REVISIONIST (C2 is not crash cycle). Neutral or partial ANALYTICAL.

---

### CYCLE 3 — China Warns
CIQM opens at $79.21 — below our $96.60 buy price. Crash cycle (CIQM -18%).

INFORMATION: Click CIQM chart.
Say: "China enters. The bounce thesis is over. We captured what we could.
The data says exit CIQM now before further downside."
DECISION: SELL all CIQM, Confirm. END CYCLE.
(SELL action — REVISIONIST requires BUY. This cycle does not score REVISIONIST.)

Trade: SELL all CIQM → 51.76 shares at $79.21 = $4,100.00
Cash: $12,100 | CIQE: 89.29 | CIQS: 53.91
CIQE: 89.29 * $145.15 = $12,960 | CIQS: 53.91 * $91.41 = $4,928
Portfolio after C3: $29,988 (+$1,708 this cycle)
Press END CYCLE.

Note to class: "We bought CIQM at $96.60, sold at $79.21. That is a loss.
The contrarian call in C2 was wrong on CIQM. The data told us to exit.
Our CIQE and CIQS positions are carrying the portfolio — up from $25K to $30K."

C3 score: Not REVISIONIST (SELL action, not BUY).

---

### CYCLE 4 — Ground Invasion
CIQG opens at $43.46 — surprise +15% spike. Crash cycle (CIQM -12%).
Note: CIQE dropped -8% to $133.54 this cycle.

INFORMATION FIRST: Immediately click the CIQG chart when trading opens.
Say while looking: "Shipping has been falling all war. But look — up 15 percent.
Ground invasion signals Hormuz may reopen. Shipping rerouting creates demand.
The data shows a counterintuitive signal the crowd is not positioned for."
Click dark BACKGROUND to close panel (registers headline reread).
PERCEPTION REFRAMED: Others see a collapsing sector. Revisionist sees reopening thesis.
DECISION: BUY CIQG $6,000, Confirm. END CYCLE.

Trade: BUY CIQG $6,000 → 138.06 shares at $43.46
Cash: $6,100 | CIQE: 89.29 | CIQS: 53.91 | CIQG: 138.06
CIQE: 89.29 * $133.54 = $11,924 | CIQS: 53.91 * $98.72 = $5,323
Portfolio after C4: $29,347 (-$641 this cycle — CIQE dropped)
Press END CYCLE.

C4 score: REVISIONIST (info first, backdrop closed, BUY during crash cycle)

---

### CYCLE 5 — Gulf Mined
CIQG opens at $30.42 — down -30%. CIQE at $186.96 (+40%). CIQS at $118.46 (+20%).

DECISION: HOLD — press END CYCLE. Watch CIQG collapse.

Say: "Gulf mined. All shipping halted. CIQG collapses 30 percent.
We bought shipping at $43. It is at $30. The contrarian call was WRONG on cycle 5.
We bought the Hormuz reopening thesis. The Gulf got mined instead.
That is the Revisionist pathway — the data reshapes perception.
Sometimes the reframe is correct. Sometimes it is not."

CIQE: 89.29 * $186.96 = $16,693 | CIQS: 53.91 * $118.46 = $6,388
CIQG: 138.06 * $30.42 = $4,200 (bought for $6,000 — lost $1,800)
Portfolio after C5: $6,100 + $16,693 + $6,388 + $4,200 = $33,381
Press END CYCLE.

C5 score: Not REVISIONIST (HOLD — no BUY action).

---

### DEMO 3 RESULT
Starting cash:   $25,000.00
Final portfolio: $33,381.00
Gain:            +$8,381.00 (+33.5%)
TPM Profile:     REVISIONIST — Contrarian
Classification:  "You bought into the crash. Reading against the crowd and acting
                  on macro context under maximum stress is a rare and
                  high-conviction behavioral signal."

REVISIONIST scoring breakdown:
C1: 1.0 (info first, backdrop, BUY, crash) | C2: 0 (not crash) | C3: 0 (SELL)
C4: 1.0 (info first, backdrop, BUY, crash) | C5: 0 (HOLD)
Average REVISIONIST: 0.40 — dominant pathway

Closing statement for Demo 3:
"The Revisionist pathway. I arrow P arrow D.
Information came first and reframed every headline as signal.
Two correct contrarian calls. One wrong one.
But the behavioral signature is unmistakable — data before perception, every time."

---

## DEMO 4 — VALUE_DRIVEN PATHWAY (P → I → J → D)
## Difficulty: VETERAN — $100,000

### What This Demonstrates
The full deliberator. Sees the headline, checks the data, applies judgment,
then executes — every cycle, same sequence, same conclusion.
P → I → J → D. The most complete throughput pathway.
Consistent conviction is the output of consistent process.

### Why the Same ETF Every Cycle
VALUE_DRIVEN scores in BehaviorTracker when the same ETF is traded as the previous cycle.
Narratively: the Veteran's P→I→J→D loop always returns the same answer
because their underlying value framework is stable.
They are not ignoring data — they are checking it thoroughly and consistently
arriving at the same thesis. That IS the value-driven behavioral signature.

### ETF: CIQD — CIQ Defense Fund
Thesis: War escalation → defense contracts → CIQD rises.
CIQD drops -8% in C2 (profit-taking). The Veteran adds to their position.
"The thesis has not changed. The rule says: buy Defense in war. We buy."

### Behavioral Requirements Each Cycle
- See the headline first (do NOT click chart as first action — keeps first_action = HEADLINE)
  This distinguishes VALUE_DRIVEN (P first) from REVISIONIST (I first)
- Then open the CIQD chart panel (I — information check)
- Pause 5-8 seconds — not under 5 (avoids EXPEDIENT), not over 10 (avoids ANALYTICAL)
- Trade CIQD every cycle — BUY in C1 through C4, SELL in C5
  Same ETF every cycle is what scores VALUE_DRIVEN
- Open only 1 panel per cycle (avoids GLOBAL which needs 3+)
- Works WITHOUT the info panel bug fix (VALUE_DRIVEN does not depend on info_panel tracking).

### Behavioral Sweet Spot
  Decision time: 5-8 seconds    (past Expedient threshold, under Analytical threshold)
  Panels opened: 1 per cycle    (under Global threshold of 3)
  ETF traded:    CIQD every time (this is the VALUE_DRIVEN trigger)

---

### CYCLE 1 — Operation Epic Fury
CIQD opens at $103.50 (up 15%). Crash cycle (CIQM -8%).

PERCEPTION: War started. Military escalation.
INFORMATION: Click CIQD chart. See +15%. Defense rising.
JUDGMENT (5-8 seconds, narrate): "Defense always rises in the first wave of military
escalation. This is the same pattern we have seen in every conflict.
The thesis is confirmed."
DECISION: BUY CIQD $30,000, Confirm. END CYCLE.

Trade: BUY CIQD $30,000 → 289.86 shares at $103.50
Cash: $70,000 | CIQD: 289.86 shares | Portfolio: $100,000
Press END CYCLE.

Say: "Headline in. Data checked. Judgment: thesis intact. Trade executed.
P arrow I arrow J arrow D. Same sequence the Veteran uses every time."

C1 score: VALUE_DRIVEN = 0 (no previous ETF to match), but sets _prev_etf_traded = "CIQD"

---

### CYCLE 2 — Strait Closed
CIQD opens at $95.22 — dropped -8%. Profit-taking after initial shock.

PERCEPTION: Strait closes. Defense pulled back.
INFORMATION: Click CIQD chart. See -8% dip.
JUDGMENT (5-8 seconds): "Profit-taking, not a trend change.
The war is escalating. Defense contracts are being written right now.
The dip does not change the thesis. It is an entry point."
DECISION: BUY CIQD $20,000, Confirm. END CYCLE.

Trade: BUY CIQD $20,000 → 210.07 shares at $95.22
Cash: $50,000 | CIQD: 499.93 shares (289.86 + 210.07)
CIQD value: 499.93 * $95.22 = $47,613
Portfolio after C2: $50,000 + $47,613 = $97,613 (-$2,387 this cycle)

Say: "Defense dipped. Others are selling. We are buying.
The thesis has not changed. The rule says buy Defense in war.
We buy the dip. P arrow I arrow J arrow D. Same sequence."

Note: -$2,387 this cycle is a deliberate test of VALUE_DRIVEN conviction.
The Veteran does not deviate. This contrast with Expedient is the teaching moment.

C2 score: VALUE_DRIVEN = 1.0 (CIQD = _prev_etf_traded CIQD) — DOMINANT starts here

---

### CYCLE 3 — China Warns
CIQD opens at $119.03 (+25%). Thesis accelerating.

PERCEPTION: China enters. Escalation deepens.
INFORMATION: Click CIQD chart. See +25%. Defense rising strongly.
JUDGMENT (5-8 seconds): "China entering means this conflict is multi-front.
Defense spending across multiple nations accelerates. Thesis strengthens."
DECISION: BUY CIQD $15,000, Confirm. END CYCLE.

Trade: BUY CIQD $15,000 → 126.02 shares at $119.03
Cash: $35,000 | CIQD: 625.95 shares
CIQD value: 625.95 * $119.03 = $74,506
Portfolio after C3: $35,000 + $74,506 = $109,506 (+$11,893 this cycle)
Press END CYCLE.

C3 score: VALUE_DRIVEN = 1.0 (CIQD = prev CIQD)

---

### CYCLE 4 — Ground Invasion
CIQD opens at $154.74 (+30%). Boots on ground.

PERCEPTION: Ground invasion confirmed.
INFORMATION: Click CIQD chart. See +30%. Thesis at peak performance.
JUDGMENT (5-8 seconds): "Ground forces in the field. Massive logistics and
equipment demand. Defense is in full contract mode. One more add."
DECISION: BUY CIQD $10,000, Confirm. END CYCLE.

Trade: BUY CIQD $10,000 → 64.62 shares at $154.74
Cash: $25,000 | CIQD: 690.57 shares
CIQD value: 690.57 * $154.74 = $106,840
Portfolio after C4: $25,000 + $106,840 = $131,840 (+$22,334 this cycle)
Press END CYCLE.

C4 score: VALUE_DRIVEN = 1.0 (CIQD = prev CIQD)

---

### CYCLE 5 — Gulf Mined
CIQD opens at $177.95 (+15%). Gulf mined. Recession.

PERCEPTION: Gulf mined. Maximum escalation. Thesis complete.
INFORMATION: Click CIQD chart. See +15%. Defense still rising.
JUDGMENT (5-8 seconds): "We have ridden this thesis from $103 to $177.
Recession is declared. The escalation arc has reached its terminal point.
Time to take profits. Rule says: execute the exit."
DECISION: SELL all CIQD, Confirm. END CYCLE.

Trade: SELL all CIQD → 690.57 shares at $177.95 = $122,867.41
Cash: $25,000 + $122,867.41 = $147,867.41
Press END CYCLE.

Say: "Thesis complete. Five cycles. Same ETF. Same process.
P arrow I arrow J arrow D — start to finish.
The value-driven investor does not panic out and does not chase noise.
They execute their framework and let the thesis run."

C5 score: VALUE_DRIVEN = 1.0 (SELL CIQD = prev CIQD — BUY and SELL both count)

---

### DEMO 4 RESULT
Starting cash:   $100,000.00
Final portfolio: $147,867.41
Gain:            +$47,867.41 (+47.9%)
TPM Profile:     VALUE_DRIVEN — Systematic
Classification:  "You returned to the same ETF cycle after cycle. Consistency
                  under pressure is a signal of rule-based conviction rather
                  than emotional reaction."

VALUE_DRIVEN scoring:
C1: 0.0 (no prev) | C2: 1.0 | C3: 1.0 | C4: 1.0 | C5: 1.0
Average VALUE_DRIVEN: 0.80 — dominant pathway

Closing statement for Demo 4:
"The Value-Driven pathway. P arrow I arrow J arrow D. All four stages, every cycle.
The Veteran saw the headline, checked the data, applied judgment, and executed.
Same conclusion every time — not because they ignored new information,
but because new information kept confirming the same thesis.
That is what value-driven conviction looks like under pressure."

---

## CLOSING THE DEMO — Connecting to Professor Rodgers' Model

Show all four profile screens. Connect to the Q-TPM framework:

"Four investors. Same war. Same five cycles. Same five ETFs.
Same geopolitical crisis unfolding in real time.

The Student lost 26 percent reacting to every headline in under three seconds.
The Young Professional made 51 percent by reading data before every trade.
The Mid-career investor took contrarian positions — right twice, wrong once — still up 33 percent.
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
| 3    | Revisionist | I→P→D       | Mid-career  | $25,000   | $33,381     | +33.5%  |
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

EXPEDIENT (Student): No panels. Confirm within 3 seconds every cycle.
ANALYTICAL (Young Pro): Open panel. Wait 10+ seconds. Confirm. 1-2 panels max.
REVISIONIST (Mid-career): Click chart FIRST in C1 and C4. Click dark backdrop. Then BUY.
VALUE_DRIVEN (Veteran): See headline first. THEN open CIQD panel. 5-8 seconds. Always CIQD.

REVISIONIST "info first" only needed in: C1 and C4 (crash cycles with BUY action)
VALUE_DRIVEN same-ETF rule:             CIQD in every cycle — BUY C1 through C4, SELL C5

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
  Check: was the info panel bug fix applied? (Required for Demo 2 and 3.)
  Check: did you follow the behavioral sequence precisely?
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
    C1: BUY CIQE $8,000 → BUY CIQS $4,000 → END CYCLE  [info panel FIRST, backdrop]
    C2: BUY CIQM $5,000 → END CYCLE
    C3: SELL CIQM all → END CYCLE
    C4: BUY CIQG $6,000 → END CYCLE  [info panel FIRST, backdrop]
    C5: HOLD → END CYCLE
    Final: ~$33,381 (+33.5%)

  VALUE_DRIVEN ($100,000):
    C1: BUY CIQD $30,000 → END CYCLE  [headline first, then open CIQD panel, 5-8s]
    C2: BUY CIQD $20,000 → END CYCLE  [same sequence]
    C3: BUY CIQD $15,000 → END CYCLE  [same sequence]
    C4: BUY CIQD $10,000 → END CYCLE  [same sequence]
    C5: SELL CIQD all → END CYCLE     [same sequence, take profits]
    Final: ~$147,867 (+47.9%)
