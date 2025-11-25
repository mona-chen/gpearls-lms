# LMS API Documentation

## Overview
This document provides comprehensive API documentation for the Learning Management System (LMS) built with Rails, designed to be compatible with Frappe LMS frontend applications.

## Authentication

### JWT Token Authentication
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password"
}
```

Response:
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "LMS Student"
  }
}
```

### Session Authentication
```http
GET /api/auth/session
Cookie: user_id=user@example.com
```

## Courses API

### List Courses
```http
GET /api/courses?page=1&per_page=20&enrolled=true&certification=true&title=search_term
Authorization: Bearer {token}
```

Response:
```json
{
  "data": [
    {
      "name": "1",
      "title": "Introduction to Programming",
      "description": "Learn the basics of programming",
      "tags": ["programming", "beginner"],
      "image": "/uploads/course_image.jpg",
      "published": true,
      "upcoming": false,
      "featured": true,
      "category": "Technology",
      "course_price": 99.99,
      "currency": "USD",
      "lessons": 12,
      "enrollments": 150,
      "rating": 4.5,
      "instructor": "Jane Smith",
      "instructor_id": 2
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20
  }
}
```

### Get Course Details
```http
GET /api/courses/{course_id}
Authorization: Bearer {token}
```

Response:
```json
{
  "name": "1",
  "title": "Introduction to Programming",
  "description": "Learn the basics of programming",
  "short_introduction": "A comprehensive introduction...",
  "video_link": "https://youtube.com/watch?v=...",
  "tags": ["programming", "beginner"],
  "image": "/uploads/course_image.jpg",
  "published": true,
  "upcoming": false,
  "featured": true,
  "category": "Technology",
  "course_price": 99.99,
  "currency": "USD",
  "enable_certification": true,
  "certificate_template": "default",
  "paid_certificate": false,
  "evaluator_id": null,
  "timezone": "UTC",
  "card_gradient": "blue",
  "disable_self_learning": false,
  "published_on": "2024-01-15T10:00:00Z",
  "creation": "2024-01-01T00:00:00Z",
  "modified": "2024-01-15T10:00:00Z",
  "owner": "instructor@example.com",
  "instructor": "Jane Smith",
  "instructor_id": 2,
  "chapters": [
    {
      "name": "1",
      "title": "Getting Started",
      "description": "Introduction to the course",
      "is_scorm_package": false,
      "lessons": [
        {
          "name": "1",
          "title": "Welcome",
          "content": "Welcome to the course...",
          "is_scorm_package": false
        }
      ]
    }
  ]
}
```

### Create Course
```http
POST /api/courses
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "New Course",
  "description": "Course description",
  "short_introduction": "Brief intro",
  "price": 49.99,
  "currency": "USD",
  "category": "Technology",
  "enable_certification": true,
  "published": false
}
```

### Update Course
```http
PUT /api/courses/{course_id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "Updated Course Title",
  "published": true
}
```

### Delete Course
```http
DELETE /api/courses/{course_id}
Authorization: Bearer {token}
```

## Enrollment API

### Enroll in Course
```http
POST /api/courses/{course_id}/enroll
Authorization: Bearer {token}
```

Response:
```json
{
  "success": true,
  "enrollment": {
    "id": 123,
    "user_id": 1,
    "course_id": 1,
    "progress": 0,
    "completed": false,
    "enrolled_at": "2024-01-15T10:00:00Z"
  }
}
```

### Get Enrollment Progress
```http
GET /api/courses/{course_id}/progress
Authorization: Bearer {token}
```

Response:
```json
{
  "enrollment_id": 123,
  "course_id": 1,
  "progress": 65.5,
  "completed": false,
  "completed_lessons": 8,
  "total_lessons": 12,
  "last_accessed_at": "2024-01-15T10:00:00Z",
  "lesson_progress": [
    {
      "lesson_id": 1,
      "completed": true,
      "completion_date": "2024-01-10T10:00:00Z"
    }
  ]
}
```

