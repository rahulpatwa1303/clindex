import { useState, useCallback } from 'react'

function loadPrefs(tableKey) {
  try {
    const raw = localStorage.getItem(`table_prefs_${tableKey}`)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

function savePrefs(tableKey, prefs) {
  try {
    localStorage.setItem(`table_prefs_${tableKey}`, JSON.stringify(prefs))
  } catch {
    // ignore storage errors
  }
}

// defaultColumns: array of column definitions [{ id, ... }]
export function useColumnPrefs(tableKey, defaultColumns) {
  const defaultOrder = defaultColumns.map((c) => c.id)

  const [prefs, setPrefs] = useState(() => {
    const stored = loadPrefs(tableKey)
    if (!stored) return { order: defaultOrder, widths: {} }

    // Merge: append any new columns not in stored order
    const storedOrder = stored.order || []
    const newCols = defaultOrder.filter((id) => !storedOrder.includes(id))
    const validOrder = storedOrder.filter((id) => defaultOrder.includes(id))
    return {
      order: [...validOrder, ...newCols],
      widths: stored.widths || {},
    }
  })

  const columnOrder = prefs.order
  const columnWidths = prefs.widths

  const setColumnOrder = useCallback((newOrder) => {
    setPrefs((prev) => {
      const next = { ...prev, order: newOrder }
      savePrefs(tableKey, next)
      return next
    })
  }, [tableKey])

  const setColumnWidth = useCallback((colId, width) => {
    setPrefs((prev) => {
      const next = { ...prev, widths: { ...prev.widths, [colId]: width } }
      savePrefs(tableKey, next)
      return next
    })
  }, [tableKey])

  const resetColumns = useCallback(() => {
    localStorage.removeItem(`table_prefs_${tableKey}`)
    setPrefs({ order: defaultOrder, widths: {} })
  }, [tableKey, defaultOrder])

  const isReordered = columnOrder.join(',') !== defaultOrder.join(',')

  return { columnOrder, columnWidths, setColumnOrder, setColumnWidth, resetColumns, isReordered }
}
