import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { fetchScans, deleteScan, retryScan } from '../lib/api'
import { subscribeToScans } from '../lib/supabase'
import Header from '../components/layout/Header'
import Badge from '../components/ui/Badge'
import Button from '../components/ui/Button'
import DataTable from '../components/ui/DataTable'
import { useTableURL } from '../hooks/useTableURL'

const PAGE_SIZE = 20

const FILTER_KEYS = ['status', 'from', 'to']

const FILTER_DEFS = [
  {
    id: 'status',
    label: 'Status',
    type: 'select',
    options: [
      { value: '', label: 'All Statuses' },
      { value: 'new', label: 'New' },
      { value: 'processing', label: 'Processing' },
      { value: 'review_needed', label: 'Review Needed' },
      { value: 'verified', label: 'Verified' },
      { value: 'failed', label: 'Failed' },
    ],
  },
  { id: 'daterange', label: 'Date', type: 'daterange', fromId: 'from', toId: 'to' },
]

const DASHBOARD_COLUMNS = [
  { id: 'date',    label: 'Date',    width: 200, minWidth: 120 },
  { id: 'status',  label: 'Status',  width: 160, minWidth: 100 },
  { id: 'image',   label: 'Image',   width: 100, minWidth: 80  },
  { id: 'actions', label: 'Actions', width: 220, minWidth: 160, resizable: false, reorderable: false, align: 'right' },
]

export default function Dashboard() {
  const [scans, setScans] = useState([])
  const [total, setTotal] = useState(0)
  const [newIds, setNewIds] = useState(new Set())
  const [retryingIds, setRetryingIds] = useState(new Set())
  const navigate = useNavigate()

  const { page, filters, setPage, setFilters } = useTableURL(FILTER_KEYS)

  const loadScans = useCallback(async () => {
    try {
      const result = await fetchScans(page * PAGE_SIZE, PAGE_SIZE, filters)
      setScans(result.data)
      setTotal(result.total)
    } catch {
      toast.error('Failed to load scans')
    }
  }, [page, filters])

  useEffect(() => {
    loadScans()
  }, [loadScans])

  // Realtime subscription
  useEffect(() => {
    const unsubscribe = subscribeToScans((newScan) => {
      toast.success('New Document Arrived', {
        description: `Scan uploaded at ${new Date(newScan.created_at).toLocaleTimeString()}`,
      })
      setNewIds((prev) => new Set([...prev, newScan.id]))
      setScans((prev) => [newScan, ...prev])
      setTotal((prev) => prev + 1)

      setTimeout(() => {
        setNewIds((prev) => {
          const next = new Set(prev)
          next.delete(newScan.id)
          return next
        })
      }, 30000)
    })
    return unsubscribe
  }, [])

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this scan? This cannot be undone.')) return
    try {
      await deleteScan(id)
      setScans((prev) => prev.filter((s) => s.id !== id))
      setTotal((prev) => prev - 1)
      toast.success('Scan deleted')
    } catch {
      toast.error('Failed to delete scan')
    }
  }

  const handleRetry = async (id) => {
    setRetryingIds((prev) => new Set([...prev, id]))
    setScans((prev) => prev.map((s) => s.id === id ? { ...s, status: 'processing' } : s))
    try {
      await retryScan(id)
      toast.success('Extraction complete')
      loadScans()
    } catch {
      toast.error('Retry failed')
      loadScans()
    } finally {
      setRetryingIds((prev) => {
        const next = new Set(prev)
        next.delete(id)
        return next
      })
    }
  }

  const columns = DASHBOARD_COLUMNS.map((col) => ({
    ...col,
    render: (scan) => {
      if (col.id === 'date') {
        return (
          <span className="text-foreground">
            {new Date(scan.created_at).toLocaleString()}
          </span>
        )
      }
      if (col.id === 'status') {
        return (
          <div className="flex items-center gap-2">
            {newIds.has(scan.id) && <Badge status="new" />}
            <Badge status={scan.status} />
          </div>
        )
      }
      if (col.id === 'image') {
        return scan.image_url ? (
          <img
            src={scan.image_url}
            alt="Scan thumbnail"
            className="w-12 h-12 object-cover rounded border border-border"
          />
        ) : null
      }
      if (col.id === 'actions') {
        return (
          <div className="flex items-center justify-end gap-2">
            {scan.status === 'failed' && (
              <Button
                variant="secondary"
                disabled={retryingIds.has(scan.id)}
                onClick={() => handleRetry(scan.id)}
              >
                {retryingIds.has(scan.id) ? 'Retrying…' : 'Retry'}
              </Button>
            )}
            {scan.status !== 'failed' && scan.status !== 'processing' && (
              <Button
                variant="secondary"
                onClick={() => navigate(`/review/${scan.id}`)}
              >
                Review
              </Button>
            )}
            <Button
              variant="destructive"
              onClick={() => handleDelete(scan.id)}
            >
              Delete
            </Button>
          </div>
        )
      }
      return null
    },
  }))

  return (
    <div>
      <Header title="Dashboard" />
      <div className="p-4 md:p-6">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h3 className="text-2xl font-bold text-foreground">Scans</h3>
            <p className="text-sm text-muted-foreground">{total} total documents</p>
          </div>
        </div>

        <DataTable
          tableKey="dashboard"
          columns={columns}
          data={scans}
          total={total}
          page={page}
          pageSize={PAGE_SIZE}
          onPageChange={setPage}
          filters={filters}
          filterDefs={FILTER_DEFS}
          onFiltersChange={setFilters}
          emptyMessage="No scans found"
          rowClassName={(scan) =>
            newIds.has(scan.id) ? 'animate-pulse bg-blue-50' : ''
          }
        />
      </div>
    </div>
  )
}