### Update Lesson Progress
```http
POST /api/courses/{course_id}/lessons/{lesson_id}/progress
Authorization: Bearer {token}
Content-Type: application/json

{
  "completed": true,
  "time_spent": 1800
}
```

## Quiz API

### Get Quiz
```http
GET /api/quizzes/{quiz_id}
Authorization: Bearer {token}
```

Response:
```json
{
  "name": "1",
  "title": "Programming Basics Quiz",
  "description": "Test your knowledge",
  "passing_score": 70,
  "time_limit": 30,
  "max_attempts": 3,
  "show_answers": false,
  "randomize_questions": true,
  "questions": [
    {
      "id": 1,
      "question": "What is a variable?",
      "question_type": "multiple_choice",
      "options": [
        "A storage location",
        "A function",
        "A loop",
        "A class"
      ],
      "correct_answer": "A storage location",
      "explanation": "Variables store data values"
    }
  ]
}
```

### Submit Quiz
```http
POST /api/quizzes/{quiz_id}/submit
Authorization: Bearer {token}
Content-Type: application/json

{
  "answers": {
    "1": "A storage location",
    "2": "function"
  },
  "time_taken": 1200
}
```

Response:
```json
{
  "success": true,
  "submission": {
    "id": 456,
    "quiz_id": 1,
    "user_id": 1,
    "score": 85,
    "passed": true,
    "time_taken": 1200,
    "submitted_at": "2024-01-15T10:00:00Z",
    "answers": {
      "1": {
        "answer": "A storage location",
        "correct": true,
        "points": 10
      }
    }
  }
}
```

## Assignment API

### Get Assignments
```http
GET /api/courses/{course_id}/assignments
Authorization: Bearer {token}
```

Response:
```json
{
  "data": [
    {
      "name": "1",
      "title": "Build a Calculator",
      "description": "Create a simple calculator application",
      "due_date": "2024-02-01T23:59:59Z",
      "max_marks": 100,
      "instructions": "Submit a working calculator...",
      "file_required": true,
      "allow_late_submission": false,
      "status": "published"
    }
  ]
}
```

### Submit Assignment
```http
POST /api/assignments/{assignment_id}/submit
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "submission_text": "My solution...",
  "files": [file_upload]
}
```

## Certificate API

### Request Certificate
```http
POST /api/certificates/request
Authorization: Bearer {token}
Content-Type: application/json

{
  "course_id": 1,
  "request_type": "Completion",
  "notes": "Please issue my certificate"
}
```

### Get Certificate
```http
GET /api/certificates/{certificate_id}
Authorization: Bearer {token}
```

Response:
```json
{
  "name": "1",
  "user_id": 1,
  "course_id": 1,
  "issue_date": "2024-01-15",
  "expiry_date": "2025-01-15",
  "status": "Approved",
  "template": "default",
  "download_url": "/api/certificates/1/download",
  "share_url": "/certificates/share/abc123"
}
```

## Payment API

### Initialize Payment
```http
POST /api/payments/initialize
Authorization: Bearer {token}
Content-Type: application/json

{
  "payment": {
    "item_type": "course",
    "item_id": 1,
    "amount": 99.99,
    "currency": "USD",
    "payment_method": "stripe"
  }
}
```

Response:
```json
{
  "success": true,
  "payment": {
    "id": 789,
    "amount": 99.99,
    "currency": "USD",
    "status": "pending",
    "payment_url": "https://checkout.stripe.com/...",
    "reference": "PAY_123456"
  }
}
```

### Verify Payment
```http
POST /api/payments/{payment_id}/verify
Authorization: Bearer {token}
Content-Type: application/json

{
  "reference": "PAY_123456"
}
```

## SCORM API

### Upload SCORM Package
```http
POST /api/scorm/upload
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "lesson_id": 1,
  "file": [scorm_zip_file]
}
```

