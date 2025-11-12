#!/bin/bash
BASE_URL="http://localhost:3000"
echo "🚀 Testing API Compatibility"
echo "1. Testing login..."
LOGIN=$(curl -s -X POST $BASE_URL/api/method/login -H "Content-Type: application/json" -d '{"email": "test@example.com", "password": "password123"}')
if [[ $LOGIN == *"token"* ]]; then
  echo "✅ Login working"
else
  echo "❌ Login failed"
  exit 1
fi
echo "2. Testing get_user_info..."
TOKEN=$(echo $LOGIN | grep -o '"token":"[^"]*' | cut -d' -f4)
USER_INFO=$(curl -s -X POST $BASE_URL/api/method/lms.api.get_user_info -H "Authorization: Bearer $TOKEN")
[[ $USER_INFO == *"email"* ]] && echo "✅ get_user_info working" || echo "❌ get_user_info failed"
echo "3. Testing get_my_courses..."
COURSES=$(curl -s -X POST $BASE_URL/api/method/lms.utils.get_my_courses -H "Authorization: Bearer $TOKEN")
[[ $COURSES == *"message"* ]] && echo "✅ get_my_courses working" || echo "❌ get_my_courses failed"
echo "4. Testing 404 error handling..."
404=$(curl -s -o /dev/null -w "