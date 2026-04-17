class_name CrashCycle
extends Resource

## One geopolitical crisis cycle. Holds all data needed to run a trading round.

@export var cycle_number: int = 0
@export_multiline var headline: String = ""
@export_multiline var subtext: String = ""

## Keys are ETF tickers ("CIQM", "CIQE", "CIQD", "CIQS").
## Values are fractional price changes, e.g. -0.08 = -8%.
@export var etf_changes: Dictionary = {}
