<template>
  <div class="min-h-screen bg-gray-50 p-8">
    <div class="max-w-4xl mx-auto">
      <h1 class="text-3xl font-bold text-gray-900 mb-8">LMS Rails Integration Test</h1>
      
      <div class="bg-white rounded-lg shadow p-6 mb-6">
        <h2 class="text-xl font-semibold mb-4">API Test Results</h2>
        <div v-if="loading" class="text-gray-600">Loading...</div>
        <div v-else-if="error" class="text-red-600">Error: {{ error }}</div>
        <div v-else>
          <div class="mb-4">
            <h3 class="font-semibold mb-2">Courses API Test:</h3>
            <p class="text-green-600" v-if="coursesTest">✅ Connected to Rails API successfully</p>
            <p class="text-red-600" v-else>❌ Failed to connect</p>
          </div>
          
          <div class="mt-4">
            <h3 class="font-semibold mb-2">Sample Courses:</h3>
            <div v-if="courses.length > 0">
              <div v-for="course in courses.slice(0, 3)" :key="course.id" class="border p-3 rounded mb-2">
                <h4 class="font-medium">{{ course.title }}</h4>
                <p class="text-sm text-gray-600">{{ course.description }}</p>
              </div>
            </div>
            <p v-else class="text-gray-500">No courses found</p>
          </div>
        </div>
      </div>
      
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-xl font-semibold mb-4">Next Steps</h2>
        <ul class="list-disc list-inside space-y-2 text-gray-700">
          <li>✅ Rails API backend running on localhost:3000</li>
          <li>✅ Vue frontend running on localhost:5173</li>
          <li>✅ API proxy configuration working</li>
          <li>🔄 Remove FrappeUI dependencies from existing components</li>
          <li>🔄 Replace with vanilla Vue components and Rails API calls</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  name: 'TestPage',
  data() {
    return {
      loading: true,
      error: null,
      courses: [],
      coursesTest: false
    }
  },
  async mounted() {
    await this.testAPI()
  },
  methods: {
    async testAPI() {
      try {
        const api = axios.create({
          baseURL: '/api',
          withCredentials: true,
          headers: {
            'Content-Type': 'application/json'
          }
        })
        
        const response = await api.get('/courses')
        this.courses = response.data || []
        this.coursesTest = true
        console.log('API Test Success:', this.courses)
      } catch (error) {
        this.error = error.message
        console.error('API Test Failed:', error)
      } finally {
        this.loading = false
      }
    }
  }
}
</script>