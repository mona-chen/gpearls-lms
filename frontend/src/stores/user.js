import { defineStore } from 'pinia'
import { createResource } from 'frappe-ui'

export const usersStore = defineStore('lms-users', () => {
	// Get stored token from localStorage
	const getToken = () => {
		return localStorage.getItem('auth_token')
	}

	// Store token in localStorage
	const setToken = (token) => {
		if (token) {
			localStorage.setItem('auth_token', token)
		} else {
			localStorage.removeItem('auth_token')
		}
	}

	// Use FrappeUI createResource for compatibility
	let userResource = createResource({
		url: 'lms.api.get_user_info',
		onError(error) {
			if (error && error.exc_type === 'AuthenticationError') {
				setToken(null)
				window.location.href = '/login'
			}
		},
		auto: true,
		makeParams() {
			return {
				// Add token to headers via fetch options
				headers: {
					'Authorization': `Bearer ${getToken()}`
				}
			}
		}
	})

	const allUsers = createResource({
		url: 'lms.api.get_all_users',
		cache: ['allUsers'],
		makeParams() {
			return {
				headers: {
					'Authorization': `Bearer ${getToken()}`
				}
			}
		}
	})

	// Login method
	const login = async (email, password) => {
		try {
			const response = await fetch('/api/login', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
				},
				body: JSON.stringify({
					usr: email,
					pwd: password
				})
			})

			if (response.ok) {
				const data = await response.json()
				setToken(data.token)
				// Reload user data after successful login
				userResource.reload()
				return data
			} else {
				throw new Error('Login failed')
			}
		} catch (error) {
			console.error('Login error:', error)
			throw error
		}
	}

	// Logout method
	const logout = async () => {
		try {
			await fetch('/api/logout', {
				method: 'POST',
				headers: {
					'Authorization': `Bearer ${getToken()}`
				}
			})
		} catch (error) {
			console.error('Logout error:', error)
		} finally {
			setToken(null)
			window.location.href = '/login'
		}
	}

	return {
		userResource,
		allUsers,
		login,
		logout,
		getToken,
		setToken,
		// Computed property for user data
		user: () => userResource.data?.user || null,
		isLoggedIn: () => !!userResource.data?.user && !!getToken(),
	}
})
