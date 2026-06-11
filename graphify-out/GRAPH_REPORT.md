# Graph Report - Personal finace all in one app  (2026-06-10)

## Corpus Check
- 52 files · ~132,290 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 390 nodes · 630 edges · 16 communities detected
- Extraction: 77% EXTRACTED · 23% INFERRED · 0% AMBIGUOUS · INFERRED: 142 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]

## God Nodes (most connected - your core abstractions)
1. `Font` - 23 edges
2. `AccountCategory` - 14 edges
3. `ExpenseCategory` - 14 edges
4. `InsightsEngine` - 13 edges
5. `DevHomeStyle` - 10 edges
6. `Insight` - 10 edges
7. `SageWorthView` - 10 edges
8. `money()` - 10 edges
9. `percentText()` - 10 edges
10. `NetWorthSnapshot` - 9 edges

## Surprising Connections (you probably didn't know these)
- `Insight` --inherits--> `Hashable`  [EXTRACTED]
  PennyPath/Features/Coach/InsightsEngine.swift →   _Bridges community 0 → community 7_
- `CurrencyOption` --inherits--> `Identifiable`  [EXTRACTED]
  PennyPath/Features/Settings/CurrencyPickerView.swift →   _Bridges community 0 → community 13_
- `OnboardingPage` --inherits--> `Identifiable`  [EXTRACTED]
  PennyPath/Features/Onboarding/OnboardingView.swift →   _Bridges community 0 → community 8_
- `RootView` --inherits--> `View`  [EXTRACTED]
  PennyPath/App/RootView.swift →   _Bridges community 0 → community 1_
- `SettingsView` --inherits--> `View`  [EXTRACTED]
  PennyPath/Features/Settings/SettingsView.swift →   _Bridges community 1 → community 8_

## Communities

### Community 0 - "Community 0"
Cohesion: 0.04
Nodes (58): AccountCategory, cash, creditCard, investment, loan, otherAsset, otherDebt, property (+50 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (36): CoachView, InsightCard, AmountField, ChipGrid, EmojiBadge, EmptyState, ProgressBar, ProgressRing (+28 more)

### Community 2 - "Community 2"
Cohesion: 0.07
Nodes (11): Account, AccountFormView, FieldCard, AppStore, Holding, HoldingFormView, Investments, AccountRow (+3 more)

### Community 3 - "Community 3"
Cohesion: 0.07
Nodes (14): ButtonStyle, PrimaryButtonStyle, SoftButtonStyle, DemoData, View, HomeViewVerde, HomeViewVerdeLite, OnboardingArtView (+6 more)

### Community 4 - "Community 4"
Cohesion: 0.08
Nodes (9): Date, HomeView, HomeViewGarden, HomeViewPremium, View, HomeViewRings, TripleRing, HomeViewSophisticated (+1 more)

### Community 5 - "Community 5"
Cohesion: 0.09
Nodes (18): Decodable, InstrumentSearchView, LocalizedError, Chart, ChartResponse, InstrumentType, Item, MarketDataProvider (+10 more)

### Community 6 - "Community 6"
Cohesion: 0.08
Nodes (13): SageCoachView, Font, Sage, SageCardStyle, SageOverline, View, SageWorthView, CardStyle (+5 more)

### Community 7 - "Community 7"
Cohesion: 0.16
Nodes (10): Insight, InsightsEngine, Tone, neutral, positive, tip, warning, AppSettings (+2 more)

### Community 8 - "Community 8"
Cohesion: 0.1
Nodes (12): Haptics, OnboardingArt, coach, goals, logo, netWorth, spending, OnboardingPage (+4 more)

### Community 9 - "Community 9"
Cohesion: 0.17
Nodes (4): BudgetFormView, BudgetCategoryRow, BudgetView, CategoryBudget

### Community 10 - "Community 10"
Cohesion: 0.25
Nodes (5): AppIntent, AppShortcutsProvider, AddExpenseIntent, PennyPathShortcuts, QuickAddCoordinator

### Community 11 - "Community 11"
Cohesion: 0.25
Nodes (2): Goal, GoalFormView

### Community 12 - "Community 12"
Cohesion: 0.25
Nodes (2): Expense, ExpenseFormView

### Community 13 - "Community 13"
Cohesion: 0.4
Nodes (2): CurrencyOption, CurrencyPickerView

### Community 14 - "Community 14"
Cohesion: 0.5
Nodes (1): Color

### Community 15 - "Community 15"
Cohesion: 0.67
Nodes (2): App, PennyPathApp

## Knowledge Gaps
- **60 isolated node(s):** `home`, `netWorth`, `expenses`, `goals`, `coach` (+55 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 11`** (8 nodes): `Goal`, `.init()`, `GoalFormView`, `.deleteGoal()`, `.load()`, `.save()`, `GoalFormView.swift`, `Goal.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 12`** (8 nodes): `Expense`, `.init()`, `ExpenseFormView`, `.deleteExpense()`, `.load()`, `.save()`, `ExpenseFormView.swift`, `Expense.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 13`** (5 nodes): `CurrencyOption`, `.init()`, `CurrencyPickerView`, `.init()`, `CurrencyPickerView.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 14`** (4 nodes): `Color`, `.adaptive()`, `.init()`, `Color+Hex.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 15`** (3 nodes): `App`, `PennyPathApp.swift`, `PennyPathApp`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Font` connect `Community 3` to `Community 0`, `Community 1`, `Community 4`, `Community 6`?**
  _High betweenness centrality (0.082) - this node is a cross-community bridge._
- **Why does `SageWorthView` connect `Community 6` to `Community 0`, `Community 1`, `Community 2`?**
  _High betweenness centrality (0.068) - this node is a cross-community bridge._
- **Why does `Insight` connect `Community 7` to `Community 0`?**
  _High betweenness centrality (0.060) - this node is a cross-community bridge._
- **Are the 20 inferred relationships involving `Font` (e.g. with `.statTile()` and `.percentChip()`) actually correct?**
  _`Font` has 20 INFERRED edges - model-reasoned connections that need verification._
- **What connects `home`, `netWorth`, `expenses` to the rest of the system?**
  _60 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._