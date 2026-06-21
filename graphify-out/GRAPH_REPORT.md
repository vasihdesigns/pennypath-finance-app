# Graph Report - Personal finace all in one app  (2026-06-21)

## Corpus Check
- 69 files · ~160,531 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 733 nodes · 1474 edges · 23 communities detected
- Extraction: 69% EXTRACTED · 31% INFERRED · 0% AMBIGUOUS · INFERRED: 458 edges (avg confidence: 0.8)
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

## God Nodes (most connected - your core abstractions)
1. `Font` - 52 edges
2. `money()` - 33 edges
3. `Account` - 30 edges
4. `SpectrumAccountSubtype` - 25 edges
5. `CurrencyConversionTests` - 19 edges
6. `SpectrumNetWorthView` - 17 edges
7. `InsightsEngine` - 16 edges
8. `SpectrumGoalsView` - 15 edges
9. `Goal` - 15 edges
10. `AccountCategory` - 15 edges

## Surprising Connections (you probably didn't know these)
- `Int` --calls--> `percentText()`  [INFERRED]
   → PennyPath/Utilities/Money.swift  _Bridges community 0 → community 7_
- `SpectrumAccountSubtype` --inherits--> `String`  [EXTRACTED]
  PennyPath/Features/Spectrum/SpectrumAddAccountView.swift →   _Bridges community 0 → community 8_
- `CycleUnit` --inherits--> `String`  [EXTRACTED]
  PennyPath/Models/UpcomingPayment.swift →   _Bridges community 0 → community 5_
- `ExportFile` --inherits--> `Identifiable`  [EXTRACTED]
  PennyPath/Features/Settings/SettingsView.swift →   _Bridges community 0 → community 3_
- `CurrencyOption` --inherits--> `Identifiable`  [EXTRACTED]
  PennyPath/Features/Settings/CurrencyPickerView.swift →   _Bridges community 0 → community 1_

## Communities

### Community 0 - "Community 0"
Cohesion: 0.03
Nodes (70): AccountCategory, cash, creditCard, investment, loan, otherAsset, otherDebt, property (+62 more)

### Community 1 - "Community 1"
Cohesion: 0.04
Nodes (41): AccountFormView, FieldCard, AppLockManager, AppLockView, AmountField, ChipGrid, EmojiBadge, EmptyState (+33 more)

### Community 2 - "Community 2"
Cohesion: 0.06
Nodes (13): ButtonStyle, Color, PrimaryButtonStyle, SoftButtonStyle, DemoData, PaywallView, SpectrumAddAccountView, SpectrumNetWorthView (+5 more)

### Community 3 - "Community 3"
Cohesion: 0.05
Nodes (20): CloudBackup, Haptics, Equatable, ExpenseFormView, GoalFormView, ActivityView, ClearStep, backupChoice (+12 more)

### Community 4 - "Community 4"
Cohesion: 0.06
Nodes (21): CategoryBudget, Codable, AccountDTO, BudgetDTO, DataExport, ExpenseDTO, GoalDTO, HoldingDTO (+13 more)

### Community 5 - "Community 5"
Cohesion: 0.08
Nodes (12): ArchivedView, money(), signedMoney(), MoneyTests, SearchView, SpectrumBudgetBurnBar, SpectrumGoalsView, CycleUnit (+4 more)

### Community 6 - "Community 6"
Cohesion: 0.09
Nodes (10): Account, CurrencyConversionTests, MockProvider, FXRates, _reset(), Holding, MarketDataProvider, MarketService (+2 more)

### Community 7 - "Community 7"
Cohesion: 0.08
Nodes (12): Date, Insight, InsightsEngine, Tone, neutral, positive, tip, warning (+4 more)

### Community 8 - "Community 8"
Cohesion: 0.05
Nodes (37): Pickable, Hashable, Market, Markets, PreciousMetal, PreciousMetalSearchView, AccountDetailField, counterparty (+29 more)

### Community 9 - "Community 9"
Cohesion: 0.09
Nodes (8): AppStore, StoreHealth, healthy, inMemoryFallback, resetAfterFailure, NetWorthHistory, SampleData, StoreBehaviorTests

