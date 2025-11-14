#!/bin/bash

# Check for unused assets in Flutter project

echo "Checking for unused assets..."

# Step 1: Extract all asset paths referenced in Dart files
REFERENCED_ASSETS=$(grep -r "AssetImage\|Image.asset\|SvgPicture.asset\|rootBundle.load" lib/ --include="*.dart" | 
    grep -o "'[^']*'" | 
    sed "s/'//g" | 
    sort | 
    uniq)

# Step 2: List all assets present in the assets directory
ACTUAL_ASSETS=$(find assets/ -type f -not -name ".DS_Store" | 
    sed "s/^assets\///" | 
    sort | 
    uniq)

# Step 3: Compare the two lists to find unused assets
echo -e "\nUnused assets:"
comm -23 <(echo "$ACTUAL_ASSETS") <(echo "$REFERENCED_ASSETS")

# Step 4: Count and summarize
REFERENCED_COUNT=$(echo "$REFERENCED_ASSETS" | wc -l)
ACTUAL_COUNT=$(echo "$ACTUAL_ASSETS" | wc -l)
UNUSED_COUNT=$(comm -23 <(echo "$ACTUAL_ASSETS") <(echo "$REFERENCED_ASSETS") | wc -l)

echo -e "\nSummary:"
echo "Total referenced assets: $REFERENCED_COUNT"
echo "Total actual assets: $ACTUAL_COUNT"
echo "Total unused assets: $UNUSED_COUNT"