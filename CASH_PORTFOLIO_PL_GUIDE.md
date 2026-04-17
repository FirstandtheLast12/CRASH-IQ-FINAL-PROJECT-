# CrashIQ — Cash, Portfolio, and P/L Explained
# Plain language guide for the team + Claude Code prompt at the bottom
# All numbers verified against actual game code
# Last updated: April 2026

---

## THE THREE NUMBERS ON SCREEN — WHAT THEY MEAN

At the top of the simulation screen there are always three numbers.
Here is exactly what each one means in plain English.

---

### CASH
Money you can spend right now. Your buying power.

- Starts at your difficulty tier amount ($500 / $5,000 / $25,000 / $100,000)
- Goes DOWN when you BUY (you spent cash to buy shares)
- Goes UP when you SELL (you converted shares back to cash)
- NEVER changes from HOLD alone
- NEVER changes just because prices move up or down

---

### PORTFOLIO
Your total wealth at this exact moment.

Formula: PORTFOLIO = Cash + (value of every position you currently hold)

A position's value = shares you own × current price of that ETF

- When you have no positions: Portfolio = Cash exactly
- When you buy: Cash drops, position appears, Portfolio stays the same
- When price moves up on something you own: Portfolio goes up
- When price moves down on something you own: Portfolio goes down
- When you sell: position closes, cash jumps, Portfolio stays the same

---

### P/L (Profit and Loss)
How much you have made or lost since the game started.

Formula: P/L = Portfolio - Starting Cash

- Always $0.00 at game start
- Always $0.00 right after you BUY (you repositioned, not gained)
- Goes POSITIVE when your Portfolio is above your Starting Cash
- Goes NEGATIVE when your Portfolio is below your Starting Cash
- Green = you are ahead, Red = you are behind

---

## HOW EACH DECISION AFFECTS ALL THREE NUMBERS

Reading this table left to right shows what changes and what stays the same.

| Decision | Cash | Portfolio | P/L |
|----------|------|-----------|-----|
| Game start (no trades yet) | = Starting Cash | = Starting Cash | = $0.00 |
| BUY $X of an ETF | DROPS by $X | NO CHANGE | NO CHANGE |
| HOLD (no positions) | NO CHANGE | NO CHANGE | NO CHANGE |
| HOLD (with positions, price rises) | NO CHANGE | GOES UP | GOES UP |
| HOLD (with positions, price falls) | NO CHANGE | GOES DOWN | GOES DOWN |
| SELL all shares of an ETF | JUMPS UP | NO CHANGE | NO CHANGE |
| Next cycle begins (prices update) | NO CHANGE | CHANGES | CHANGES |

The key insight: BUY and SELL move money between Cash and Positions
but do not change your total Portfolio. Your Portfolio only changes
when PRICES MOVE on things you already own.

---

## STEP BY STEP WALKTHROUGH — YOUNG PRO ($5,000)

### Game Loads — Before Any Trade

  Cash:      $5,000.00
  Portfolio: $5,000.00   ← same as cash because no positions yet
  P/L:           $0.00   ← nothing has happened

### Cycle 1 — Player BUYS $2,000 of CIQE at $89.60

  shares bought = $2,000 / $89.60 = 22.3214 shares

  Cash:      $3,000.00   ← dropped $2,000 (spent on shares)
  Portfolio: $5,000.00   ← unchanged ($3,000 cash + $2,000 position)
  P/L:           $0.00   ← unchanged (just repositioned, not gained)

  WHY P/L IS STILL ZERO: You paid $2,000 for shares worth $2,000.
  You have not made anything yet. The price has to move first.

### Cycle 2 Begins — CIQE Price Updates to $120.96

  Position is now worth: 22.3214 shares × $120.96 = $2,700.00

  Cash:      $3,000.00   ← unchanged (you did not buy or sell)
  Portfolio: $5,700.00   ← went up ($3,000 cash + $2,700 position)
  P/L:        +$700.00   ← you are $700 ahead of where you started

  THIS IS UNREALIZED GAIN. You own shares that are worth more.
  But you have not sold yet. If price drops before you sell, you lose it.

### Cycle 2 — Player HOLDs

  Cash:      $3,000.00   ← unchanged (HOLD never touches cash)
  Portfolio: $5,700.00   ← unchanged (HOLD does not move prices)
  P/L:        +$700.00   ← unchanged

### Cycle 3 Begins — CIQE Price Updates to $145.15

  Position is now worth: 22.3214 × $145.15 = $3,239.96

  Cash:      $3,000.00
  Portfolio: $6,239.96
  P/L:       +$1,239.96

### Cycle 3 — Player SELLS all CIQE at $145.15

  proceeds = 22.3214 × $145.15 = $3,239.96

  Cash:      $6,239.96   ← jumped up (shares converted to cash)
  Portfolio: $6,239.96   ← unchanged ($6,239.96 cash + $0 positions)
  P/L:       +$1,239.96  ← unchanged

  THIS IS NOW REALIZED GAIN. The $1,239.96 is locked in as cash.
  It cannot be taken away by future price movements.

---

## WHAT LOSING MONEY LOOKS LIKE

### Cycle 1 — Player BUYS $2,000 of CIQM at $92.00

  Cash:      $3,000.00
  Portfolio: $5,000.00
  P/L:           $0.00

