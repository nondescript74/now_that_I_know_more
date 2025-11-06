#!/usr/bin/env python3
"""
Chinese Character Stroke Data Fetcher
Retrieves stroke order data for 100 basic Chinese characters commonly taught to children.

This version includes sample data and multiple data source options.
Run this on your local machine with internet access for full functionality.
"""

import json
import time
import requests
from typing import Dict, List, Optional

# 100 most common characters for children learning Chinese
BASIC_CHARACTERS = [
    # Numbers 1-10
    '一', '二', '三', '四', '五', '六', '七', '八', '九', '十',
    # Common characters (family, daily life, nature)
    '人', '口', '手', '日', '月', '水', '火', '木', '金', '土',
    '大', '小', '中', '上', '下', '左', '右', '天', '地', '山',
    '田', '石', '目', '耳', '心', '门', '女', '子', '马', '牛',
    '羊', '鸟', '鱼', '米', '竹', '丝', '虫', '贝', '见', '车',
    '风', '云', '雨', '雪', '电', '刀', '力', '又', '文', '方',
    # Common verbs and adjectives
    '不', '也', '了', '在', '有', '我', '你', '他', '她', '好',
    '来', '去', '出', '入', '本', '白', '红', '长', '多', '少',
    '高', '开', '生', '学', '工', '用', '走', '飞', '吃', '喝',
    '看', '听', '说', '读', '写', '坐', '站', '爱', '笑', '哭'
]

# Sample data structure (for the character 一 - "one")
SAMPLE_DATA = {
    "一": {
        "character": "一",
        "unicode": "4e00",
        "stroke_count": 1,
        "strokes": ["M 150 500 L 850 500"],
        "medians": [[[150, 500], [850, 500]]],
        "radical": "一"
    },
    "人": {
        "character": "人",
        "unicode": "4eba",
        "stroke_count": 2,
        "strokes": [
            "M 325 750 L 500 50",
            "M 675 750 L 500 50"
        ],
        "medians": [
            [[325, 750], [500, 50]],
            [[675, 750], [500, 50]]
        ],
        "radical": "人"
    }
}


def fetch_from_hanziwriter(character: str) -> Optional[Dict]:
    """
    Fetch from HanziWriter CDN (recommended - most reliable).
    Data source: https://github.com/chanind/hanzi-writer-data
    """
    try:
        unicode_hex = format(ord(character), 'x')
        url = f"https://cdn.jsdelivr.net/npm/hanzi-writer-data@2.0/{unicode_hex}.json"
        
        response = requests.get(url, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            return {
                'character': character,
                'unicode': unicode_hex,
                'stroke_count': len(data.get('strokes', [])),
                'strokes': data.get('strokes', []),
                'medians': data.get('medians', []),
                'radical': data.get('radical', ''),
            }
        return None
    except Exception as e:
        print(f"  Error: {str(e)}")
        return None


def fetch_from_makemeahanzi(character: str) -> Optional[Dict]:
    """
    Alternative: Fetch from Make Me a Hanzi (requires downloading the full dataset).
    Data source: https://github.com/skishore/makemeahanzi
    
    For this approach, download graphics.txt from the repo and parse it locally.
    """
    # This would require local file parsing
    # Included here as reference for alternative data source
    pass


def create_sample_dataset() -> List[Dict]:
    """
    Creates a small sample dataset for demonstration purposes.
    Use this if you can't access external APIs.
    """
    print("Creating sample dataset with embedded data...")
    return [SAMPLE_DATA[char] for char in SAMPLE_DATA.keys()]


def fetch_all_characters(characters: List[str], delay: float = 0.2, 
                         use_sample: bool = False) -> List[Dict]:
    """
    Fetch stroke data for all characters in the list.
    """
    if use_sample:
        return create_sample_dataset()
    
    results = []
    total = len(characters)
    
    print(f"Fetching stroke data for {total} characters...")
    print("=" * 60)
    
    for i, char in enumerate(characters, 1):
        print(f"[{i}/{total}] Fetching {char}...", end='')
        
        data = fetch_from_hanziwriter(char)
        
        if data:
            results.append(data)
            print(f" ✓ ({data['stroke_count']} strokes)")
        else:
            print(f" ✗ Failed")
        
        # Be respectful to the API
        if i < total:
            time.sleep(delay)
    
    print("=" * 60)
    print(f"Successfully fetched {len(results)} out of {total} characters")
    
    return results


def save_to_json(data: List[Dict], filename: str = "chinese_stroke_data.json"):
    """Save the collected data to a JSON file."""
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"\n✓ Data saved to {filename}")
        return True
    except Exception as e:
        print(f"\n✗ Error saving file: {str(e)}")
        return False


