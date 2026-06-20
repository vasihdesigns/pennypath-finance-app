# Graph Report - Personal finace all in one app  (2026-06-20)

## Corpus Check
- 60 files · ~147,909 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 626 nodes · 1174 edges · 24 communities detected
- Extraction: 73% EXTRACTED · 27% INFERRED · 0% AMBIGUOUS · INFERRED: 316 edges (avg confidence: 0.8)
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
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]

## God Nodes (most connected - your core abstractions)
1. `Font` - 39 edges
2. `SpectrumAccountSubtype` - 25 edges
3. `money()` - 23 edges
4. `Account` - 21 edges
5. `InsightsEngine` - 16 edges
6. `SpectrumGoalsView` - 14 edges
7. `SpectrumNetWorthView` - 14 edges
8. `AccountCategory` - 14 edges
9. `ExpenseCategory` - 14 edges
10. `SpectrumBudgetView` - 13 edges

## Surprising Connections (you probably didn't know these)
- `Int` --calls--> `percentText()`  [INFERRED]
   → PennyPath/Utilities/Money.swift  _Bridges community 14 → community 3_
- `SpectrumAccountSubtype` --inherits--> `String`  [EXTRACTED]
  PennyPath/Features/Spectrum/SpectrumAddAccountView.swift →   _Bridges community 2 → community 8_
- `CycleUnit` --inherits--> `String`  [EXTRACTED]
  PennyPath/Models/UpcomingPayment.swift →   _Bridges community 2 → community 9_
- `ExportFile` --inherits--> `Identifiable`  [EXTRACTED]
  PennyPath/Features/Settings/SettingsView.swift →   _Bridges community 2 → community 6_
- `Insight` --inherits--> `Identifiable`  [EXTRACTED]
  PennyPath/Features/Coach/InsightsEngine.swift →   _Bridges community 2 → community 3_

## Communities

### Community 0 - "Community 0"
Cohesion: 0.04
Nodes (41): AmountField, ChipGrid, EmojiBadge, EmptyState, Haptics, ProgressBar, ProgressRing, SectionHeader (+33 more)

### Community 1 - "Community 1"
Cohesion: 0.06
Nodes (18): ButtonStyle, Color, PrimaryButtonStyle, View, SpectrumAddAccountEntryView, SpectrumAddAccountView, SpectrumGoalsView, SpectrumInsightsView (+10 more)

### Community 2 - "Community 2"
Cohesion: 0.04
Nodes (57): AccountCategory, cash, creditCard, investment, loan, otherAsset, otherDebt, property (+49 more)

### Community 3 - "Community 3"
Cohesion: 0.08
Nodes (17): CategoryBudget, Expense, Insight, InsightsEngine, Tone, neutral, positive, tip (+9 more)

### Community 4 - "Community 4"
Cohesion: 0.07
Nodes (10): AppStore, StoreHealth, healthy, inMemoryFallback, resetAfterFailure, Holding, NetWorthHistory, NetWorthSnapshot (+2 more)

### Community 5 - "Community 5"
Cohesion: 0.1
Nodes (9): Account, CurrencyConversionTests, MockProvider, FXRates, _reset(), MarketDataProvider, MarketService, YahooMarketDataProvider (+1 more)

### Community 6 - "Community 6"
Cohesion: 0.07
Nodes (13): AccountFormView, FieldCard, ExpenseFormView, GoalFormView, ActivityView, ExportFile, SettingsView, Outcome (+5 more)

### Community 7 - "Community 7"
Cohesion: 0.09
Nodes (8): Date, Goal, AccountTests, ExpenseTests, GoalTests, DateHelperTests, SpectrumExpensesView, XCTestCase

### Community 8 - "Community 8"
Cohesion: 0.06
Nodes (31): Pickable, Hashable, PreciousMetal, PreciousMetalSearchView, AccountDetailField, counterparty, creditLimit, dueDate (+23 more)

