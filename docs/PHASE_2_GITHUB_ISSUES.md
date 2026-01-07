# GitHub Issues for Phase 2 - Quick Reference

This document provides ready-to-copy issue templates for creating GitHub issues for each Phase 2 component.

---

## Issue 1: Phase 2.1 - Extract MarketPanel Component

**Title:** `[Phase 2.1] Extract MarketPanel component from Main.gd`

**Labels:** `enhancement`, `refactoring`, `phase-2`

**Assignee:** (assign as needed)

**Description:**
```markdown
## Overview
Extract market-related functionality from `Main.gd` into a dedicated `MarketPanel` component (~100 lines).

**Parent Issue:** #36  
**Phase:** 2.1 of Phase 2 (Split Main.gd into Components)  
**Priority:** High  
**Estimated Effort:** 3-5 days

## Tasks
- [ ] Create `Scenes/UI/MarketPanel.tscn` scene file
- [ ] Create `Scenes/UI/MarketPanel.gd` script
- [ ] Define signals: `listing_purchased`, `listing_created`, `market_closed`
- [ ] Move 6 market functions from Main.gd
- [ ] Update Main.gd to use MarketPanel signals
- [ ] Test market functionality (buy, sell, refresh, create listing)
- [ ] Verify no regressions

## Expected Outcome
- Main.gd reduced by ~100 lines
- Market functionality isolated in reusable component
- Clean signal-based communication

## References
- See `docs/PHASE_2_ISSUES.md` for detailed specification
- Related to #36 (Modularity Assessment)
```

---

## Issue 2: Phase 2.2 - Extract ProductionManager Component

**Title:** `[Phase 2.2] Extract ProductionManager autoload from Main.gd`

**Labels:** `enhancement`, `refactoring`, `phase-2`

**Description:**
```markdown
## Overview
Extract production polling and state management into a dedicated `ProductionManager` autoload (~80 lines).

**Parent Issue:** #36  
**Phase:** 2.2 of Phase 2 (Split Main.gd into Components)  
**Priority:** High  
**Estimated Effort:** 2-4 days

## Tasks
- [ ] Create `autoload/ProductionManager.gd` script
- [ ] Register as autoload in `project.godot`
- [ ] Define signals: `production_started`, `production_completed`, `production_state_changed`
- [ ] Move production state variables and polling logic
- [ ] Implement production management API
- [ ] Update Main.gd to use ProductionManager
- [ ] Test production timing and state synchronization
- [ ] Verify polling works correctly

## Expected Outcome
- Main.gd reduced by ~80 lines
- Centralized production state management
- Proper timer handling in autoload

## References
- See `docs/PHASE_2_ISSUES.md` for detailed specification
- Related to #36 (Modularity Assessment)
```

---

## Issue 3: Phase 2.3 - Extract BuildingPanel Component

**Title:** `[Phase 2.3] Extract BuildingPanel component from Main.gd`

**Labels:** `enhancement`, `refactoring`, `phase-2`

**Description:**
```markdown
## Overview
Extract building information dialog and icon management into a dedicated `BuildingPanel` component (~60 lines).

**Parent Issue:** #36  
**Phase:** 2.3 of Phase 2 (Split Main.gd into Components)  
**Priority:** Medium  
**Estimated Effort:** 2-3 days  
**Dependencies:** Phase 2.2 (ProductionManager) recommended

## Tasks
- [ ] Create `Scenes/UI/BuildingPanel.tscn` scene file
- [ ] Create `Scenes/UI/BuildingPanel.gd` script
- [ ] Define signals: `building_selected`, `building_action_requested`, `dialog_closed`
- [ ] Move 7 building-related functions from Main.gd
- [ ] Update Main.gd to use BuildingPanel signals
- [ ] Test building selection and dialog display
- [ ] Verify icon handlers work correctly

## Expected Outcome
- Main.gd reduced by ~60 lines
- Building UI logic separated and reusable
- Clean component for building display

## References
- See `docs/PHASE_2_ISSUES.md` for detailed specification
- Related to #36 (Modularity Assessment)
```

---

## Issue 4: Phase 2.4 - Extract UIStateManager Component

