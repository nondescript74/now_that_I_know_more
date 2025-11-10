# Recipe Diagnostics Coverage

## Overview
The Recipe Diagnostics tool provides comprehensive health checks for your SwiftData database and file system integrity.

## Current Checks ✅

### Core Data Integrity
1. **Valid UUIDs** - Ensures all recipes have valid, non-empty UUIDs
2. **Duplicate UUIDs** - Detects if multiple recipes share the same UUID
3. **Missing Titles** - Identifies recipes without titles
4. **Spoonacular IDs** - Counts recipes with API IDs (informational)

### Relationship Integrity
5. **Orphaned Media** - Media items that aren't linked to any recipe
6. **Orphaned Notes** - Notes that aren't linked to any recipe
7. **Invalid Featured Media** - Recipes referencing featured media that doesn't exist in their media collection
8. **Empty Recipe Books** - Books with no recipes (informational, not an error)

### File System Integrity
9. **Missing Media Files** - Media records that point to files that don't exist on disk
10. **Invalid Media Paths** - Media items with empty or malformed file paths

### Data Corruption
11. **Corrupted Ingredients Data** - Recipes with JSON data that can't be decoded into ExtendedIngredient arrays
12. **Corrupted Instructions Data** - Recipes with JSON data that can't be decoded into AnalyzedInstruction arrays

### Summary Statistics
- Total Recipes
- Total Recipe Books
- Total Media Items
- Total Notes

### Detailed Recipe View
For each recipe, displays:
- Title
- UUID
- Spoonacular ID (if any)
- Number of books it belongs to
- Number of media items
- Number of notes

## Export Functionality
- Exports all recipes to JSON backup file
- Includes: UUID, title, timestamps, Spoonacular ID, servings, dietary flags

## Console Report
Generates detailed console output with:
- Full summary statistics
- Integrity check results
- Complete recipe listings with all metadata
- Issues list with actionable warnings

## What's NOT Currently Checked

### Potential Future Additions
1. **Recipe Content Validation**
   - Recipes with no ingredients
   - Recipes with no instructions
   - Invalid or missing serving sizes
   - Negative cooking/prep times

2. **Media Quality Checks**
   - Corrupted image files
   - Excessively large media files
   - Duplicate media files (same hash)
   - Media sort order conflicts

3. **Relationship Depth**
   - Books with duplicate recipe references
   - Circular relationship issues
   - Cascade deletion warnings

4. **Performance Metrics**
   - Database size
   - Media storage usage
   - Query performance indicators

5. **Data Quality**
   - Recipes with suspicious data (e.g., 9999 servings)
   - Duplicate recipe content (same title + ingredients)
   - Empty or placeholder summaries

6. **User Content**
   - Note content quality checks
   - Media caption validation

## Usage
Navigate to Settings > Recipe Diagnostics to:
1. View real-time database health
2. Run diagnostics on demand
3. Export recipes for backup
4. View detailed per-recipe information

## Technical Notes
- All SwiftData property access is optimized to prevent memory faulting errors
- Console output uses privacy annotations for OSLog compatibility
- File system checks validate actual file existence
- JSON corruption detection uses safe decoding with error handling
