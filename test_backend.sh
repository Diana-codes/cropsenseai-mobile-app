#!/bin/bash
# Quick test script for backend endpoints

BASE_URL="http://localhost:8000"

echo "🧪 Testing CropSense AI Backend"
echo "================================"
echo ""

# Test 1: Health Check
echo "1️⃣  Testing Health Check..."
response=$(curl -s "$BASE_URL/")
if echo "$response" | grep -q "CropSense AI API is running"; then
    echo "   ✅ Health check passed"
    echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
else
    echo "   ❌ Health check failed"
    echo "$response"
fi
echo ""

# Test 2: Available Crops
echo "2️⃣  Testing Available Crops..."
response=$(curl -s "$BASE_URL/crops")
if echo "$response" | grep -q "crops"; then
    echo "   ✅ Crops endpoint working"
    echo "$response" | python3 -m json.tool 2>/dev/null | head -20 || echo "$response" | head -5
else
    echo "   ❌ Crops endpoint failed"
    echo "$response"
fi
echo ""

# Test 3: Weather Data
echo "3️⃣  Testing Weather Data..."
response=$(curl -s "$BASE_URL/weather?location=Rwanda")
if echo "$response" | grep -q "temperature"; then
    echo "   ✅ Weather endpoint working"
    echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
else
    echo "   ❌ Weather endpoint failed"
    echo "$response"
fi
echo ""

# Test 4: AI Advisor (without image)
echo "4️⃣  Testing AI Advisor..."
response=$(curl -s -X POST "$BASE_URL/advisor" \
    -H "Content-Type: application/json" \
    -d '{
        "province": "Eastern Province",
        "district": "Bugesera",
        "sector": "Gashora",
        "cell": "Biryogo",
        "village": "Akagera",
        "season": "Season A (Sept - Jan)",
        "landType": "Wetland"
    }')
if echo "$response" | grep -q "best_match"; then
    echo "   ✅ AI Advisor endpoint working"
    echo "$response" | python3 -m json.tool 2>/dev/null | head -30 || echo "$response"
else
    echo "   ❌ AI Advisor endpoint failed"
    echo "$response"
fi
echo ""

echo "================================"
echo "✅ Backend testing complete!"
echo ""
echo "💡 To test image prediction, use:"
echo "   curl -X POST $BASE_URL/predict -F \"file=@/path/to/image.jpg\""
echo ""
