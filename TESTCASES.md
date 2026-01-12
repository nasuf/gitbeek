# Test Cases for AllChangeRequestsViewModel Changes

## Overview
This document describes test cases for the recent changes to `AllChangeRequestsViewModel`, `LiquidGlassFilterBar`, and `AllChangeRequestsView`.

## Core Changes
1. Pull-to-refresh returns immediately (top spinner disappears)
2. If already loading, pull-to-refresh doesn't interrupt previous load
3. Task cancellation mechanism with multiple checkpoints
4. Filter bar auto-scrolls to center when filter is tapped
5. Loading view shows "Loading change requests..." when data is empty
6. Data displays immediately once available (even if loading not complete)

---

## Test Cases

### 1. Initial Load
**Scenario:** User opens All Change Requests view for the first time

**Steps:**
1. Launch app
2. Navigate to All Change Requests view

**Expected Result:**
- `isLoading` = true initially
- All filters show loading spinner icons
- Content area shows "Loading change requests..."
- After data loads:
  - `isLoading` = false
  - Filters show actual counts
  - Change requests displayed in hierarchy (collections > spaces)
  - `hasLoadedData` = true

**Pass Criteria:**
- ✅ Loading indicators appear correctly
- ✅ Data loads successfully
- ✅ Hierarchy structure correct (collections before top-level spaces)
- ✅ Change requests sorted by updated date (newest first)

---

### 2. Pull-to-Refresh - Normal Flow
**Scenario:** User pulls to refresh when NOT currently loading

**Steps:**
1. Open All Change Requests view (wait for initial load)
2. Pull down to trigger refresh
3. Observe top spinning indicator
4. Release the pull gesture

**Expected Result:**
- Top spinning indicator appears briefly (~100ms)
- Top indicator disappears immediately after release
- Screen scrolls back to top automatically
- Filter shows reset to "All"
- All filters show loading spinner icons
- Content area shows either:
  - Previous data (if exists) OR
  - "Loading change requests..." (if no data)
- Background loading continues
- Once complete: new data appears, loading indicators disappear

**Pass Criteria:**
- ✅ Top spinner disappears within ~100ms
- ✅ Filter resets to "All"
- ✅ UI remains responsive during loading
- ✅ Data updates after loading complete

---

### 3. Pull-to-Refresh - Already Loading
**Scenario:** User pulls to refresh WHILE previous load is still in progress

**Steps:**
1. Open All Change Requests view
2. Immediately pull to refresh (before initial load completes)
3. Release the pull gesture
4. Observe behavior

**Expected Result:**
- Top spinning indicator appears briefly
- Top indicator disappears immediately after release (~100ms)
- Screen scrolls back to top
- Filter resets to "All"
- **Previous loading continues without interruption**
- No error messages
- Data appears when original loading completes

**Pass Criteria:**
- ✅ Top spinner disappears quickly
- ✅ No interruption of previous load
- ✅ No errors or warnings
- ✅ Filter resets correctly
- ✅ Data loads successfully from original request

---

### 4. Cancellation During Load
**Scenario:** User cancels pull-to-refresh mid-load

**Steps:**
1. Have slow network or add delay to mock
2. Pull to refresh
3. Release gesture (cancel refresh)
4. Wait for background task to notice cancellation

**Expected Result:**
- Background task checks `Task.isCancelled` at multiple points
- Task exits early at next checkpoint
- No error dialog appears
- `isLoading` resets to false
- UI remains in stable state

**Pass Criteria:**
- ✅ No "request cancelled" error dialog
- ✅ Loading state resets properly
- ✅ App remains responsive

---

### 5. Filter Selection with Auto-Scroll
**Scenario:** User taps different filters in the filter bar

**Steps:**
1. Open All Change Requests view (wait for load)
2. Observe initial filter position (should be "All")
3. Tap "Archived" filter (rightmost)
4. Observe scroll animation
5. Tap "All" filter (leftmost)
6. Observe scroll animation

**Expected Result:**
- Tapping "Archived":
  - Filter bar scrolls smoothly to show "Archived" centered
  - Content updates to show only archived change requests
  - Selected filter has blue border and loading icon removed
- Tapping "All":
  - Filter bar scrolls smoothly to show "All" centered
  - Content updates to show all change requests

**Pass Criteria:**
- ✅ Filter bar scrolls to center selected filter
- ✅ Smooth animation (spring, response: 0.3)
- ✅ Content filters correctly
- ✅ UI updates immediately

---

### 6. Loading View Display
**Scenario:** User switches filters while loading

**Steps:**
1. Start with data loaded
2. Pull to refresh
3. Immediately tap "Draft" filter
4. Observe content area

**Expected Result:**
- If draft data exists: show existing draft change requests
- If no draft data: show "Loading change requests..." message with spinner
- Once loading completes: update with fresh draft data

**Pass Criteria:**
- ✅ Loading message shows when filter has no data
- ✅ Existing data shows immediately if available
- ✅ UI doesn't flicker or show empty states incorrectly

---

### 7. Caching Mechanism
**Scenario:** User leaves and returns to view

**Steps:**
1. Open All Change Requests view (wait for load)
2. Navigate away from view
3. Return to All Change Requests view

**Expected Result:**
- Cached data displays immediately
- No loading indicators
- No new API calls made
- `hasLoadedData` remains true

**Steps (Force Refresh):**
4. Pull to refresh

**Expected Result:**
- Forces new load even with cached data
- Data clears temporarily
- Fresh data loads from API

**Pass Criteria:**
- ✅ Cache works correctly (no reload on revisit)
- ✅ Force refresh bypasses cache
- ✅ API call count matches expectations

---

