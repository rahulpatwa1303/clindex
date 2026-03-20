import { useState, useRef, useEffect, useCallback } from 'react'
import { useColumnPrefs } from '../../hooks/useColumnPrefs'
import Button from './Button'
import DateRangePicker from './DateRangePicker'

export default function DataTable({
  tableKey,
  columns,
  data,
  total,
  page,
  pageSize = 20,
  onPageChange,
  filters = {},
  filterDefs = [],
  onFiltersChange,
  emptyMessage = 'No results found',
  rowClassName,
}) {
  const { columnOrder, columnWidths, setColumnOrder, setColumnWidth, resetColumns, isReordered } =
    useColumnPrefs(tableKey, columns)

  // Drag-to-reorder state
  const dragColRef = useRef(null)
  const [dragOver, setDragOver] = useState(null)

  // Resize state
  const resizeRef = useRef(null)
  const [isResizing, setIsResizing] = useState(false)
  const [hoverResizeCol, setHoverResizeCol] = useState(null)

  const totalPages = Math.ceil(total / pageSize)

  // Build ordered columns
  const colMap = Object.fromEntries(columns.map((c) => [c.id, c]))
  const orderedCols = columnOrder
    .filter((id) => colMap[id])
    .map((id) => colMap[id])

  function getWidth(col) {
    return columnWidths[col.id] ?? col.width ?? 160
  }

  const minTableWidth = orderedCols.reduce((sum, col) => sum + (col.minWidth ?? 80), 0)

  // ── Filters ──────────────────────────────────────────────────────────────

  // How many filter controls have active values
  const activeCount = filterDefs.filter((f) => {
    if (f.type === 'daterange') return !!(filters[f.fromId] || filters[f.toId])
    return !!filters[f.id]
  }).length

  function clearAllFilters() {
    const cleared = {}
    filterDefs.forEach((f) => {
      if (f.type === 'daterange') {
        cleared[f.fromId] = undefined
        cleared[f.toId] = undefined
      } else {
        cleared[f.id] = undefined
      }
    })
    onFiltersChange(cleared)
  }

  // ── Drag-to-reorder ──────────────────────────────────────────────────────
  function handleDragStart(e, colId) {
    dragColRef.current = colId
    e.dataTransfer.effectAllowed = 'move'
  }

  function handleDragOver(e, colId) {
    e.preventDefault()
    if (colMap[colId]?.reorderable === false) return
    setDragOver(colId)
  }

  function handleDrop(e, targetColId) {
    e.preventDefault()
    const sourceId = dragColRef.current
    if (!sourceId || sourceId === targetColId || colMap[targetColId]?.reorderable === false) {
      setDragOver(null)
      return
    }
    const newOrder = [...columnOrder]
    const fromIdx = newOrder.indexOf(sourceId)
    const toIdx = newOrder.indexOf(targetColId)
    if (fromIdx !== -1 && toIdx !== -1) {
      newOrder.splice(fromIdx, 1)
      newOrder.splice(toIdx, 0, sourceId)
      setColumnOrder(newOrder)
    }
    dragColRef.current = null
    setDragOver(null)
  }

  function handleDragEnd() {
    dragColRef.current = null
    setDragOver(null)
  }

  // ── Column resize ────────────────────────────────────────────────────────
  const handleResizeMouseDown = useCallback((e, colId) => {
    e.preventDefault()
    const col = colMap[colId]
    // For columns without a stored width, read actual rendered width from DOM
    const thEl = document.querySelector(`[data-col-resize="${colId}"]`)
    const startWidth =
      columnWidths[colId] ?? (thEl ? thEl.offsetWidth : (col.width ?? 160))
    resizeRef.current = {
      colId,
      startX: e.clientX,
      startWidth,
      minWidth: col.minWidth ?? 80,
    }
    setIsResizing(true)
    setHoverResizeCol(null)
  }, [colMap, columnWidths])

  useEffect(() => {
    if (!isResizing) return

    function handleMouseMove(e) {
      const { colId, startX, startWidth, minWidth } = resizeRef.current
      const newWidth = Math.max(minWidth, startWidth + (e.clientX - startX))
      const thEl = document.querySelector(`[data-col-resize="${colId}"]`)
      if (thEl) thEl.style.width = `${newWidth}px`
    }

    function handleMouseUp(e) {
      const { colId, startX, startWidth, minWidth } = resizeRef.current
      const newWidth = Math.max(minWidth, startWidth + (e.clientX - startX))
      setColumnWidth(colId, newWidth)
      setIsResizing(false)
      resizeRef.current = null
    }

    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)
    return () => {
      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('mouseup', handleMouseUp)
    }
  }, [isResizing, setColumnWidth])

  // ── Render ───────────────────────────────────────────────────────────────
  return (
    <div>
      {/* Toolbar */}
      <div className="flex items-center flex-wrap gap-x-4 gap-y-2 mb-3">

        {filterDefs.map((f) => (
          <div key={f.id} className="flex items-center gap-1.5">
            <label className="text-xs font-medium text-muted-foreground whitespace-nowrap">
              {f.label}
            </label>

            {/* Select filter */}
            {f.type === 'select' && (
              <select
                value={filters[f.id] || ''}
                onChange={(e) =>
                  onFiltersChange({ ...filters, [f.id]: e.target.value || undefined })
                }
                className="rounded-md border border-border bg-background px-2 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
              >
                {f.options.map((opt) => (
                  <option key={opt.value} value={opt.value}>{opt.label}</option>
                ))}
              </select>
            )}

            {/* Date range filter */}
            {f.type === 'daterange' && (
              <DateRangePicker
                from={filters[f.fromId]}
                to={filters[f.toId]}
                onFromChange={(val) => onFiltersChange({ ...filters, [f.fromId]: val })}
                onToChange={(val) => onFiltersChange({ ...filters, [f.toId]: val })}
              />
            )}

            {/* Single date filter */}
            {f.type === 'date' && (
              <div className="flex items-center gap-1">
                <input
                  type="date"
                  value={filters[f.id] || ''}
                  onChange={(e) =>
                    onFiltersChange({ ...filters, [f.id]: e.target.value || undefined })
                  }
                  className="rounded-md border border-border bg-background px-2 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
                />
                {filters[f.id] && (
                  <button
                    onClick={() => onFiltersChange({ ...filters, [f.id]: undefined })}
                    className="text-muted-foreground hover:text-foreground"
                    aria-label={`Clear ${f.label}`}
                  >
                    ×
                  </button>
                )}
              </div>
            )}
          </div>
        ))}

        {activeCount > 1 && (
          <button
            onClick={clearAllFilters}
            className="text-xs text-muted-foreground hover:text-foreground underline"
          >
            Clear all
          </button>
        )}

        {isReordered && (
          <span className="ml-auto text-xs text-muted-foreground flex items-center gap-1">
            ⚙ Columns reordered ·{' '}
            <button onClick={resetColumns} className="underline hover:text-foreground">
              Reset to default
            </button>
          </span>
        )}
      </div>

      {/* Table wrapper */}
      <div
        className="border border-border rounded-lg overflow-x-auto"
        style={{ cursor: isResizing ? 'col-resize' : undefined }}
      >
        <table
          className="text-sm"
          style={{
            tableLayout: 'fixed',
            width: '100%',
            minWidth: `${minTableWidth}px`,
          }}
        >
          <colgroup>
            {orderedCols.map((col) => (
              <col key={col.id} style={{ width: `${getWidth(col)}px` }} />
            ))}
          </colgroup>

          <thead className="bg-muted">
            <tr>
              {orderedCols.map((col) => {
                const canReorder = col.reorderable !== false
                const canResize = col.resizable !== false
                const isHoverResize = hoverResizeCol === col.id
                const isDragTarget = dragOver === col.id
                const isRight = col.align === 'right'

                return (
                  <th
                    key={col.id}
                    data-col-resize={col.id}
                    style={{ position: 'relative', userSelect: 'none' }}
                    className={[
                      isRight ? 'text-right' : 'text-left',
                      'px-4 py-3 font-medium text-muted-foreground',
                      isDragTarget ? 'bg-blue-50 dark:bg-blue-950' : '',
                    ].join(' ')}
                    draggable={canReorder}
                    onDragStart={canReorder ? (e) => handleDragStart(e, col.id) : undefined}
                    onDragOver={(e) => handleDragOver(e, col.id)}
                    onDrop={(e) => handleDrop(e, col.id)}
                    onDragEnd={handleDragEnd}
                  >
                    {col.label}

                    {/* Visible resize divider */}
                    {canResize && (
                      <div
                        style={{
                          position: 'absolute',
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: '8px',
                          cursor: 'col-resize',
                          display: 'flex',
                          alignItems: 'stretch',
                          justifyContent: 'center',
                          zIndex: 1,
                        }}
                        onMouseEnter={() => setHoverResizeCol(col.id)}
                        onMouseLeave={() => setHoverResizeCol(null)}
                        onMouseDown={(e) => handleResizeMouseDown(e, col.id)}
                      >
                        <div
                          style={{
                            width: isHoverResize ? '3px' : '1px',
                            borderRadius: '2px',
                            background: isHoverResize
                              ? 'var(--primary, #6366f1)'
                              : 'var(--border, #e2e8f0)',
                            transition: 'width 0.1s, background 0.1s',
                            alignSelf: 'stretch',
                          }}
                        />
                      </div>
                    )}
                  </th>
                )
              })}
            </tr>
          </thead>

          <tbody className="divide-y divide-border">
            {data.map((row, rowIdx) => (
              <tr
                key={row.id ?? rowIdx}
                className={`hover:bg-muted/50 transition-colors ${rowClassName ? rowClassName(row) : ''}`}
              >
                {orderedCols.map((col) => (
                  <td
                    key={col.id}
                    className={`px-4 py-3 overflow-hidden ${col.align === 'right' ? 'text-right' : ''}`}
                  >
                    {col.render ? col.render(row) : row[col.id]}
                  </td>
                ))}
              </tr>
            ))}
            {data.length === 0 && (
              <tr>
                <td
                  colSpan={orderedCols.length}
                  className="px-4 py-12 text-center text-muted-foreground"
                >
                  {emptyMessage}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-muted-foreground">
            Page {page + 1} of {totalPages} · {total} total
          </p>
          <div className="flex gap-2">
            <Button
              variant="secondary"
              onClick={() => onPageChange(Math.max(0, page - 1))}
              disabled={page === 0}
            >
              Previous
            </Button>
            <Button
              variant="secondary"
              onClick={() => onPageChange(Math.min(totalPages - 1, page + 1))}
              disabled={page >= totalPages - 1}
            >
              Next
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}
