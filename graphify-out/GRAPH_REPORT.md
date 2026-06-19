# Graph Report - Personal finace all in one app  (2026-06-20)

## Corpus Check
- 153 files · ~215,515 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1463 nodes · 2898 edges · 32 communities detected
- Extraction: 70% EXTRACTED · 30% INFERRED · 0% AMBIGUOUS · INFERRED: 870 edges (avg confidence: 0.8)
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
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]

## God Nodes (most connected - your core abstractions)
1. `Font` - 141 edges
2. `money()` - 54 edges
3. `MonoAccountSubtype` - 25 edges
4. `AccountSubtype` - 25 edges
5. `SpectrumAccountSubtype` - 25 edges
6. `Account` - 24 edges
7. `percentText()` - 23 edges
8. `DevHomeStyle` - 22 edges
9. `InsightsEngine` - 16 edges
10. `SummitWorthView` - 14 edges

## Surprising Connections (you probably didn't know these)
- `Int` --calls--> `percentText()`  [INFERRED]
   → PennyPath/Utilities/Money.swift  _Bridges community 8 → community 2_
- `Insight` --inherits--> `Hashable`  [EXTRACTED]
  PennyPath/Features/Coach/InsightsEngine.swift →   _Bridges community 5 → community 2_
- `MonoAccountSubtype` --inherits--> `Hashable`  [EXTRACTED]
  PennyPath/Features/Mono/MonoAddAccountView.swift →   _Bridges community 5 → community 14_
- `AccountSubtype` --inherits--> `Hashable`  [EXTRACTED]
  PennyPath/Features/Ember/EmberAddAccountView.swift →   _Bridges community 5 → community 15_
- `Field` --inherits--> `Hashable`  [EXTRACTED]
  PennyPath/Features/Spectrum/SpectrumBudgetView.swift →   _Bridges community 5 → community 12_

## Communities

### Community 0 - "Community 0"
Cohesion: 0.01
Nodes (135): AuroraArt, comet, constellation, nova, orbs, quest, AuroraArtView, AuroraOnboardingView (+127 more)

### Community 1 - "Community 1"
Cohesion: 0.01
Nodes (164): AccountCategory, cash, creditCard, investment, loan, otherAsset, otherDebt, property (+156 more)

### Community 2 - "Community 2"
Cohesion: 0.03
Nodes (48): BudgetCategoryRow, BudgetView, CategoryBudget, ClarityHealth, ClaritySignal, Status, fair, good (+40 more)

### Community 3 - "Community 3"
Cohesion: 0.03
Nodes (37): AuroraFlowView, ClarityAdviceView, ClarityTodayView, Color, SoftButtonStyle, DemoData, GoalDetailView, HomeView (+29 more)

### Community 4 - "Community 4"
Cohesion: 0.03
Nodes (32): BudgetFormView, ButtonStyle, PrimaryButtonStyle, EmberAddAccountView, EmberBudgetView, EmberInsightsView, Ember, EmberGlassPill (+24 more)

### Community 5 - "Community 5"
Cohesion: 0.03
Nodes (69): AuroraTab, flow, nova, pulse, quests, ClarityTab, goals, spending (+61 more)

### Community 6 - "Community 6"
Cohesion: 0.05
Nodes (18): Account, CurrencyConversionTests, MockProvider, FXRates, _reset(), InstrumentSearchView, MarketCatalogTests, InstrumentType (+10 more)

### Community 7 - "Community 7"
Cohesion: 0.05
Nodes (11): ClarityWorthView, EmberNetWorthView, HoldingFormView, Investments, MonoNetWorthView, MonoSubsStatsSheet, MonoUpcomingView, AccountRow (+3 more)

### Community 8 - "Community 8"
Cohesion: 0.04
Nodes (36): AppIconView, AppStoreSearch, AppSuggestion, Item, Response, Decodable, EmberAllocationSlice, EmberAllocationView (+28 more)

### Community 9 - "Community 9"
Cohesion: 0.06
Nodes (35): EmberMoneyKind, cash, investment, liability, property, receivable, Range, all (+27 more)

### Community 10 - "Community 10"
Cohesion: 0.06
Nodes (12): AccountFormView, FieldCard, AppStore, StoreHealth, healthy, inMemoryFallback, resetAfterFailure, Holding (+4 more)

### Community 11 - "Community 11"
Cohesion: 0.07
Nodes (16): Font, Font, Font, Font, Font, Strata, StrataBand, StrataCardStyle (+8 more)

### Community 12 - "Community 12"
Cohesion: 0.12
Nodes (9): HillShape, Shape, Field, category, income, total, SpectrumBudgetView, SpectrumMeter (+1 more)

### Community 13 - "Community 13"
Cohesion: 0.11
Nodes (11): AuroraGuideView, NovaOrb, AuroraPulseView, Aurora, AuroraBeamButton, AuroraCardStyle, AuroraOverline, AuroraSky (+3 more)

### Community 14 - "Community 14"
Cohesion: 0.09
Nodes (21): MonoAccountSubtype, car, cash, cashOther, creditCard, crypto, debitCard, deposit (+13 more)