### Community 9 - "Community 9"
Cohesion: 0.12
Nodes (8): HoldingFormView, Investments, SpectrumNetWorthView, CycleUnit, day, month, week, year

### Community 10 - "Community 10"
Cohesion: 0.12
Nodes (6): InstrumentSearchView, MarketCatalogTests, InstrumentType, SymbolMatch, Market, Markets

### Community 11 - "Community 11"
Cohesion: 0.13
Nodes (19): AppIconView, AppStoreSearch, AppSuggestion, Item, Response, Decodable, LocalizedError, Chart (+11 more)

### Community 12 - "Community 12"
Cohesion: 0.16
Nodes (8): Shape, Field, category, income, total, SpectrumBudgetView, SpectrumMeter, VLine

### Community 13 - "Community 13"
Cohesion: 0.32
Nodes (10): Codable, AccountDTO, BudgetDTO, DataExport, ExpenseDTO, GoalDTO, HoldingDTO, Snapshot (+2 more)

### Community 14 - "Community 14"
Cohesion: 0.24
Nodes (6): Int, MarketFlow, funds, metals, search, SpectrumAllocationView

### Community 15 - "Community 15"
Cohesion: 0.25
Nodes (5): AppIntent, AppShortcutsProvider, AddExpenseIntent, PennyPathShortcuts, QuickAddCoordinator

### Community 16 - "Community 16"
Cohesion: 0.25
Nodes (8): Topic, budget, cushion, general, goals, netWorth, spending, subscriptions

### Community 17 - "Community 17"
Cohesion: 0.29
Nodes (5): CardStyle, Radius, Space, Theme, View

### Community 18 - "Community 18"
Cohesion: 0.33
Nodes (2): AppLockManager, AppLockView

### Community 19 - "Community 19"
Cohesion: 0.33
Nodes (6): OnboardingArt, coach, goals, logo, netWorth, spending

### Community 20 - "Community 20"
Cohesion: 0.4
Nodes (4): PennyPathMigrationPlan, PennyPathSchemaV1, SchemaMigrationPlan, VersionedSchema

### Community 21 - "Community 21"
Cohesion: 0.4
Nodes (4): HoldingSearchMode, funds, markets, HoldingSearchView

### Community 22 - "Community 22"
Cohesion: 0.67
Nodes (2): App, PennyPathApp

### Community 23 - "Community 23"
Cohesion: 0.67
Nodes (1): SupportLinks

## Knowledge Gaps
- **108 isolated node(s):** `system`, `light`, `dark`, `healthy`, `resetAfterFailure` (+103 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 18`** (6 nodes): `AppLockManager`, `.authenticate()`, `.init()`, `.lockForBackground()`, `AppLockView`, `AppLock.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 22`** (3 nodes): `App`, `PennyPathApp.swift`, `PennyPathApp`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 23`** (3 nodes): `SupportLinks.swift`, `SupportLinks`, `.supportMailURL()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Font` connect `Community 1` to `Community 0`, `Community 9`, `Community 12`, `Community 14`, `Community 17`?**
  _High betweenness centrality (0.081) - this node is a cross-community bridge._
- **Why does `Account` connect `Community 5` to `Community 0`, `Community 2`, `Community 3`, `Community 4`, `Community 7`, `Community 9`?**
  _High betweenness centrality (0.078) - this node is a cross-community bridge._
- **Why does `SpectrumAccountSubtype` connect `Community 8` to `Community 1`, `Community 2`?**
  _High betweenness centrality (0.066) - this node is a cross-community bridge._
- **Are the 35 inferred relationships involving `Font` (e.g. with `.paceCard()` and `.reachedPill()`) actually correct?**
  _`Font` has 35 INFERRED edges - model-reasoned connections that need verification._
- **Are the 22 inferred relationships involving `money()` (e.g. with `.paceCard()` and `.spendingInsights()`) actually correct?**
  _`money()` has 22 INFERRED edges - model-reasoned connections that need verification._
- **What connects `system`, `light`, `dark` to the rest of the system?**
  _108 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._