Response:
```json
{
  "success": true,
  "package": {
    "id": 101,
    "title": "SCORM Module",
    "status": "extracted",
    "launch_url": "/scorm/101/launch",
    "manifest": { ... }
  }
}
```

### Launch SCORM Content
```http
GET /api/scorm/{package_id}/launch
Authorization: Bearer {token}
```

### Track SCORM Progress
```http
POST /api/scorm/{package_id}/track
Authorization: Bearer {token}
Content-Type: application/json

{
  "scorm_data": {
    "cmi.core.lesson_status": "completed",
    "cmi.core.score.raw": "85",
    "cmi.core.total_time": "00:30:00"
  }
}
```

## Live Classes API

### Create Live Class
```http
POST /api/live_classes
Authorization: Bearer {token}
Content-Type: application/json

{
  "batch_id": 1,
  "title": "Live Session 1",
  "description": "Interactive session",
  "start_time": "2024-01-20T15:00:00Z",
  "duration": 60,
  "timezone": "UTC",
  "zoom_account": "zoom_account_1"
}
```

Response:
```json
{
  "success": true,
  "live_class": {
    "id": 202,
    "title": "Live Session 1",
    "start_time": "2024-01-20T15:00:00Z",
    "join_url": "https://zoom.us/j/123456789",
    "start_url": "https://zoom.us/s/123456789/start",
    "meeting_id": "123456789",
    "password": "abc123"
  }
}
```

## Programming Exercises API

### Execute Code
```http
POST /api/exercises/{exercise_id}/execute
Authorization: Bearer {token}
Content-Type: application/json

{
  "code": "print('Hello World')",
  "language": "python",
  "test_cases": [
    {
      "input": "",
      "expected_output": "Hello World"
    }
  ]
}
```

Response:
```json
{
  "success": true,
  "execution": {
    "passed": true,
    "total_tests": 1,
    "passed_tests": 1,
    "results": [
      {
        "input": "",
        "expected": "Hello World",
        "actual": "Hello World",
        "passed": true,
        "execution_time": 0.05
      }
    ],
    "feedback": "Excellent! All test cases passed."
  }
}
```

## Batch API

### List Batches
```http
GET /api/batches?page=1&per_page=20&status=active&my_batches=true&search=term
Authorization: Bearer {token}
```

### Create Batch
```http
POST /api/batches
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "Spring 2024 Batch",
  "description": "New batch for spring semester",
  "course_id": 1,
  "instructor_id": 2,
  "start_date": "2024-03-01",
  "end_date": "2024-05-31",
  "max_students": 50,
  "price": 299.99,
  "currency": "USD",
  "category": "Technology",
  "published": true
}
```

## User API

### Get User Profile
```http
GET /api/users/profile
Authorization: Bearer {token}
```

Response:
```json
{
  "name": "1",
  "email": "user@example.com",
  "full_name": "John Doe",
  "username": "johndoe",
  "profile_image": "/uploads/profile.jpg",
  "role": "LMS Student",
  "country": "US",
  "timezone": "America/New_York",
  "bio": "Software developer",
  "education_details": [
    {
      "degree": "BS Computer Science",
      "institution": "University of Tech",
      "year": 2020
    }
  ],
  "work_experience": [
    {
      "title": "Software Engineer",
      "company": "Tech Corp",
      "start_date": "2020-01-01",
      "end_date": null
    }
  ],
  "skills": ["Ruby", "JavaScript", "Python"]
}
```

## Analytics API

### Course Analytics
```http
GET /api/analytics/courses/{course_id}?date_range=30d&timeframe=week
Authorization: Bearer {token}
```

Response:
```json
{
  "enrollments": {
    "total": 150,
    "this_month": 25,
    "trend": [10, 15, 20, 25]
  },
  "completion": {
    "rate": 68.5,
    "completed": 103,
    "in_progress": 32,
    "not_started": 15
  },
  "engagement": {
    "avg_session_time": 45.5,
    "total_views": 2500,
    "unique_visitors": 180
  },
  "ratings": {
    "average": 4.3,
    "distribution": {
      "5": 50,
      "4": 30,
      "3": 15,
      "2": 3,
      "1": 2
    }
  }
}
```

