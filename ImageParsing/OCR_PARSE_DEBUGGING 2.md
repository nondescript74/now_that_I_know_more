# OCR Parse Button - Hanging at Vision Framework

## Current Issue
The parse button stops at "Starting Vision text recognition..." which means the Vision framework's `handler.perform()` is hanging.

## Quick Fix - Try This First! 🔧

The most likely issue is that **the image is too large**. Add this function to resize images before processing:

```swift
// Add to RecipeImageParserView
private func resizeImage(_ image: UIImage, maxDimension: CGFloat = 2000) -> UIImage {
    let size = image.size
    let ratio = min(maxDimension / size.width, maxDimension / size.height)
    
    if ratio >= 1 { return image }
    
    let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
    
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return resizedImage ?? image
}
```

Then in `parseImage()`, change:
```swift
// Before:
parser.parseRecipeImage(image) { result in

// After:
let resizedImage = resizeImage(image)
parser.parseRecipeImage(resizedImage) { result in
```

## Alternative Quick Fixes

### Fix 2: Use Fast Recognition (Trade accuracy for speed)
In `RecipeImageParser.swift` line ~85, change:
```swift
request.recognitionLevel = .fast  // instead of .accurate
```

### Fix 3: Remove Language Restriction
In `RecipeImageParser.swift`, comment out:
```swift
// request.recognitionLanguages = ["en-US"]
```

## What's Happening

The logs show the Vision framework starts but never completes. This typically means:
1. **Image too large** - Vision is processing but taking forever
2. **Image format issue** - Some image formats are problematic
3. **Memory issue** - Not enough memory to process the image

## Testing

After applying Fix 1, you should see these additional logs:
```
🔍 [TableFormatParser] Handler created, about to perform request...
✅ [TableFormatParser] Vision request performed successfully
📊 [TableFormatParser] Got X observations
```

If you still see nothing after "about to perform request...", try Fix 2.

## Added Features

✅ **30-second timeout** - You'll now get an error if it takes too long
✅ **Detailed logging** - See exactly where it hangs  
✅ **Image size logging** - See how big the image is

## More Debugging

Add this to `parseImage()` to see image details:
```swift
print("🖼️ Image: \(image.size.width)x\(image.size.height) @ \(image.scale)x")
```

If the width/height are > 3000, that's likely your problem!
