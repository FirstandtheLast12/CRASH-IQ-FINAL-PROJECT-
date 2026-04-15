# CrashIQ — Trading Mechanics Reference
# For Claude Code: read this before modifying any trading logic
# Trading type: Long-only spot equity trading with fractional shares (Robinhood model)

---

## What Kind of Trading This Is

CrashIQ uses LONG-ONLY SPOT EQUITY TRADING with FRACTIONAL SHARES.
This is identical to how Robinhood, Webull, and Cash App work for retail investors.

Key rules that must always be true:
- Players can only BUY or SELL at the current market price (no limit orders)
- Players cannot short sell (cannot profit from a falling price directly)
- Players cannot use leverage or margin
- Players cannot trade options or derivatives
- Fractional shares are allowed (you can buy $50 worth of a $100 ETF = 0.5 shares)
- All trades execute instantly at the cycle price (market orders only)

Real-world analogy: A college student opens Robinhood during a breaking news event
and decides whether to buy energy stocks, sell their holdings, or do nothing.

---

## The 5 ETFs and How They Behave

Each ETF has a starting price and changes per cycle based on the Iran war scenario.
Prices COMPOUND — each cycle's end price becomes the next cycle's start price.

| Ticker | Full Name            | Start  | Iran War Behavior                          |
|--------|----------------------|--------|--------------------------------------------|
| CIQM   | CIQ Broad Market     | $100   | Falls — panic selling, recession fears     |
| CIQE   | CIQ Energy Fund      | $80    | Spikes when Hormuz closes, dips C4         |
| CIQD   | CIQ Defense Fund     | $90    | Rises with war, small dip C2               |
| CIQS   | CIQ Safe Haven       | $70    | Slow steady rise — gold/treasury analog    |
| CIQG   | CIQ Global Shipping  | $60    | Falls hard — trade routes collapse, C4 spike |

Cycle changes (applied as multipliers each cycle):
  CIQM: [-0.08,  0.05, -0.18, -0.12, -0.25]
  CIQE: [ 0.12,  0.35,  0.20, -0.08,  0.40]
  CIQD: [ 0.15, -0.08,  0.25,  0.30,  0.15]
  CIQS: [ 0.06,  0.12,  0.10,  0.08,  0.20]
  CIQG: [-0.05, -0.22, -0.15,  0.15, -0.30]

Example compounding for CIQE starting at $80:
  After C1: $80 * 1.12 = $89.60
  After C2: $89.60 * 1.35 = $120.96
  After C3: $120.96 * 1.20 = $145.15
  After C4: $145.15 * 0.92 = $133.54  ← reversal, punishes holders
  After C5: $133.54 * 1.40 = $186.96  ← recovers for those who held through dip

---

## How BUY Works

When player presses BUY and confirms:

1. Player enters a dollar amount OR share count
2. System calculates shares = dollars / current_price (if dollar mode)
3. Validation: shares * price must not exceed current cash balance
4. On confirm:
   cash = cash - (shares * price)
   holdings[ticker] = holdings[ticker] + shares
5. Portfolio value immediately reflects new position

Example: Player has $5,000 cash. CIQE is at $89.60.
  Player buys $1,000 worth.
  shares = 1000 / 89.60 = 11.16 shares
  cash = 5000 - 1000 = $4,000
  holdings["CIQE"] = 0 + 11.16 = 11.16 shares
  portfolio_value = 11.16 * 89.60 = $1,000 (same as cost, no gain yet)

After next cycle if CIQE rises 20%:
  new price = 89.60 * 1.20 = $107.52
  portfolio_value = 11.16 * 107.52 = $1,199.92
  unrealized gain = $199.92

---

## How SELL Works

When player presses SELL and confirms:

1. Player enters a dollar amount OR share count to sell
2. Validation: shares to sell must not exceed holdings[ticker]
3. On confirm:
   holdings[ticker] = holdings[ticker] - shares
   cash = cash + (shares * price)
4. If selling all shares of an ETF, holdings[ticker] returns to 0

Example: Player holds 11.16 shares of CIQE now at $107.52.
  Player sells all 11.16 shares.
  proceeds = 11.16 * 107.52 = $1,199.92
  cash = 4000 + 1199.92 = $5,199.92
  holdings["CIQE"] = 0
  Realized gain = $199.92

---

## How HOLD Works

HOLD means the player deliberately does nothing this cycle.

What HOLD does NOT do:
  - Does NOT sell any positions
  - Does NOT change cash balance
  - Does NOT change holdings

What HOLD DOES do:
  - Records the decision for BehaviorTracker Q-TPM scoring
  - Advances to the next cycle
  - Holdings gain or lose value passively based on price changes

