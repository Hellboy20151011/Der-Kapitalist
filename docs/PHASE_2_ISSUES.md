# Phase 2 Component Extraction Issues

This document contains detailed specifications for breaking down Phase 2 (Split Main.gd into Components) into separate, manageable issues/tasks.

## Overview

Phase 2 aims to reduce Main.gd from 830 lines to ~200 lines by extracting distinct responsibilities into separate components. This will be done through 5 sub-tasks:

1. **Phase 2.1:** Extract MarketPanel Component (~100 lines)
2. **Phase 2.2:** Extract ProductionManager Component (~80 lines)
3. **Phase 2.3:** Extract BuildingPanel Component (~60 lines)
4. **Phase 2.4:** Extract UIStateManager Component (~50 lines)
5. **Phase 2.5:** Final Main.gd Cleanup (~390 lines removed total)

---

## Phase 2.1: Extract MarketPanel Component

**Priority:** High  
**Estimated Effort:** 3-5 days  
**Dependencies:** GameConfig, Api, GameState (all exist)

### Description
Extract market-related functionality from `Main.gd` into a dedicated `MarketPanel` component to improve modularity.

### Tasks
- [ ] Create `Scenes/UI/MarketPanel.tscn` scene file
- [ ] Create `Scenes/UI/MarketPanel.gd` script (~100 lines)
- [ ] Define signals: `listing_purchased`, `listing_created`, `market_closed`
- [ ] Move market functions from Main.gd:
  - `_show_market()`
  - `_close_market()`
  - `_refresh_market_listings()`
  - `_add_listing_item(listing: Dictionary)`
  - `_buy_listing(listing_id, listing: Dictionary)`
  - `_create_market_listing()`
- [ ] Update Main.gd to connect to MarketPanel signals
- [ ] Test all market functionality
- [ ] Verify no regressions

### Files to Create/Modify
- Create: `Scenes/UI/MarketPanel.gd`
- Create: `Scenes/UI/MarketPanel.tscn`
- Modify: `Scenes/Game/Main.gd` (remove ~100 lines)
- Modify: `Scenes/Game/Main.tscn` (update scene tree)

### Success Criteria
- Market panel functions independently
- Main.gd reduced by ~100 lines
- All market operations work as before
- Clean signal-based communication established

---

## Phase 2.2: Extract ProductionManager Component

**Priority:** High  
**Estimated Effort:** 2-4 days  
**Dependencies:** GameConfig, Api, GameState (all exist)

### Description
Extract production polling, state tracking, and management into a dedicated `ProductionManager` autoload component.

### Tasks
- [ ] Create `autoload/ProductionManager.gd` script (~80 lines)
- [ ] Register as autoload in `project.godot`
- [ ] Define signals: `production_started`, `production_completed`, `production_state_changed`
- [ ] Move production state variables:
  - `well_producing`, `well_ready_at`
  - `lumber_producing`, `lumber_ready_at`
  - `sandgrube_producing`, `sandgrube_ready_at`
- [ ] Move production functions:
  - `_poll_production()`
  - Production state management logic
- [ ] Implement methods:
  - `start_production(building_type, quantity)`
  - `get_production_status(building_type)`
  - `is_building_producing(building_type)`
  - `get_ready_at(building_type)`
- [ ] Update Main.gd to use ProductionManager
- [ ] Test production timing and state sync
- [ ] Verify polling works correctly

### Files to Create/Modify
- Create: `autoload/ProductionManager.gd`
- Modify: `project.godot` (register autoload)
- Modify: `Scenes/Game/Main.gd` (remove ~80 lines)

### Success Criteria
- Production manager handles all production state
- Main.gd reduced by ~80 lines
- Production timing works correctly
- State is properly synchronized

---

## Phase 2.3: Extract BuildingPanel Component

**Priority:** Medium  
**Estimated Effort:** 2-3 days  
**Dependencies:** GameConfig (exists), ProductionManager (Phase 2.2)

### Description
Extract building information dialog and icon management into a dedicated `BuildingPanel` component.

### Tasks
- [ ] Create `Scenes/UI/BuildingPanel.tscn` scene file
- [ ] Create `Scenes/UI/BuildingPanel.gd` script (~60 lines)
- [ ] Define signals: `building_selected`, `building_action_requested`, `dialog_closed`
- [ ] Move building functions from Main.gd:
  - `_on_building_selected(index)`
  - `_on_home_icon_pressed()`
  - `_on_well_icon_pressed()`
  - `_on_lumber_icon_pressed()`
  - `_on_stone_icon_pressed()`
  - `_show_building_dialog()`
  - `_close_dialog()`
- [ ] Update Main.gd to connect to BuildingPanel signals
- [ ] Test building selection and display
- [ ] Verify dialog functionality

### Files to Create/Modify
- Create: `Scenes/UI/BuildingPanel.gd`
- Create: `Scenes/UI/BuildingPanel.tscn`
- Modify: `Scenes/Game/Main.gd` (remove ~60 lines)
- Modify: `Scenes/Game/Main.tscn` (update scene tree)