## Compatibility API

The LMS provides Frappe-compatible API endpoints for seamless frontend integration:

### Frappe-style Method Calls
```http
POST /api/method
Content-Type: application/json

{
  "method": "lms.utils.get_courses",
  "filters": {
    "category": "Technology",
    "published": 1
  }
}
```

### Supported Frappe Methods
- `lms.utils.get_courses` - List courses
- `lms.utils.get_course_details` - Get course details
- `lms.api.get_user_info` - Get user information
- `lms.utils.enroll_in_course` - Enroll in course
- `lms.utils.get_course_progress` - Get progress
- `frappe.client.get_single_value` - Get settings
- And many more...

## Error Handling

All API endpoints return consistent error responses:

```json
{
  "error": "Error message description",
  "status": 400
}
```

### Common HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Unprocessable Entity
- `500` - Internal Server Error

## Rate Limiting

API endpoints are rate limited to prevent abuse:
- General endpoints: 1000 requests per hour
- Authentication endpoints: 10 requests per minute
- File upload endpoints: 50 requests per hour

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Webhooks

The LMS supports webhooks for real-time notifications:

### Payment Webhooks
```http
POST /api/webhooks/payments
X-Signature: signature_from_gateway

{
  "event": "payment.completed",
  "payment_id": "123",
  "amount": 99.99,
  "currency": "USD"
}
```

### Enrollment Webhooks
```http
POST /api/webhooks/enrollments

{
  "event": "enrollment.created",
  "user_id": 1,
  "course_id": 1,
  "enrollment_id": 123
}
```

## File Upload

### Upload Course Files
```http
POST /api/files/upload
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "file": [uploaded_file],
  "doctype": "Course",
  "docname": "1",
  "fieldname": "image"
}
```

Response:
```json
{
  "success": true,
  "file_url": "/uploads/courses/1/image.jpg",
  "file_name": "image.jpg",
  "file_size": 1024000
}
```

## Pagination

All list endpoints support pagination:

```http
GET /api/courses?page=2&per_page=50
```

Response includes pagination metadata:
```json
{
  "data": [...],
  "pagination": {
    "current_page": 2,
    "total_pages": 10,
    "total_count": 500,
    "per_page": 50,
    "next_page": 3,
    "prev_page": 1
  }
}
```

## Filtering and Sorting

Most list endpoints support filtering and sorting:

```http
GET /api/courses?category=Technology&published=true&sort=created_at&order=desc
```

## Versioning

API versioning is handled through URL paths:
- Current version: `/api/v1/`
- Legacy support: `/api/` (defaults to v1)

## SDKs and Libraries

### JavaScript SDK
```javascript
import { LMSClient } from '@lms/sdk';

const client = new LMSClient({
  baseURL: 'https://your-lms.com/api',
  token: 'your-jwt-token'
});

// Get courses
const courses = await client.courses.list({
  category: 'Technology',
  published: true
});

// Enroll in course
await client.courses.enroll(123);
```

### Python SDK
```python
from lms_sdk import LMSClient

client = LMSClient(
    base_url='https://your-lms.com/api',
    token='your-jwt-token'
)

# Get user profile
user = client.users.get_profile()

# Submit quiz
result = client.quizzes.submit(456, {
    'answers': {'1': 'A', '2': 'B'}
})
```

## Support and Documentation

For additional support:
- API Reference: `/api/docs`
- Status Page: `/api/status`
- Health Check: `/api/health`

## Changelog

### v1.0.0 (Current)
- Complete LMS API implementation
- Frappe compatibility layer
- SCORM support
- Payment gateway integration
- Live class management
- Programming exercise execution
- Comprehensive analytics

This documentation covers the complete LMS API surface. All endpoints are fully tested and production-ready.