Example: Player holds 11.16 shares of CIQE at $89.60. Presses HOLD cycle 2.
  CIQE rises 35% to $120.96.
  Player did nothing but their position is now worth: 11.16 * 120.96 = $1,350.13
  This is UNREALIZED gain — they have not locked it in by selling.
  Cash remains unchanged.

IMPORTANT: HOLD during a falling ETF = passive loss on that position.
  Player holds 11.16 CIQE through C4 reversal (-8%).
  Price drops from $145.15 to $133.54.
  Position value drops from $1,619.87 to $1,490.31.
  Loss of $129.56 in portfolio value without any action.

---

## Portfolio Value Calculation

Total portfolio value at any moment:
  total = cash + sum(holdings[ticker] * etf_prices[ticker] for all tickers)

Starting cash = difficulty tier cash (Student $500, etc.)
Starting holdings = 0 for all ETFs

Player "gains money" when: total > starting_cash
Player "loses money" when: total < starting_cash

Liquidation threshold: total <= $1.00 triggers LIQUIDATED screen

---

## Cycle Result Display Logic

After each trade confirm, show the player what happened:

If action == HOLD:
  unrealized_change = current_portfolio_value - portfolio_value_before_cycle_prices_updated
  Display: "HELD — Market moved +$X on your positions" (green) or
           "HELD — Market moved -$X on your positions" (red) or
           "HELD — No position change" (gray)
  This is UNREALIZED — they did not lock it in

If action == BUY:
  Display: "BOUGHT [ticker] — Position opened at $X"
  Show new total portfolio value

If action == SELL:
  realized_gain = (sell_price - avg_buy_price) * shares_sold
  Display: "SOLD [ticker] — +$X gain" (green) or "-$X loss" (red)

---

## TPM Pathway Mapping to Trade Decisions

Each decision is scored by BehaviorTracker against these rules:

EXPEDIENT (P→D):
  Triggered by: deciding in under 5 seconds without opening any ETF info panel
  Market signal: panic selling CIQM or CIQG immediately after headline
  Real behavior: "I saw the crash headline and hit sell immediately"

ANALYTICAL (I→J→D):
  Triggered by: opening info panel, spending over 10 seconds deciding
  Market signal: buying CIQE or CIQD after reviewing data
  Real behavior: "I checked the numbers before acting"

VALUE_DRIVEN (P→J→D):
  Triggered by: trading the same ETF as previous cycle
  Market signal: consistent CIQS buyer every cycle
  Real behavior: "I have a rule and I stick to it"

RULING_GUIDE (P→I→J→D):
  Triggered by: checking multiple ETF panels (2+ switches) before deciding
  Market signal: deliberate diversified decision
  Real behavior: "I reviewed all options before choosing"

REVISIONIST (I→P→D):
  Triggered by: opening info panel FIRST, rereading headline, then buying during crash
  Market signal: buying CIQM dip in cycle 2
  Real behavior: "The data told me this was an opportunity not a disaster"

GLOBAL (I→P→J→D):
  Triggered by: 3+ info panel switches AND buying a macro-positive ETF
  Market signal: rotating from CIQE to CIQD as war escalates
  Real behavior: "I tracked the whole picture and positioned accordingly"

---

## What Makes a Player Lose Money (Game Challenge Design)

The game is NOT automatically profitable. These traps exist:

Trap 1 — Panic selling CIQM in C1:
  CIQM drops 8% in C1 but BOUNCES 5% in C2.
  Player who sells C1 locks in -8% loss and misses the recovery.
  Player who holds through C2 is back near even before the bigger drop in C3.

Trap 2 — Riding CIQE without selling before C4:
  CIQE rises C1/C2/C3 then DROPS 8% in C4.
  Player who bought C1 and held to C4 gives back gains.
  Player who sold before C4 keeps the profit.

Trap 3 — Buying CIQG spike in C4:
  CIQG surprises with +15% in C4 (shipping rerouting demand).
  Player who buys it then holds through C5 gets crushed (-30%).
  The spike is a trap for contrarian buyers.

Trap 4 — Never selling, always holding:
  Pure HOLD loses nothing but gains nothing — boring safe CIQS is the only
  ETF that consistently appreciates without reversals.
  All-HOLD player ends near starting_cash with small unrealized CIQS gains
  if they bought it. Pure HOLD with no buys = exactly starting_cash always.

---

## Critical Implementation Rules

1. cash can NEVER go below 0 — validate before every BUY
2. holdings[ticker] can NEVER go below 0 — validate before every SELL
3. Fractional shares must be preserved to 4 decimal places minimum
4. portfolio_value_before must be captured BEFORE _apply_trade() runs
5. portfolio_value_after must be captured AFTER _apply_trade() runs
6. HOLD trade_data must still be passed to BehaviorTracker for TPM scoring
7. Cycle prices update in _snapshot_cycle_open_prices() at cycle START
   not at cycle end — player sees new prices when headline appears
8. The trade executes at the price AFTER the cycle update, not before
