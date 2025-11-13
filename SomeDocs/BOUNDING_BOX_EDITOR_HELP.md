# Recipe OCR Bounding Box Editor - User Guide

## Overview
The Bounding Box Editor allows you to manually define regions in a recipe image for more accurate OCR parsing. This is especially useful for complex layouts, handwritten recipes, or images where automatic parsing struggles.

## How to Access
1. Open the Recipe Parser
2. Select or capture a recipe image
3. Tap **"Define Regions (Advanced)"**

## Key Features

### 🔍 Zoom Controls
- **Pinch to Zoom**: Use two fingers to pinch in/out on the image (1x to 5x)
- **Zoom Slider**: Use the slider at the bottom of the screen to adjust zoom level (100% - 500%)
- **Current Zoom**: Shows your current zoom percentage on screen

### 🗺️ Mini-Map
- **Location**: Top-right corner of the screen
- **Purpose**: Shows thumbnail of entire image with all defined regions
- **Toggle**: Tap the map icon in zoom controls to show/hide
- **Helps**: Navigate when zoomed in on large images

### ✏️ Drawing Regions
1. Tap **"Draw Region"** button
2. Select region type from the toolbar:
   - **Title**: Recipe name
   - **Servings**: Number of servings
   - **Ingredients**: Ingredient list
   - **Instructions**: Cooking steps
   - **Notes**: Additional information
   - **Ignore**: Areas to exclude from parsing
3. Drag on the image to draw a box around the region
4. Repeat for all recipe sections

### 📝 Ingredient Grouping
When you create an **Ingredients** region:
- The app automatically opens a grouping interface
- Tap words in order to select them
- Tap **"Create Group"** to form a complete ingredient line
- Each group becomes one ingredient in the parsed recipe
- Tap **"Done"** when finished grouping

### 👁️ Text Overlay
- Toggle to show/hide detected text boundaries (cyan boxes)
- Helps you see what the OCR engine detected
- Useful for aligning your regions with detected text

### ↩️ Undo
- Removes the most recently drawn region
- Only available when you have drawn at least one region

## Tips for Best Results

1. **Zoom In**: Increase zoom level (2x-3x) for precise boundary drawing
2. **Use Text Overlay**: Turn on text overlay to see exactly what was detected
3. **Draw Tight Boxes**: Draw boxes as close to text as possible
4. **Group Ingredients**: Take time to properly group ingredient words
5. **Check Mini-Map**: Use the mini-map to verify you haven't missed any regions

## Workflow Example

1. Start with 2x zoom (default)
2. Turn on text overlay to see detected text
3. Draw a Title region around recipe name
4. Draw a Servings region if present
5. Draw an Ingredients region around ingredient list
   - Group words into complete ingredient lines
6. Draw an Instructions region around cooking steps
7. Add Notes region for any additional info
8. Mark any unwanted areas as Ignore
9. Use mini-map to verify all regions are captured
10. Tap **"Done"** to parse with your defined regions

## Troubleshooting

**Drawing isn't working?**
- Make sure you tapped "Draw Region" first
- Ensure you selected a region type from the toolbar

**Can't see text well?**
- Increase zoom level with pinch or slider
- Use mini-map to navigate to the right area

**Ingredient grouping seems wrong?**
- Tap the ingredient region again to edit grouping
- Delete incorrect groups and recreate them
- Words are automatically sorted by position

**Regions appear in wrong place?**
- The editor uses Vision framework coordinates
- Try redrawing the region while zoomed in for accuracy

## Keyboard Shortcuts (iPad)
- **Space**: Toggle between draw and select mode
- **Cmd + Z**: Undo last region
- **Escape**: Cancel current drawing

---

*Last Updated: November 12, 2025*
