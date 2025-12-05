// Stub for frappe-ui/src/resources/resources
export function getCachedResource() {
  return null
}

export function createResource() {
  return {
    data: null,
    loading: false,
    error: null,
    fetch: () => Promise.resolve(),
    reload: () => Promise.resolve()
  }
}