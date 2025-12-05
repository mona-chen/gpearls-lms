// Stub for frappe-ui/src/resources/listResource
export function getCachedListResource() {
  return null
}

export function createListResource() {
  return {
    data: [],
    loading: false,
    error: null,
    fetch: () => Promise.resolve(),
    reload: () => Promise.resolve()
  }
}