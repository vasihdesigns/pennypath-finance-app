# Graph Report - Personal finace all in one app  (2026-06-20)

## Corpus Check
- 71 files · ~154,436 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 694 nodes · 1323 edges · 15 communities detected
- Extraction: 71% EXTRACTED · 29% INFERRED · 0% AMBIGUOUS · INFERRED: 386 edges (avg confidence: 0.8)
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

## God Nodes (most connected - your core abstractions)
1. `Font` - 51 edges
2. `SpectrumAccountSubtype` - 25 edges
3. `money()` - 24 edges
4. `Account` - 21 edges
5. `percentText()` - 18 edges
6. `InsightsEngine` - 16 edges
7. `SpectrumGoalsView` - 14 edges
8. `SpectrumNetWorthView` - 14 edges
9. `AccountCategory` - 14 edges
10. `ExpenseCategory` - 14 edges

## Surprising Connections (you probably didn't know these)
- `Int` --calls--> `percentText()`  [INFERRED]
   → PennyPath/Utilities/Money.swift  _Bridges community 7 → community 4_
- `AppSuggestion` --inherits--> `Hashable`  [EXTRACTED]
  PennyPath/Services/AppStoreSearch.swift →   _Bridges community 7 → community 3_
- `SpectrumAccountSubtype` --inherits--> `String`  [EXTRACTED]
  PennyPath/Features/Spectrum/SpectrumAddAccountView.swift →   _Bridges community 0 → community 7_
- `Insight` --inherits--> `Identifiable`  [EXTRACTED]
  PennyPath/Features/Coach/InsightsEngine.swift →   _Bridges community 0 → community 4_
- `SpectrumOnboardPage` --inherits--> `Identifiable`  [EXTRACTED]
  PennyPath/Features/Spectrum/SpectrumOnboardingView.swift →   _Bridges community 0 → community 1_

## Communities

### Community 0 - "Community 0"
Cohesion: 0.03
Nodes (76): AccountCategory, cash, creditCard, investment, loan, otherAsset, otherDebt, property (+68 more)

### Community 1 - "Community 1"
Cohesion: 0.03
Nodes (55): AccountFormView, FieldCard, CoachView, InsightCard, AmountField, ChipGrid, EmojiBadge, EmptyState (+47 more)

### Community 2 - "Community 2"
Cohesion: 0.05
Nodes (15): Account, AppStore, StoreHealth, healthy, inMemoryFallback, resetAfterFailure, CurrencyConversionTests, MockProvider (+7 more)

### Community 3 - "Community 3"
Cohesion: 0.06
Nodes (27): AppIconView, AppStoreSearch, AppSuggestion, Item, Response, Decodable, FXRates, InstrumentSearchView (+19 more)

### Community 4 - "Community 4"
Cohesion: 0.07
Nodes (24): Insight, InsightsEngine, Tone, neutral, positive, tip, warning, Topic (+16 more)

### Community 5 - "Community 5"
Cohesion: 0.05
Nodes (14): BudgetCategoryRow, BudgetView, CategoryBudget, Date, Expense, Goal, InsightsEngineTests, AccountTests (+6 more)

### Community 6 - "Community 6"
Cohesion: 0.05
Nodes (14): BudgetFormView, Haptics, ExpenseFormView, GoalFormView, OnboardingView, SettingsView, Outcome, expense (+6 more)

### Community 7 - "Community 7"
Cohesion: 0.04
Nodes (49): Pickable, Hashable, Int, Market, Markets, PreciousMetal, PreciousMetalSearchView, AppTab (+41 more)

### Community 8 - "Community 8"
Cohesion: 0.06
Nodes (16): SoftButtonStyle, DemoData, HomeView, HomeViewPremium, View, HomeViewRings, TripleRing, HomeViewSophisticated (+8 more)

### Community 9 - "Community 9"
Cohesion: 0.09
Nodes (10): ButtonStyle, PrimaryButtonStyle, HoldingFormView, Investments, AccountRow, HoldingRow, NetWorthView, SpectrumNetWorthView (+2 more)

### Community 10 - "Community 10"
Cohesion: 0.08
Nodes (15): Color, View, SpectrumAddAccountEntryView, Spectrum, SpectrumGlassPill, SpectrumHeader, SpectrumPanelStyle, SpectrumPlusButton (+7 more)

### Community 11 - "Community 11"
Cohesion: 0.17
Nodes (5): HillShape, Shape, SpectrumBudgetView, SpectrumMeter, VLine

### Community 12 - "Community 12"
Cohesion: 0.25
Nodes (5): AppIntent, AppShortcutsProvider, AddExpenseIntent, PennyPathShortcuts, QuickAddCoordinator

### Community 13 - "Community 13"
Cohesion: 0.33
Nodes (6): SpectrumOnboardArt, deck, expenses, goals, insights, netWorth

### Community 14 - "Community 14"
Cohesion: 0.67
Nodes (2): App, PennyPathApp

## Knowledge Gaps
- **125 isolated node(s):** `home`, `netWorth`, `expenses`, `goals`, `coach` (+120 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 14`** (3 nodes): `App`, `PennyPathApp.swift`, `PennyPathApp`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Font` connect `Community 8` to `Community 1`, `Community 4`, `Community 6`, `Community 7`, `Community 9`, `Community 10`, `Community 11`?**
  _High betweenness centrality (0.087) - this node is a cross-community bridge._
- **Why does `Account` connect `Community 2` to `Community 0`, `Community 3`, `Community 5`, `Community 8`, `Community 9`?**
  _High betweenness centrality (0.063) - this node is a cross-community bridge._
- **Why does `SpectrumAccountSubtype` connect `Community 7` to `Community 0`?**
  _High betweenness centrality (0.061) - this node is a cross-community bridge._
- **Are the 47 inferred relationships involving `Font` (e.g. with `.statTile()` and `.percentChip()`) actually correct?**
  _`Font` has 47 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `money()` (e.g. with `.paceCard()` and `.spendingInsights()`) actually correct?**
  _`money()` has 23 INFERRED edges - model-reasoned connections that need verification._
- **What connects `home`, `netWorth`, `expenses` to the rest of the system?**
  _125 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._