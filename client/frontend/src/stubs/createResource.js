// Simple createResource stub for Rails compatibility
export function createResource(options) {
  return {
    data: options?.initialData || null,
    loading: false,
    error: null,
    promise: Promise.resolve(),
    fetched: false,
    fetch: async () => {
      console.log(`Mock API call: ${options?.url}`)
      return { message: 'Mock response' }
    },
    reload: () => Promise.resolve(),
    submit: () => Promise.resolve(),
    reset: () => {},
    update: () => {},
    setData: () => {}
  }
}