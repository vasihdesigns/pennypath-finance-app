# Graph Report - Personal finace all in one app  (2026-06-11)

## Corpus Check
- 58 files · ~134,273 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 441 nodes · 724 edges · 16 communities detected
- Extraction: 76% EXTRACTED · 24% INFERRED · 0% AMBIGUOUS · INFERRED: 177 edges (avg confidence: 0.8)
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
1. `Font` - 24 edges
2. `AccountCategory` - 14 edges
3. `ExpenseCategory` - 14 edges
4. `InsightsEngine` - 13 edges
5. `money()` - 12 edges
6. `Goal` - 11 edges
7. `Account` - 11 edges
8. `percentText()` - 11 edges
9. `StoreBehaviorTests` - 11 edges
10. `DevHomeStyle` - 10 edges

## Surprising Connections (you probably didn't know these)
- `Insight` --inherits--> `Hashable`  [EXTRACTED]
  PennyPath/Features/Coach/InsightsEngine.swift →   _Bridges community 0 → community 6_
- `SymbolMatch` --inherits--> `Hashable`  [EXTRACTED]
  PennyPath/Services/MarketData.swift →   _Bridges community 0 → community 3_
- `ContributeMode` --inherits--> `String`  [EXTRACTED]
  PennyPath/Features/Goals/GoalDetailView.swift →   _Bridges community 0 → community 12_
- `OnboardingPage` --inherits--> `Identifiable`  [EXTRACTED]
  PennyPath/Features/Onboarding/OnboardingView.swift →   _Bridges community 0 → community 7_
- `RootView` --inherits--> `View`  [EXTRACTED]
  PennyPath/App/RootView.swift →   _Bridges community 0 → community 1_

## Communities

### Community 0 - "Community 0"
Cohesion: 0.04
Nodes (60): AccountCategory, cash, creditCard, investment, loan, otherAsset, otherDebt, property (+52 more)

### Community 1 - "Community 1"
Cohesion: 0.06
Nodes (35): CoachView, InsightCard, AmountField, ChipGrid, EmojiBadge, EmptyState, ProgressBar, ProgressRing (+27 more)

### Community 2 - "Community 2"
Cohesion: 0.05
Nodes (19): ButtonStyle, PrimaryButtonStyle, SoftButtonStyle, HomeView, HomeViewPremium, View, HomeViewRings, TripleRing (+11 more)

### Community 3 - "Community 3"
Cohesion: 0.08
Nodes (20): Decodable, InstrumentSearchView, LocalizedError, MarketCatalogTests, Chart, ChartResponse, InstrumentType, Item (+12 more)

### Community 4 - "Community 4"
Cohesion: 0.08
Nodes (8): Account, AccountFormView, FieldCard, AppStore, NetWorthHistory, NetWorthSnapshot, SampleData, StoreBehaviorTests

### Community 5 - "Community 5"
Cohesion: 0.07
Nodes (9): BudgetFormView, CategoryBudget, Expense, Goal, InsightsEngineTests, AccountTests, ExpenseTests, GoalTests (+1 more)

### Community 6 - "Community 6"
Cohesion: 0.14
Nodes (12): Insight, InsightsEngine, Tone, neutral, positive, tip, warning, AppSettings (+4 more)

### Community 7 - "Community 7"
Cohesion: 0.1
Nodes (12): Haptics, OnboardingArt, coach, goals, logo, netWorth, spending, OnboardingPage (+4 more)

### Community 8 - "Community 8"
Cohesion: 0.13
Nodes (5): DemoData, Holding, HoldingFormView, Investments, OnboardingArtView

### Community 9 - "Community 9"
Cohesion: 0.13
Nodes (5): ExpenseFormView, GoalFormView, AccountRow, HoldingRow, NetWorthView

### Community 10 - "Community 10"
Cohesion: 0.13
Nodes (7): SageCoachView, Sage, SageCardStyle, SageOverline, View, SageWorthView, ViewModifier

### Community 11 - "Community 11"
Cohesion: 0.18
Nodes (4): BudgetCategoryRow, BudgetView, Date, DateHelperTests

### Community 12 - "Community 12"
Cohesion: 0.12
Nodes (10): ContributeMode, add, withdraw, GoalContributeView, GoalDetailView, CardStyle, Radius, Space (+2 more)

### Community 13 - "Community 13"
Cohesion: 0.25
Nodes (5): AppIntent, AppShortcutsProvider, AddExpenseIntent, PennyPathShortcuts, QuickAddCoordinator

### Community 14 - "Community 14"
Cohesion: 0.5
Nodes (1): Color

### Community 15 - "Community 15"
Cohesion: 0.67
Nodes (2): App, PennyPathApp

## Knowledge Gaps
- **62 isolated node(s):** `home`, `netWorth`, `expenses`, `goals`, `coach` (+57 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 14`** (4 nodes): `Color`, `.adaptive()`, `.init()`, `Color+Hex.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 15`** (3 nodes): `App`, `PennyPathApp.swift`, `PennyPathApp`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Font` connect `Community 2` to `Community 0`, `Community 1`, `Community 8`, `Community 10`, `Community 12`?**
  _High betweenness centrality (0.085) - this node is a cross-community bridge._
- **Why does `Account` connect `Community 4` to `Community 8`, `Community 5`?**
  _High betweenness centrality (0.068) - this node is a cross-community bridge._
- **Why does `Insight` connect `Community 6` to `Community 0`?**
  _High betweenness centrality (0.062) - this node is a cross-community bridge._
- **Are the 20 inferred relationships involving `Font` (e.g. with `.statTile()` and `.percentChip()`) actually correct?**
  _`Font` has 20 INFERRED edges - model-reasoned connections that need verification._
- **What connects `home`, `netWorth`, `expenses` to the rest of the system?**
  _62 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._