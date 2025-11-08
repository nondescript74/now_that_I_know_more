# Bug Fix: Can't Select Items After Creating Groups

## Problem

User reported: "can't select more items to create ingredient groups after 2 or 3"

## Root Cause

The issue was in the `mergeRecognizedItems` function. When a user dragged one text line onto another to merge them:

1. The two lines were combined into one
2. One item was removed from the `recognizedItems` array
3. **ALL ingredient and instruction groups were completely cleared**
4. This meant that after a user created 2-3 ingredient groups, if they used drag-to-merge at any point, all their groups would be lost

The original code:
```swift
private func mergeRecognizedItems(source: Int, destination: Int) {
    // ... merge logic ...
    recognizedItems = newItems
    // For safety, clear all selection/grouping states
    selectedTitleIndicesState.removeAll()  // ❌ Too aggressive
    ingredientGroups.removeAll()            // ❌ Loses user's work!
    instructionGroups.removeAll()           // ❌ Loses user's work!
    // ...
}
```

## Solution

Instead of clearing all selections and groups, we now **update the indices** to account for the merged/removed item:

1. The item that was removed (`removeFirst`) is removed from all groups
2. Any index greater than `removeFirst` is decremented by 1 (shifted down)
3. Any index less than `removeFirst` stays the same

This preserves all the user's work while correctly handling the index changes.

### New Implementation

```swift
private func mergeRecognizedItems(source: Int, destination: Int) {
    // ... merge logic ...
    
    // Update indices in all selections and groups
    func updateIndices(_ indices: Set<Int>) -> Set<Int> {
        var updated = Set<Int>()
        for idx in indices {
            if idx == removeFirst {
                continue  // Merged away
            } else if idx > removeFirst {
                updated.insert(idx - 1)  // Shift down
            } else {
                updated.insert(idx)  // Keep as is
            }
        }
        return updated
    }
    
    // Apply updates to all selections and groups
    selectedTitleIndicesState = updateIndices(selectedTitleIndicesState)
    ingredientGroups = ingredientGroups.map { updateIndexArray($0) }.filter { !$0.isEmpty }
    // ...
}
```

## Example

Before merge:
```
Items: ["Title", "Salt", "Pepper", "Sugar", "Mix", "Bake"]
         0        1       2         3        4       5

Ingredient Groups: [[1, 2, 3], [4]]  (Salt, Pepper, Sugar) and (Mix)
```

User drags item 0 ("Title") onto item 1 ("Salt"):
```
Merged item at index 0: "Title Salt"
Removed item at index 1
```

After merge (OLD buggy behavior):
```
Items: ["Title Salt", "Pepper", "Sugar", "Mix", "Bake"]
         0             1         2        3       4

Ingredient Groups: []  ❌ ALL GROUPS LOST!
```

After merge (NEW correct behavior):
```
Items: ["Title Salt", "Pepper", "Sugar", "Mix", "Bake"]
         0             1         2        3       4

Ingredient Groups: [[1, 2], [3]]  ✅ Groups preserved!
Original [1, 2, 3] became [1, 2] (1 was removed, 2 became 1, 3 became 2)
Original [4] became [3] (4 became 3)
```

## Additional Fix

Also fixed a minor issue where `selectedIngredientIndices` and `selectedInstructionIndices` weren't being excluded when calculating available items for those sections. While these sets were empty in practice, this ensures the logic is completely correct:

```swift
// Old:
let usedInIngredients = Set(groupingIngredient).union(alreadyGrouped)

// New:
let usedInIngredients = Set(groupingIngredient).union(alreadyGrouped).union(selectedIngredientIndices)
```

## Testing Checklist

To verify the fix works:

- [ ] Create 2-3 ingredient groups
- [ ] Try to select more items for a 4th group
- [ ] Should work! ✓
- [ ] Use drag-to-merge on any items
- [ ] Verify all ingredient groups are still present ✓
- [ ] Verify indices are correct (items match their groups) ✓
- [ ] Create instruction groups and test same behavior ✓

## Impact

- **Before**: Users would lose all their work if they used drag-to-merge after creating groups
- **After**: Drag-to-merge intelligently updates indices, preserving all groups
- **Bonus**: Title and summary selections also preserved during merge

## Files Modified

1. **ImageToListView.swift**
   - Completely rewrote `mergeRecognizedItems` function
   - Added index update logic
   - Added helper functions for updating Set<Int> and [Int]
   - Filter out empty groups after update

2. **RecipePartsSection.swift**
   - Added `selectedIngredientIndices` and `selectedInstructionIndices` to exclusion calculation
   - Minor correctness improvement

## Related Improvements

This fix builds on the earlier filtering improvement where items selected for one section are hidden from other sections. Combined, these changes create a much more robust user experience:

1. Items don't accidentally get reused across sections (filtering)
2. Work doesn't get lost when merging items (this fix)
3. Drag-to-merge works correctly with all selections and groups (this fix)