### Community 10 - "Community 10"
Cohesion: 0.1
Nodes (6): View, AppSettings, currencySymbol(), SpectrumAddAccountEntryView, SpectrumEditAccountView, SpectrumInsightsView

### Community 11 - "Community 11"
Cohesion: 0.1
Nodes (23): AppIconView, AppStoreSearch, AppSuggestion, Item, Response, BackupError, unavailable, ImportError (+15 more)

### Community 12 - "Community 12"
Cohesion: 0.16
Nodes (4): InstrumentSearchView, MarketCatalogTests, InstrumentType, SymbolMatch

### Community 13 - "Community 13"
Cohesion: 0.14
Nodes (11): ClearFlowDialogs, SpectrumGlassPill, SpectrumPanelStyle, SpectrumPlusButton, View, CardStyle, Radius, Space (+3 more)

### Community 14 - "Community 14"
Cohesion: 0.16
Nodes (3): HoldingFormView, Investments, Store

### Community 15 - "Community 15"
Cohesion: 0.24
Nodes (4): Shape, SpectrumBudgetView, SpectrumMeter, VLine

### Community 16 - "Community 16"
Cohesion: 0.25
Nodes (8): Topic, budget, cushion, general, goals, netWorth, spending, subscriptions

### Community 17 - "Community 17"
Cohesion: 0.33
Nodes (3): AppIntent, AddExpenseIntent, QuickAddCoordinator

### Community 18 - "Community 18"
Cohesion: 0.4
Nodes (4): PennyPathMigrationPlan, PennyPathSchemaV1, SchemaMigrationPlan, VersionedSchema

### Community 19 - "Community 19"
Cohesion: 0.4
Nodes (4): ControlWidget, AddExpenseControl, PennyPathWidgetBundle, WidgetBundle

### Community 20 - "Community 20"
Cohesion: 0.67
Nodes (2): AppShortcutsProvider, PennyPathShortcuts

### Community 21 - "Community 21"
Cohesion: 0.67
Nodes (2): App, PennyPathApp

### Community 22 - "Community 22"
Cohesion: 0.67
Nodes (1): SupportLinks

## Knowledge Gaps
- **112 isolated node(s):** `system`, `light`, `dark`, `healthy`, `resetAfterFailure` (+107 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 20`** (3 nodes): `AppShortcutsProvider`, `PennyPathShortcuts.swift`, `PennyPathShortcuts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 21`** (3 nodes): `App`, `PennyPathApp.swift`, `PennyPathApp`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 22`** (3 nodes): `SupportLinks.swift`, `SupportLinks`, `.supportMailURL()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Font` connect `Community 2` to `Community 0`, `Community 3`, `Community 5`, `Community 10`, `Community 13`, `Community 14`, `Community 15`?**
  _High betweenness centrality (0.083) - this node is a cross-community bridge._
- **Why does `money()` connect `Community 5` to `Community 0`, `Community 2`, `Community 6`, `Community 7`, `Community 10`, `Community 15`?**
  _High betweenness centrality (0.073) - this node is a cross-community bridge._
- **Why does `Account` connect `Community 6` to `Community 0`, `Community 2`, `Community 4`, `Community 7`, `Community 9`, `Community 14`?**
  _High betweenness centrality (0.069) - this node is a cross-community bridge._
- **Are the 48 inferred relationships involving `Font` (e.g. with `.resultRow()` and `.featureRow()`) actually correct?**
  _`Font` has 48 INFERRED edges - model-reasoned connections that need verification._
- **Are the 32 inferred relationships involving `money()` (e.g. with `.accountRow()` and `.holdingRow()`) actually correct?**
  _`money()` has 32 INFERRED edges - model-reasoned connections that need verification._
- **Are the 27 inferred relationships involving `Account` (e.g. with `.fill()` and `.seed()`) actually correct?**
  _`Account` has 27 INFERRED edges - model-reasoned connections that need verification._
- **What connects `system`, `light`, `dark` to the rest of the system?**
  _112 weakly-connected nodes found - possible documentation gaps or missing edges._