### Community 15 - "Community 15"
Cohesion: 0.09
Nodes (21): AccountSubtype, car, cash, cashOther, creditCard, crypto, debitCard, deposit (+13 more)

### Community 16 - "Community 16"
Cohesion: 0.13
Nodes (10): VividCoachView, VividHomeView, View, VividAmount, VividCardStyle, VividDonut, VividMonogram, VividOverline (+2 more)

### Community 17 - "Community 17"
Cohesion: 0.1
Nodes (8): Outcome, expense, futurePayment, subscription, SpectrumAddItemView, UpcomingPayment, CategoryPickerView, UpcomingPaymentFormView

### Community 18 - "Community 18"
Cohesion: 0.18
Nodes (7): MonoInsightsView, Mono, MonoGlassPill, MonoHeader, MonoPanelStyle, MonoPlusButton, View

### Community 19 - "Community 19"
Cohesion: 0.16
Nodes (5): Sage, SageCardStyle, SageOverline, View, SageWorthView

### Community 20 - "Community 20"
Cohesion: 0.14
Nodes (11): SpectrumGlass, SpectrumOnboardArt, deck, expenses, goals, insights, netWorth, SpectrumOnboardingView (+3 more)

### Community 21 - "Community 21"
Cohesion: 0.17
Nodes (3): Goal, GoalFormView, GoalTests

### Community 22 - "Community 22"
Cohesion: 0.21
Nodes (10): OnyxAsset, OnyxAssetCard, OnyxBackground, OnyxGlassCircleButton, OnyxGlassCircleStyle, OnyxGlassPill, OnyxGlassStyle, OnyxPlusButton (+2 more)

### Community 23 - "Community 23"
Cohesion: 0.25
Nodes (5): AppIntent, AppShortcutsProvider, AddExpenseIntent, PennyPathShortcuts, QuickAddCoordinator

### Community 24 - "Community 24"
Cohesion: 0.29
Nodes (5): CardStyle, Radius, Space, Theme, View

### Community 25 - "Community 25"
Cohesion: 0.32
Nodes (2): SpectrumSubsStatsSheet, SpectrumUpcomingView

### Community 26 - "Community 26"
Cohesion: 0.4
Nodes (5): VividArt, donut, hero, ring, spark

### Community 27 - "Community 27"
Cohesion: 0.4
Nodes (5): PrismArt, boxes, insight, spend, worth

### Community 28 - "Community 28"
Cohesion: 0.4
Nodes (5): ClarityArt, line, mark, ring, rule

### Community 29 - "Community 29"
Cohesion: 0.4
Nodes (5): StrataArt, insight, layers, trend, worth

### Community 30 - "Community 30"
Cohesion: 0.4
Nodes (4): HoldingSearchMode, funds, markets, HoldingSearchView

### Community 31 - "Community 31"
Cohesion: 0.67
Nodes (2): App, PennyPathApp

## Knowledge Gaps
- **294 isolated node(s):** `home`, `netWorth`, `expenses`, `goals`, `coach` (+289 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 25`** (8 nodes): `SpectrumUpcomingView.swift`, `SpectrumSubsStatsSheet`, `SpectrumUpcomingView`, `.compact()`, `.dueLabel()`, `.markPaid()`, `.row()`, `.stat()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 31`** (3 nodes): `App`, `PennyPathApp.swift`, `PennyPathApp`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Font` connect `Community 3` to `Community 0`, `Community 1`, `Community 2`, `Community 4`, `Community 5`, `Community 7`, `Community 8`, `Community 9`, `Community 11`, `Community 12`, `Community 13`, `Community 16`, `Community 18`, `Community 19`, `Community 22`, `Community 24`, `Community 25`?**
  _High betweenness centrality (0.110) - this node is a cross-community bridge._
- **Why does `money()` connect `Community 2` to `Community 3`, `Community 4`, `Community 7`, `Community 8`, `Community 9`, `Community 12`, `Community 13`, `Community 16`, `Community 19`, `Community 25`?**
  _High betweenness centrality (0.050) - this node is a cross-community bridge._
- **Why does `MonoAccountSubtype` connect `Community 14` to `Community 1`, `Community 4`, `Community 5`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **Are the 137 inferred relationships involving `Font` (e.g. with `.statTile()` and `.percentChip()`) actually correct?**
  _`Font` has 137 INFERRED edges - model-reasoned connections that need verification._
- **Are the 63 inferred relationships involving `ButtonStyle` (e.g. with `.statTile()` and `.statCard()`) actually correct?**
  _`ButtonStyle` has 63 INFERRED edges - model-reasoned connections that need verification._
- **Are the 53 inferred relationships involving `money()` (e.g. with `.paceCard()` and `.accountRow()`) actually correct?**
  _`money()` has 53 INFERRED edges - model-reasoned connections that need verification._
- **What connects `home`, `netWorth`, `expenses` to the rest of the system?**
  _294 weakly-connected nodes found - possible documentation gaps or missing edges._