def create_swift_compatible_format(data: List[Dict], 
                                   filename: str = "stroke_data_swift.json"):
    """
    Create a Swift-friendly JSON format optimized for iOS apps.
    """
    swift_data = {
        "version": "1.0",
        "character_count": len(data),
        "characters": {}
    }
    
    for item in data:
        char = item['character']
        swift_data["characters"][char] = {
            "unicode": item['unicode'],
            "strokeCount": item['stroke_count'],
            "strokes": item['strokes'],
            "medians": item['medians'],
            "radical": item.get('radical', '')
        }
    
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(swift_data, f, ensure_ascii=False, indent=2)
        print(f"✓ Swift-compatible data saved to {filename}")
        return True
    except Exception as e:
        print(f"✗ Error saving Swift format: {str(e)}")
        return False


def create_summary_report(data: List[Dict]):
    """Create a summary report of the collected data."""
    if not data:
        print("\nNo data to summarize.")
        return
    
    total_chars = len(data)
    stroke_counts = [item['stroke_count'] for item in data]
    avg_strokes = sum(stroke_counts) / len(stroke_counts)
    min_strokes = min(stroke_counts)
    max_strokes = max(stroke_counts)
    
    print("\n" + "=" * 60)
    print("SUMMARY REPORT")
    print("=" * 60)
    print(f"Total characters collected: {total_chars}")
    print(f"Average stroke count: {avg_strokes:.1f}")
    print(f"Minimum strokes: {min_strokes}")
    print(f"Maximum strokes: {max_strokes}")
    print(f"\nCharacters by stroke count:")
    
    # Group by stroke count
    stroke_groups = {}
    for item in data:
        count = item['stroke_count']
        if count not in stroke_groups:
            stroke_groups[count] = []
        stroke_groups[count].append(item['character'])
    
    for count in sorted(stroke_groups.keys()):
        chars = ''.join(stroke_groups[count])
        print(f"  {count:2d} strokes: {chars} ({len(stroke_groups[count])} chars)")
    
    print("=" * 60)


def create_usage_instructions():
    """Print instructions for using the data in SwiftUI."""
    print("\n" + "=" * 60)
    print("USING THIS DATA IN YOUR iOS APP")
    print("=" * 60)
    print("""
1. Add the JSON file to your Xcode project
2. Parse the stroke data in Swift:

struct StrokeData: Codable {
    let character: String
    let unicode: String
    let strokeCount: Int
    let strokes: [String]
    let medians: [[[Double]]]
    let radical: String
    
    enum CodingKeys: String, CodingKey {
        case character, unicode, radical
        case strokeCount = "stroke_count"
        case strokes, medians
    }
}

3. Load the data:

func loadStrokeData() -> [StrokeData] {
    guard let url = Bundle.main.url(forResource: "chinese_stroke_data", 
                                     withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let strokes = try? JSONDecoder().decode([StrokeData].self, 
                                                   from: data)
    else { return [] }
    return strokes
}

4. Render strokes using SwiftUI Path:
   - The 'strokes' array contains SVG path commands
   - The 'medians' array provides simplified stroke paths for animation
   - Use Path drawing to create interactive stroke practice

5. For stroke animation:
   - Use the median points to create smooth animations
   - Implement drag gesture recognition for user practice
   - Compare user strokes with the median path

Recommended library: HanziWriter (JavaScript) has iOS ports
or implement custom rendering using the SVG path data.
""")
    print("=" * 60)


def main():
    """Main function to run the stroke data fetcher."""
    print("\n🖌️  Chinese Character Stroke Data Fetcher")
    print("Collecting data for 100 basic characters for children\n")
    
    import sys
    use_sample = '--sample' in sys.argv
    
    if use_sample:
        print("Using embedded sample data (--sample flag detected)\n")
        stroke_data = fetch_all_characters(BASIC_CHARACTERS, use_sample=True)
    else:
        print("Attempting to fetch from HanziWriter CDN...")
        print("(Use --sample flag to use embedded sample data)\n")
        stroke_data = fetch_all_characters(BASIC_CHARACTERS, delay=0.2)
    
    if stroke_data:
        # Save standard format
        save_to_json(stroke_data, "/mnt/user-data/outputs/chinese_stroke_data.json")
        
        # Save Swift-compatible format
        create_swift_compatible_format(stroke_data, 
                                       "/mnt/user-data/outputs/stroke_data_swift.json")
        
        # Create report
        create_summary_report(stroke_data)
        
        # Show sample
        print("\n📝 Sample data structure:")
        if len(stroke_data) > 0:
            sample = stroke_data[0]
            print(json.dumps({
                'character': sample['character'],
                'unicode': sample['unicode'],
                'stroke_count': sample['stroke_count'],
                'strokes': sample['strokes'][:2] if len(sample['strokes']) > 2 
                          else sample['strokes'],
                'medians': sample['medians'][:2] if len(sample['medians']) > 2 
                          else sample['medians'],
            }, ensure_ascii=False, indent=2))
        
        create_usage_instructions()
        
        print("\n✅ Done! Files saved to /mnt/user-data/outputs/")
    else:
        print("\n⚠ No data was collected.")
        print("To run this script successfully:")
        print("1. Run it on your local machine with internet access")
        print("2. Or use the --sample flag to generate sample data")
        print("\nExample: python3 chinese_stroke_fetcher.py --sample")


if __name__ == "__main__":
    main()