### 8. Multiple Organizations/Spaces
**Scenario:** User has multiple organizations with multiple spaces

**Steps:**
1. Mock data with:
   - 2 organizations
   - 3 collections (2 in org1, 1 in org2)
   - 5 spaces (3 in collections, 2 top-level)
   - 10 change requests distributed across spaces
2. Load view

**Expected Result:**
- All organizations queried
- All spaces and collections retrieved
- Change requests grouped correctly:
  - Collection groups appear first (sorted by title)
  - Top-level space groups appear after
- Counts accurate in filter bar

**Pass Criteria:**
- ✅ All organizations loaded
- ✅ Hierarchy correct (collections > spaces)
- ✅ Counts match reality
- ✅ No duplicate entries

---

### 9. Error Handling
**Scenario:** API call fails during load

**Steps:**
1. Mock organization repository to throw error
2. Attempt to load

**Expected Result:**
- `isLoading` = false after error
- `error` property set
- Alert dialog shows error message
- `hasLoadedData` remains false
- User can dismiss alert
- User can retry (pull to refresh)

**Pass Criteria:**
- ✅ Error handled gracefully
- ✅ UI recovers properly
- ✅ Retry works correctly

---

### 10. Filter Counts
**Scenario:** Verify counts update correctly

**Steps:**
1. Load data with mixed statuses:
   - 2 open
   - 1 draft
   - 3 merged
   - 1 archived
2. Observe filter bar

**Expected Result:**
- All: 7
- Open: 2
- Draft: 1
- Merged: 3
- Archived: 1

**Steps (Filter):**
3. Tap each filter and verify content matches count

**Pass Criteria:**
- ✅ Counts accurate for each status
- ✅ Filtered content matches count
- ✅ Counts update after refresh

---

### 11. Sort Order
**Scenario:** Verify change requests sorted by updated date

**Steps:**
1. Mock change requests with specific dates:
   - CR1: updated 3 days ago
   - CR2: updated 1 day ago
   - CR3: updated 5 days ago
2. Load view

**Expected Result:**
- Order: CR2, CR1, CR3 (newest first)

**Pass Criteria:**
- ✅ Correct sort order
- ✅ Sort applies across all spaces/collections

---

### 12. Expand/Collapse Collections
**Scenario:** User expands and collapses collection

**Steps:**
1. Load view with collection containing change requests
2. Tap collection header to expand
3. Observe change requests appear
4. Tap header again to collapse

**Expected Result:**
- Initially collapsed
- Expands to show all change requests in collection
- Collapses to hide change requests
- State persists during session

**Pass Criteria:**
- ✅ Expand/collapse animation smooth
- ✅ State tracked correctly
- ✅ Content displays properly

---

### 13. Display Mode Toggle
**Scenario:** User toggles display mode for collection

**Steps:**
1. Expand a collection
2. Default mode: "Grouped by Spaces"
3. Tap display mode toggle icon
4. Observe change to "Flat by Time"
5. Toggle again

**Expected Result:**
- Grouped mode: Change requests grouped under each space name
- Flat mode: All change requests in chronological order
- Toggle icon updates (grid <-> list)

**Pass Criteria:**
- ✅ Both modes display correctly
- ✅ Toggle works smoothly
- ✅ Data remains consistent

---

## Performance Criteria

### Response Time
- Filter tap response: < 50ms
- Pull-to-refresh dismissal: < 150ms
- Auto-scroll animation: 0.3s (spring)
- Initial load: < 5s (typical network)

### Memory
- No memory leaks
- Memory usage stable after multiple refreshes
- Task cleanup proper (no orphaned tasks)

### Network
- Cancellation works (no unnecessary API calls)
- Concurrent request handling correct
- Error recovery proper

---

## Edge Cases

### 1. No Data
**Scenario:** User has no change requests
**Expected:** "No Change Requests" empty state

### 2. Single Organization
**Scenario:** User has only one organization
**Expected:** Works same as multiple

### 3. All Same Status
**Scenario:** All change requests are "merged"
**Expected:** Other filters show 0, function normally

### 4. Very Long List
**Scenario:** 100+ change requests
**Expected:** Lazy loading, smooth scroll, no performance issues

### 5. Rapid Filter Changes
**Scenario:** User rapidly taps multiple filters
**Expected:** UI remains responsive, displays latest filter correctly

### 6. Network Timeout
**Scenario:** API call times out
**Expected:** Error handled, user can retry

---

## Automated Test Coverage

Based on `AllChangeRequestsViewModelTests.swift`:

### Covered ✅
1. Initial state verification
2. Load success flow
3. Caching mechanism
4. Force refresh
5. Error handling
6. Filter operations
7. Status counts
8. Collection grouping
9. Top-level space grouping
10. Expand/collapse state
11. Display mode toggle
12. Sort order
13. Error clearing

### Manual Testing Required 🔍
1. Pull-to-refresh UI behavior
2. Auto-scroll animation
3. Loading view display timing
4. Rapid user interactions
5. Background task cancellation visual feedback
6. Haptic feedback

---

## Regression Tests

Ensure previous functionality still works:
1. Navigation to change request detail
2. Search functionality (if exists)
3. Settings and preferences
4. Deep linking
5. State restoration

---

## Summary

Total Test Cases: 13 main + 6 edge cases = **19 test scenarios**

Priority Levels:
- **P0 (Critical):** 1, 2, 3, 4, 9
- **P1 (High):** 5, 6, 7, 10, 11
- **P2 (Medium):** 8, 12, 13, Edge cases

Automated: 13 unit tests in `AllChangeRequestsViewModelTests.swift`
Manual: 6 UI/UX tests requiring simulator/device