### Cycle 3 Begins — CIQM Drops to $79.21 (fell 14%)

  Position: 21.74 shares × $79.21 = $1,721.96

  Cash:      $3,000.00
  Portfolio: $4,721.96
  P/L:         -$278.04   ← RED — you are losing money

  THIS IS UNREALIZED LOSS. You still own the shares.
  If you hold, maybe it recovers. If you sell now, you lock in the loss.

### Cycle 3 — Player Panic SELLS at $79.21

  Cash:      $4,721.96
  Portfolio: $4,721.96
  P/L:         -$278.04   ← REALIZED — locked in permanently

  The player sold at a loss. That $278.04 is gone.

---

## THE DISPLAY BUG AND HOW TO FIX IT

### What Is Happening

SimulationManager.get_portfolio_value() already contains cash inside it.
Its formula: total = cash + sum(all holdings × prices)

If display code does:  cash + get_portfolio_value()
It is doing:           cash + (cash + positions) = 2×cash + positions

This makes Young Pro show $10,000 instead of $5,000 at start.
P/L shows +$5,000 instead of $0.00.

### The Fix

Every place in SimulationScreen.gd that shows Portfolio or Total:
  WRONG:  var total = get_cash() + get_portfolio_value()
  RIGHT:  var total = get_portfolio_value()

Every place that shows P/L:
  RIGHT:  var pnl = get_portfolio_value() - SimulationManager.starting_cash

Every place that shows Cash or Buying Power:
  RIGHT:  var cash = get_cash()

Never combine get_cash() and get_portfolio_value() in the same sum.

---

## TPM CONNECTION — WHY THESE NUMBERS MATTER FOR BEHAVIOR SCORING

The three numbers on screen are not just cosmetic.
They create the emotional pressure that drives TPM pathway decisions.

A falling P/L number creates FEAR → triggers Expedient behavior (panic sell)
A rising P/L number creates GREED → triggers Value-Driven behavior (hold longer)
A flat P/L with lots of cash → triggers Analytical behavior (what should I buy?)
A negative P/L → triggers Revisionist behavior (buy the dip or cut losses?)

If the numbers are wrong, the emotional pressure is wrong.
If the numbers are wrong, the TPM pathway scoring is measuring the wrong thing.
Getting these three numbers right is not just cosmetic — it is the game.

---

## COPY-PASTE PROMPT FOR CLAUDE CODE

Give this to your teammate to fix the display issue:

---

Read CLAUDE.md. Only modify scripts/SimulationScreen.gd.
Do not change any other file. Do not create new files.

CONTEXT:
SimulationManager.get_portfolio_value() returns:
  cash + sum(holdings[ticker] * etf_prices[ticker] for all tickers)
It already includes cash internally.

Adding get_cash() on top of get_portfolio_value() counts cash twice.
This causes Portfolio to show double the correct value at game start.
Young Pro ($5,000) shows $10,000. P/L shows +$5,000. Both wrong.

WHAT EACH LABEL SHOULD SHOW:

  CASH label (top bar):
    = SimulationManager.get_cash()
    Shows money available to spend right now
    Example at start: $5,000.00

  PORTFOLIO label (top bar):
    = SimulationManager.get_portfolio_value()
    Shows total wealth (cash + all open positions)
    Example at start: $5,000.00 (same as cash — no positions yet)
    Example after buying $2,000 CIQE: $5,000.00 (unchanged — just repositioned)
    Example after CIQE rises 35%: $5,700.00 (position gained $700)

  P/L label (top bar):
    = SimulationManager.get_portfolio_value() - SimulationManager.starting_cash
    Shows gain or loss since game began
    Example at start: $0.00
    Example after buying: $0.00 (still zero — price has not moved yet)
    Example after CIQE rises 35%: +$700.00

  BUYING POWER label (trade panel):
    = SimulationManager.get_cash()
    Same as cash — what you can spend

THE FIX:
Find these functions in SimulationScreen.gd and fix them:
  _update_portfolio_display()
  _refresh_top_bar()
  _update_cash_display()
  Any other function that sets portfolio_label, pnl_label, cash_label

In each function, find any line doing:
  var total = SimulationManager.get_cash() + SimulationManager.get_portfolio_value()

Replace with:
  var total: float = SimulationManager.get_portfolio_value()
  var cash: float = SimulationManager.get_cash()
  var pnl: float = total - SimulationManager.starting_cash

Then set labels:
  cash_label.text = "Cash: $%.2f" % cash
  _portfolio_label.text = "Portfolio: $%.2f" % total
  if pnl_label:
    if pnl >= 0:
      pnl_label.text = "P/L: +$%.2f" % pnl
      pnl_label.modulate = Color("00ff41")
    else:
      pnl_label.text = "P/L: -$%.2f" % abs(pnl)
      pnl_label.modulate = Color("ff4444")

Also fix buying_power_label in TradePanel or SimulationScreen:
  buying_power_label.text = "$%.2f" % SimulationManager.get_cash()

VERIFY after fix:
  Young Pro at game start: Cash=$5,000 | Portfolio=$5,000 | P/L=$0.00
  After buying $2,000 CIQE: Cash=$3,000 | Portfolio=$5,000 | P/L=$0.00
  After cycle 2 (CIQE +35%): Cash=$3,000 | Portfolio=$5,700 | P/L=+$700.00
  After selling all CIQE: Cash=$6,240 | Portfolio=$6,240 | P/L=+$1,240.00

Do not modify SimulationManager.gd, BehaviorTracker.gd, or TradePanel.gd.
Do not change scene transitions or signal connections.
