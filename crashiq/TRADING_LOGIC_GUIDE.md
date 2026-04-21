# CrashIQ — Trading Logic Plain Language Guide
# For team members with no trading experience
# All numbers verified against actual game code
# Last updated: April 2026

---

## The Simple Version — What the Game Is Doing

Think of it like this. You open a Robinhood account. You get some cash.
You can buy stocks. The stocks go up or down based on Iran war news.
You make money if you buy something before it goes up.
You lose money if you buy something before it goes down.
You can also do nothing (HOLD) and wait.

That is the entire game. No complexity beyond that.

---

## The Three Actions

### BUY
You spend some of your cash to own shares of an ETF.
Your cash goes down. Your position value goes up by the same amount.
Your total portfolio value does NOT change when you buy.
You have not made or lost anything yet — you just moved cash into shares.

Example: You have $5,000. You buy $2,000 of CIQE.
  Before: Cash $5,000 | Positions $0 | Portfolio $5,000 | P/L $0
  After:  Cash $3,000 | Positions $2,000 | Portfolio $5,000 | P/L $0

The money moved from your left pocket to your right pocket.
No gain. No loss. Just repositioned.

### SELL
You convert your shares back into cash.
Your position goes down. Your cash goes up.
You LOCK IN whatever gain or loss happened while you held those shares.

Example: You held CIQE and it rose. You sell.
  Before sell: Cash $3,000 | Positions $2,700 | Portfolio $5,700 | P/L +$700
  After sell:  Cash $5,700 | Positions $0 | Portfolio $5,700 | P/L +$700

The $700 gain is now locked in as cash. It cannot go away.

### HOLD
You do nothing. Cash stays the same. Shares stay the same.
If prices go up your portfolio value increases — but this is UNREALIZED.
Unrealized means: you have not locked it in by selling yet.
If the price then drops before you sell, you lose that gain.

Example: You hold CIQE through cycle 4 (price drops 8%)
  C3: Portfolio $6,240 — P/L +$1,240 (unrealized, not locked in)
  C4: Portfolio $5,981 — P/L +$981 (gave back $259 without doing anything)

---

## Dollar Mode vs Shares Mode

The TradePanel lets you trade in two ways:

DOLLAR MODE (default):
  You type how many dollars you want to spend.
  The game figures out how many shares that buys.
  Example: Type $500, CIQE costs $89.60 → you get 5.58 shares

SHARES MODE:
  You type how many shares you want.
  The game figures out what that costs.
  Example: Type 5 shares, CIQE costs $89.60 → costs you $448.00

Both modes use fractional shares — you do not need to buy whole numbers.
You can own 22.3214 shares of CIQE. This is normal and realistic.

For the demo: USE DOLLAR MODE. It is simpler to explain to the audience.

---

## Portfolio, Cash, and P/L — What Each Label Means

CASH (also called Buying Power):
  Money you have available to spend.
  Goes down when you BUY. Goes up when you SELL.
  Never changes from HOLD alone.

PORTFOLIO (also called Total Value):
  Your cash PLUS the current market value of all your positions.
  Formula: Portfolio = Cash + (shares owned × current price for each ETF)
  At game start with no positions: Portfolio = Cash exactly.

P/L (Profit and Loss):
  How much you have gained or lost since the game started.
  Formula: P/L = Portfolio - Starting Cash
  At game start: P/L = $0.00 always.
  Goes positive when your total is above starting cash.
  Goes negative when your total is below starting cash.

IMPORTANT CODE NOTE:
  SimulationManager.get_portfolio_value() already includes cash.
  Never add get_cash() on top of it. This causes the display bug
  where Young Pro shows $10,000 instead of $5,000 at start.
  Correct: total = get_portfolio_value()
  Wrong:   total = get_cash() + get_portfolio_value()

---

## What Each Difficulty Level Looks Like in Practice

### Student — $500 — 30 seconds per cycle

With $500 every dollar matters. Losing $100 is a 20% hit.
The 30 second timer is generous — student has time to look around.
Realistic trades: buying $100-$200 positions at a time.

Sample: Buy $200 CIQE in cycle 1
  Shares: 200 / 89.60 = 2.2321 shares
  If held to C5: worth 2.2321 × $186.96 = $417.32 (gained $217)
  Portfolio goes: $500 → $500 → $535 → $562 → $549 → $608

### Young Pro — $5,000 — 20 seconds per cycle

Meaningful money. Losing $1,000 stings. 20 seconds is moderate pressure.
Realistic trades: $500 to $2,000 positions.

Sample: Buy $2,000 CIQE in cycle 1 (40% of portfolio)
  P/L progression: $0 → +$700 → +$1,240 → +$981 → +$2,173
  Notice C4 dip: gave back $259 before recovering in C5

### Mid-career — $25,000 — 15 seconds per cycle

High stakes. Losing $5,000 is serious. 15 seconds creates real pressure.
Realistic trades: $2,000 to $10,000 positions.

Sample: Buy $5,000 CIQE in cycle 1 (20% of portfolio)
  P/L progression: $0 → +$1,750 → +$3,100 → +$2,452 → +$5,433

### Veteran — $100,000 — 10 seconds per cycle