**Title:** `[Phase 2.4] Extract UIStateManager autoload from Main.gd`

**Labels:** `enhancement`, `refactoring`, `phase-2`

**Description:**
```markdown
## Overview
Extract UI state management (loading, buttons, status messages) into a dedicated `UIStateManager` autoload (~50 lines).

**Parent Issue:** #36  
**Phase:** 2.4 of Phase 2 (Split Main.gd into Components)  
**Priority:** Medium  
**Estimated Effort:** 2-3 days  
**Dependencies:** None (independent)

## Tasks
- [ ] Create `autoload/UIStateManager.gd` script
- [ ] Register as autoload in `project.godot`
- [ ] Define signals: `loading_changed`, `status_changed`, `buttons_state_changed`
- [ ] Move 3 UI state functions from Main.gd
- [ ] Implement button group management
- [ ] Implement status message timeout handling
- [ ] Update Main.gd to use UIStateManager
- [ ] Test loading states and status messages

## Expected Outcome
- Main.gd reduced by ~50 lines
- Centralized UI state management
- Reusable across different scenes

## References
- See `docs/PHASE_2_ISSUES.md` for detailed specification
- Related to #36 (Modularity Assessment)
```

---

## Issue 5: Phase 2.5 - Final Main.gd Cleanup and Integration

**Title:** `[Phase 2.5] Final Main.gd cleanup and component integration`

**Labels:** `enhancement`, `refactoring`, `phase-2`, `testing`

**Description:**
```markdown
## Overview
Final cleanup and integration of all Phase 2 components. Reduce Main.gd to ~200 lines containing only high-level coordination logic.

**Parent Issue:** #36  
**Phase:** 2.5 of Phase 2 (Split Main.gd into Components) - **Final Step**  
**Priority:** High  
**Estimated Effort:** 3-5 days  
**Dependencies:** Phases 2.1, 2.2, 2.3, 2.4 must be complete

## Tasks
- [ ] Remove any remaining duplicate code
- [ ] Simplify `_sync_state()` function
- [ ] Consolidate initialization logic
- [ ] Update scene tree structure
- [ ] Comprehensive integration testing
- [ ] Performance testing
- [ ] Update documentation and modularity scores

## Expected Outcome
- Main.gd reduced to ~200 lines (76% reduction from 830)
- **Modularity Score: 9.0/10 achieved**
- All functionality works perfectly
- No regressions
- Clean, maintainable architecture

## Testing Required
- [ ] All game functionality works
- [ ] Components communicate correctly
- [ ] State remains consistent
- [ ] No memory leaks
- [ ] Performance is acceptable

## References
- See `docs/PHASE_2_ISSUES.md` for detailed specification
- Related to #36 (Modularity Assessment)
- Completes Phase 2 of 3-phase refactoring roadmap
```

---

## Implementation Notes

### Recommended Order
1. **Phase 2.4** (UIStateManager) - Independent foundation
2. **Phase 2.2** (ProductionManager) - Clear boundaries
3. **Phase 2.1** (MarketPanel) - Uses UIStateManager
4. **Phase 2.3** (BuildingPanel) - Uses ProductionManager
5. **Phase 2.5** (Final Cleanup) - Integration

### Parallel Work
Two developers can work in parallel:
- **Developer 1:** Phases 2.1 + 2.3 (UI components)
- **Developer 2:** Phases 2.2 + 2.4 (Autoload managers)
- **Both:** Phase 2.5 (Integration)

### Total Effort
- Individual tasks: 2-5 days each
- Total sequential: 12-20 days
- With parallelization: 8-12 days

---

## Creating the Issues

To create these issues in GitHub:

1. Go to repository Issues page
2. Click "New Issue"
3. Copy/paste the title and description from above
4. Add appropriate labels
5. Link to parent issue #36
6. Add to project/milestone if applicable
7. Assign to developer(s)

Or use GitHub CLI:
```bash
gh issue create --title "[Phase 2.1] Extract MarketPanel component from Main.gd" \
  --body-file phase-2-1-description.md \
  --label "enhancement,refactoring,phase-2"
```
