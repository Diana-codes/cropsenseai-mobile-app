#!/bin/bash
# Test image prediction endpoint

if [ -z "$1" ]; then
    echo "Usage: ./test_image.sh /path/to/image.jpg"
    echo "Example: ./test_image.sh ~/Downloads/maize_images.jpg"
    exit 1
fi

IMAGE_PATH="$1"

if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Error: Image file not found: $IMAGE_PATH"
    exit 1
fi

echo "🧪 Testing Image Prediction..."
echo "Image: $IMAGE_PATH"
echo ""

response=$(curl -s -X POST http://localhost:8000/predict \
    -F "file=@$IMAGE_PATH")

if echo "$response" | grep -q "prediction"; then
    echo "✅ Prediction successful!"
    echo ""
    echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
else
    echo "❌ Prediction failed"
    echo "$response"
fi