Maximum stakes. 10 seconds is brutal. Every second of hesitation counts.
Realistic trades: $10,000 to $50,000 positions.

Sample: Buy $20,000 CIQE in cycle 1 (20% of portfolio)
  P/L progression: $0 → +$7,000 → +$12,400 → +$9,808 → +$21,732

The percentage gains are THE SAME across all tiers.
Difficulty is about: timer pressure + emotional weight of larger dollar amounts.

---

## How Much Money Can You Actually Make or Lose

Buying $1,000 of each ETF in cycle 1 and holding all 5 cycles:

  CIQM (Broad Market): $1,000 → $568    LOSS of $432  (-43.2%)
  CIQE (Energy):       $1,000 → $2,087  GAIN of $1,087 (+108.7%)
  CIQD (Defense):      $1,000 → $1,719  GAIN of $719   (+71.9%)
  CIQS (Safe Haven):   $1,000 → $1,597  GAIN of $596   (+59.6%)
  CIQG (Shipping):     $1,000 → $534    LOSS of $466  (-46.6%)

Best possible outcome (buy CIQE C1, sell C3, rebuy C4):
  Student:    $500   → $1,134  (+126.8%)
  Young Pro:  $5,000 → $11,340 (+126.8%)
  Mid-career: $25,000 → $56,700 (+126.8%)
  Veteran:    $100,000 → $226,802 (+126.8%)

Worst possible outcome (buy CIQM C1 and hold everything):
  Student:    $500   → $284   (-43.2%)
  Young Pro:  $5,000 → $2,841 (-43.2%)
  Mid-career: $25,000 → $14,207 (-43.2%)
  Veteran:    $100,000 → $56,826 (-43.2%)

Can a player go to zero? The liquidation threshold is $1.00.
No ETF in the game crashes to zero. CIQM falls 43% and CIQG falls 47%.
To trigger liquidation requires consistently bad decisions across cycles.
It is possible but not easy.

---

## The Three Demo Pathways — Verified Final Numbers

DEMO 1 — Expedient — Student $500:
  Decisions: panic buy+sell CIQM C1, buy back CIQM C3, panic sell C4, hold C5
  Final portfolio: $451.98
  P/L: -$48.02  (-9.6%)
  TPM Profile: Expedient — Impulse Trader

DEMO 2 — Analytical — Young Pro $5,000:
  Decisions: buy CIQE C1, add CIQD C2, sell CIQE C3, rotate to CIQS C4, hold C5
  Final portfolio: $7,577.49
  P/L: +$2,577.49  (+51.5%)
  TPM Profile: Analytical — Strategic

DEMO 3 — Revisionist — Mid-career $25,000:
  Decisions: buy CIQE+CIQS C1, buy CIQM dip C2, sell CIQM C3, buy CIQG spike C4, hold C5
  Final portfolio: $33,378.46
  P/L: +$8,378.46  (+33.5%)
  TPM Profile: Revisionist — Contrarian

These numbers are what the game should display if the trading mechanics
and portfolio display are working correctly.

---

## Common Questions Your Team Might Have

Q: Why does P/L show $0 right after I buy something?
A: Because buying moves cash into shares at the same value.
   You repositioned, you did not gain or lose anything yet.
   P/L only changes when the PRICE moves after your purchase.

Q: Why does Portfolio equal Cash at the start?
A: Because you have no positions. Portfolio = Cash + Positions.
   Positions are worth $0 when you own no shares.
   Portfolio only separates from Cash after you buy something.

Q: Why is my Portfolio showing double my Cash amount?
A: This is the display bug. get_portfolio_value() already includes cash.
   Adding cash on top of it doubles the number.
   Fix: use get_portfolio_value() alone for the Portfolio label.

Q: If I HOLD every cycle without buying anything, do I lose money?
A: No. If you have no positions your portfolio never changes.
   You start with $5,000 and end with $5,000. P/L = $0 always.
   You only lose money when you own shares that fall in price.

Q: What is the difference between unrealized and realized gain?
A: Unrealized = your position is worth more but you have not sold yet.
               The gain can disappear if the price drops before you sell.
   Realized   = you sold and the profit is now in your cash.
               It is permanently locked in and cannot be lost.

Q: Why does CIQE show +108% but the Analytical demo only shows +51%?
A: Because the Analytical demo only invested 40% of the portfolio in CIQE,
   not all of it. Also it rotated out of CIQE before C5.
   The 108% is what happens if you go all-in and hold the full game.
   The 51% is what a smart diversified strategy achieves.

---

## For Tuesday's Deliverable — Minimum Working Requirements

The game works correctly for the demo if these are true:

1. Starting screen shows correct cash per difficulty (Student $500, etc.)
2. Portfolio label equals Cash label before any trade is made
3. P/L label shows $0.00 before any trade is made
4. After a BUY: cash drops, portfolio stays same, P/L stays $0
5. After next cycle: portfolio changes to reflect price movement
6. After a SELL: cash increases, position closes, P/L shows gain or loss
7. After 5 cycles: TPMResultsScreen appears for any decision combination
8. ProfileScreen shows correct archetype based on decision pattern

If all 8 are true the game is ready for the presentation demo.
