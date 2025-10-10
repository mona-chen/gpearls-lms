// Action Cable WebSocket client for Rails backend
import { createConsumer } from '@rails/actioncable'

export function initSocket() {
	// Get the authentication token from localStorage
	const getToken = () => {
		return localStorage.getItem('auth_token')
	}

	// Create Action Cable consumer with authentication
	const consumer = createConsumer(`ws://localhost:3001/cable?token=${getToken()}`)

	// Store subscriptions for cleanup
	const subscriptions = new Map()

	// Enhanced socket object that maintains compatibility with existing frontend code
	const socket = {
		consumer,
		subscriptions,

		// Subscribe to a channel
		subscribe: (channelName, params = {}) => {
			const channel = consumer.subscriptions.create(
				{ channel: channelName, ...params },
				{
					connected() {
						console.log(`Connected to ${channelName}`)
					},
					disconnected() {
						console.log(`Disconnected from ${channelName}`)
					},
					received(data) {
						// Handle incoming WebSocket messages
						console.log(`Received data from ${channelName}:`, data)
					}
				}
			)

			subscriptions.set(channelName, channel)
			return channel
		},

		// Unsubscribe from a channel
		unsubscribe: (channelName) => {
			const channel = subscriptions.get(channelName)
			if (channel) {
				channel.unsubscribe()
				subscriptions.delete(channelName)
			}
		},

		// Generic on method for compatibility with existing code
		on: (event, callback) => {
			console.log(`Socket: listening for ${event}`)
			// Store callback for when actual channels are created
			if (!socket.eventCallbacks) {
				socket.eventCallbacks = new Map()
			}
			if (!socket.eventCallbacks.has(event)) {
				socket.eventCallbacks.set(event, [])
			}
			socket.eventCallbacks.get(event).push(callback)
		},

		// Generic emit method for compatibility
		emit: (event, data) => {
			console.log(`Socket: emitting ${event}`, data)
			// Handle specific events that frontend expects
			if (event === 'update_lesson_progress') {
				// Broadcast to lessons channel
				const lessonChannel = subscriptions.get('LessonsChannel')
				if (lessonChannel) {
					lessonChannel.update_progress(data)
				}
			}
		},

		// Disconnect all subscriptions
		disconnect: () => {
			console.log('Socket: disconnecting from all channels')
			subscriptions.forEach((channel, channelName) => {
				channel.unsubscribe()
			})
			subscriptions.clear()
			consumer.disconnect()
		},

		// Method to subscribe to notifications
		subscribeToNotifications: (callback) => {
			return socket.subscribe('NotificationsChannel', {
				connected() {
					console.log('Connected to notifications')
				},
				received(data) {
					if (callback) callback(data)
				}
			})
		},

		// Method to subscribe to lesson progress
		subscribeToLesson: (lessonId, callback) => {
			return socket.subscribe('LessonsChannel', { lesson_id: lessonId },
				{
					connected() {
						console.log(`Connected to lesson ${lessonId}`)
					},
					received(data) {
						if (callback) callback(data)
					}
				}
			)
		},

		// Method to subscribe to discussions
		subscribeToDiscussion: (discussionId, callbacks = {}) => {
			return socket.subscribe('DiscussionsChannel', { discussion_id: discussionId },
				{
					connected() {
						console.log(`Connected to discussion ${discussionId}`)
					},
					received(data) {
						if (data.type === 'new_message' && callbacks.onNewMessage) {
							callbacks.onNewMessage(data)
						}
						if (data.type === 'message_updated' && callbacks.onUpdateMessage) {
							callbacks.onUpdateMessage(data)
						}
						if (data.type === 'message_deleted' && callbacks.onDeleteMessage) {
							callbacks.onDeleteMessage(data)
						}
					}
				}
			)
		}
	}

	return socket
}