### Success Criteria
- Building panel functions independently
- Main.gd reduced by ~60 lines
- All building UI works as before
- Clean component separation

---

## Phase 2.4: Extract UIStateManager Component

**Priority:** Medium  
**Estimated Effort:** 2-3 days  
**Dependencies:** None (independent component)

### Description
Extract UI state management (loading, buttons, status messages) into a dedicated `UIStateManager` autoload component.

### Tasks
- [ ] Create `autoload/UIStateManager.gd` script (~50 lines)
- [ ] Register as autoload in `project.godot`
- [ ] Define signals: `loading_changed`, `status_changed`, `buttons_state_changed`
- [ ] Move UI state functions from Main.gd:
  - `_show_loading(show: bool)`
  - `_disable_buttons(disable: bool)`
  - `_set_status(msg, is_result)`
- [ ] Implement button group management
- [ ] Implement status message timeout handling
- [ ] Update Main.gd to use UIStateManager
- [ ] Test UI state changes
- [ ] Verify loading and button states work

### Files to Create/Modify
- Create: `autoload/UIStateManager.gd`
- Modify: `project.godot` (register autoload)
- Modify: `Scenes/Game/Main.gd` (remove ~50 lines)

### Success Criteria
- UI state manager handles all UI state
- Main.gd reduced by ~50 lines
- Loading states work correctly
- Status messages display properly

---

## Phase 2.5: Final Main.gd Cleanup and Integration

**Priority:** High  
**Estimated Effort:** 3-5 days  
**Dependencies:** Phases 2.1, 2.2, 2.3, 2.4 must be complete

### Description
Final cleanup and integration of all Phase 2 components. Reduce Main.gd to ~200 lines containing only high-level coordination logic.

### Tasks
- [ ] Remove any remaining duplicate code
- [ ] Simplify `_sync_state()` function
- [ ] Consolidate initialization logic
- [ ] Remove unused variables and functions
- [ ] Update scene tree structure in Main.tscn
- [ ] Comprehensive integration testing
- [ ] Performance testing
- [ ] Update documentation
- [ ] Update modularity assessment scores

### Target Structure for Main.gd (~200 lines)
Should only contain:
- Scene initialization (`_ready()`)
- Component registration and setup
- High-level event handlers
- Navigation between sections
- Data synchronization coordination
- Logout functionality

### Testing Checklist
- [ ] All game functionality works
- [ ] No regressions in features
- [ ] Components communicate correctly
- [ ] State remains consistent
- [ ] Performance is acceptable
- [ ] No memory leaks
- [ ] Error handling works

### Files to Modify
- Modify: `Scenes/Game/Main.gd` (reduce to ~200 lines)
- Modify: `Scenes/Game/Main.tscn` (final scene structure)
- Modify: `docs/MODULARITY_ASSESSMENT.md` (update scores)
- Modify: `docs/REFACTORING_PROGRESS.md` (mark Phase 2 complete)

### Success Criteria
- Main.gd is ~200 lines or less
- All functionality works perfectly
- No regressions
- **Modularity Score: 9.0/10 achieved**
- Clean, maintainable architecture
- Well-documented

---

## Implementation Order

**Recommended order of implementation:**

1. **Phase 2.4** (UIStateManager) - Independent, provides foundation
2. **Phase 2.2** (ProductionManager) - Independent, clear boundaries
3. **Phase 2.1** (MarketPanel) - Can use UIStateManager
4. **Phase 2.3** (BuildingPanel) - Can use ProductionManager state
5. **Phase 2.5** (Final Cleanup) - Integrates everything

**Alternative order (parallel work possible):**

- **Track 1:** Phase 2.1 (MarketPanel) + Phase 2.3 (BuildingPanel)
- **Track 2:** Phase 2.2 (ProductionManager) + Phase 2.4 (UIStateManager)
- **Final:** Phase 2.5 (Integration)

---

## Expected Outcomes

### Code Metrics
- **Main.gd:** 830 → ~200 lines (76% reduction)
- **Total codebase:** ~1,280 lines across 7 well-organized files
- **Modularity Score:** 7.2/10 → 9.0/10

### Files Created
1. `autoload/GameConfig.gd` (75 lines) - ✅ Already done
2. `autoload/ProductionManager.gd` (~80 lines)
3. `autoload/UIStateManager.gd` (~50 lines)
4. `Scenes/UI/MarketPanel.gd` (~100 lines)
5. `Scenes/UI/BuildingPanel.gd` (~60 lines)

### Architecture Benefits
- Clear separation of concerns
- Reusable components
- Easier testing
- Better maintainability
- Signal-based communication
- Reduced coupling

---

## References

- Parent Issue: #36 (Modularity Assessment)
- `docs/MODULARITY_ASSESSMENT.md` - Original assessment
- `docs/REFACTORING_PROGRESS.md` - Current progress
- Phase 1: Duplicate production system removal (✅ Complete)
