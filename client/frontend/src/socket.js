import { io } from 'socket.io-client'

export function initSocket() {
	let host = window.location.hostname
	let siteName = window.site_name || host
	let port = window.location.port ? ':8000' : ''
	let protocol = port ? 'http' : 'https'
	let url = `${protocol}://${host}${port}`

	let socket = io(url, {
		withCredentials: true,
		reconnectionAttempts: 5,
	})
	// Note: Resource refetching disabled for Rails compatibility
	// socket.on('refetch_resource', (data) => {
	// 	// Resource caching not implemented in Rails version
	// })
	return socket
}
