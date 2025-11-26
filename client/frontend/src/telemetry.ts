import { createResource } from 'frappe-ui'

declare global {
  interface Window {
    posthog: any
  }
}

type PosthogSettings = {
  posthog_project_id: string
  posthog_host: string
  enable_telemetry: boolean
  telemetry_site_age: number
}

interface CaptureOptions {
  data: {
    user: string
    [key: string]: string | number | boolean | object
  }
}

// Mock posthog for Rails backend
let posthog = {
  init: (projectId: string, config: any) => {
    console.log('Posthog mock: initialized', projectId, config)
  },
  capture: (event: string, properties: any) => {
    console.log('Posthog mock: capture', event, properties)
  },
  identify: (userId: any) => {
    console.log('Posthog mock: identify', userId)
  },
  people: {
    set: (properties: any) => {
      console.log('Posthog mock: people.set', properties)
    }
  }
}

// Mock Posthog Settings for Rails backend
let posthogSettings = {
  data: {
    posthog_project_id: '',
    posthog_host: '',
    enable_telemetry: false,
    telemetry_site_age: 0
  },
  fetch: () => {
    console.log('Posthog mock: settings fetched')
  }
}

let isTelemetryEnabled = () => {
  return false // Disabled for Rails backend
}

// Posthog Initialization
function initPosthog(ps: PosthogSettings) {
  if (!isTelemetryEnabled()) return
  console.log('Posthog mock: would initialize with', ps)
}

// Posthog Functions
function capture(
  event: string,
  options: CaptureOptions = { data: { user: '' } },
) {
  if (!isTelemetryEnabled()) return
  console.log('Posthog mock: would capture lms_' + event, options)
}

function startRecording() {
  console.log('Posthog mock: would start recording')
}

function stopRecording() {
  console.log('Posthog mock: would stop recording')
}

// Posthog Plugin
function posthogPlugin(app: any) {
    app.config.globalProperties.posthog = posthog
    console.log('Posthog mock: plugin installed')
}

export {
  posthog,
  posthogSettings,
  posthogPlugin,
  capture,
  startRecording,
  stopRecording,
}
