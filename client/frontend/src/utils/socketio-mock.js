// Mock socket.io to prevent FrappeUI from trying to connect to port 9000
// This prevents CORS errors while we use Action Cable for real WebSocket functionality

class MockSocketIO {
  constructor(url, options = {}) {
    console.log(`[Socket.io Mock] Preventing connection to ${url}`)
    this.url = url
    this.options = options
    this.connected = false
  }

  connect() {
    console.log('[Socket.io Mock] Mock connection established')
    this.connected = true
    setTimeout(() => {
      this.emit('connect')
    }, 100)
  }

  disconnect() {
    console.log('[Socket.io Mock] Mock disconnect')
    this.connected = false
    this.emit('disconnect')
  }

  on(event, callback) {
    console.log(`[Socket.io Mock] Listening for event: ${event}`)
    // Store event listeners but don't actually do anything
    if (!this.eventListeners) {
      this.eventListeners = {}
    }
    if (!this.eventListeners[event]) {
      this.eventListeners[event] = []
    }
    this.eventListeners[event].push(callback)
    return this
  }

  off(event, callback) {
    if (this.eventListeners && this.eventListeners[event]) {
      const index = this.eventListeners[event].indexOf(callback)
      if (index > -1) {
        this.eventListeners[event].splice(index, 1)
      }
    }
    return this
  }

  emit(event, ...args) {
    console.log(`[Socket.io Mock] Emitting event: ${event}`, args)
    if (this.eventListeners && this.eventListeners[event]) {
      this.eventListeners[event].forEach(callback => {
        try {
          callback(...args)
        } catch (error) {
          console.error(`[Socket.io Mock] Error in event callback for ${event}:`, error)
        }
      })
    }
    return this
  }

  // Additional socket.io methods that FrappeUI might try to call
  once(event, callback) {
    const onceWrapper = (...args) => {
      this.off(event, onceWrapper)
      callback(...args)
    }
    return this.on(event, onceWrapper)
  }

  removeAllListeners(event) {
    if (event) {
      if (this.eventListeners && this.eventListeners[event]) {
        delete this.eventListeners[event]
      }
    } else {
      this.eventListeners = {}
    }
    return this
  }

  // For compatibility with socket.io-client v4+
  close() {
    this.disconnect()
  }
}

// Mock io function that returns our mock socket
function io(url, options = {}) {
  return new MockSocketIO(url, options)
}

// Export for compatibility
export { io as default, io, MockSocketIO }