import { useCallback, useMemo } from 'react'
import { useSearchParams } from 'react-router-dom'

// filterKeys must be a stable reference (define as module-level constant in calling component)
export function useTableURL(filterKeys) {
  const [searchParams, setSearchParams] = useSearchParams()

  // URL stores page as 1-indexed; we expose 0-indexed internally
  const page = Math.max(0, (parseInt(searchParams.get('page') || '1', 10) - 1))

  // Memoize filters object so it has a stable reference between renders
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const filters = useMemo(() => {
    const result = {}
    for (const key of filterKeys) {
      const val = searchParams.get(key)
      if (val) result[key] = val
    }
    return result
  // We intentionally use searchParams.toString() as the dependency so the
  // object is only re-created when the URL actually changes.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams.toString(), filterKeys])

  const setPage = useCallback((newPage) => {
    setSearchParams((prev) => {
      const next = new URLSearchParams(prev)
      if (newPage === 0) {
        next.delete('page')
      } else {
        next.set('page', String(newPage + 1))
      }
      return next
    }, { replace: true })
  }, [setSearchParams])

  const setFilters = useCallback((newFilters) => {
    setSearchParams((prev) => {
      const next = new URLSearchParams(prev)
      // Reset page when filters change
      next.delete('page')
      // Remove all current filter keys
      for (const key of filterKeys) {
        next.delete(key)
      }
      // Set new filter values
      for (const [key, val] of Object.entries(newFilters)) {
        if (val) next.set(key, val)
      }
      return next
    }, { replace: true })
  }, [setSearchParams, filterKeys])

  return { page, filters, setPage, setFilters }
}
