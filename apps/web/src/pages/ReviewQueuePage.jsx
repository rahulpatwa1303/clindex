import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { fetchScans, deleteScan } from '../lib/api'
import Header from '../components/layout/Header'
import Badge from '../components/ui/Badge'
import Button from '../components/ui/Button'
import DataTable from '../components/ui/DataTable'
import { useTableURL } from '../hooks/useTableURL'

const PAGE_SIZE = 20

const FILTER_KEYS = ['from', 'to']

const FILTER_DEFS = [
  { id: 'daterange', label: 'Date', type: 'daterange', fromId: 'from', toId: 'to' },
]

const REVIEW_QUEUE_COLUMNS = [
  { id: 'date',    label: 'Date',    width: 200, minWidth: 120 },
  { id: 'status',  label: 'Status',  width: 160, minWidth: 100 },
  { id: 'image',   label: 'Image',   width: 100, minWidth: 80  },
  { id: 'actions', label: 'Actions', width: 220, minWidth: 160, resizable: false, reorderable: false, align: 'right' },
]

export default function ReviewQueuePage() {
  const [scans, setScans] = useState([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate()

  const { page, filters, setPage, setFilters } = useTableURL(FILTER_KEYS)

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

  const loadScans = useCallback(async () => {
    try {
      const result = await fetchScans(
        page * PAGE_SIZE,
        PAGE_SIZE,
        { status: 'review_needed', ...filters }
      )
      setScans(result.data)
      setTotal(result.total)
    } catch {
      toast.error('Failed to load review queue')
    } finally {
      setLoading(false)
    }
  }, [page, filters])

  useEffect(() => {
    loadScans()
  }, [loadScans])

  const columns = REVIEW_QUEUE_COLUMNS.map((col) => ({
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
        return <Badge status={scan.status} />
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
            <Button
              variant="secondary"
              onClick={() => navigate(`/review/${scan.id}`)}
            >
              Review
            </Button>
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
      <Header title="Review Queue" />
      <div className="p-6">
        <div className="mb-6">
          <h3 className="text-2xl font-bold text-foreground">Pending Review</h3>
          <p className="text-sm text-muted-foreground">
            {loading ? 'Loading…' : `${total} document${total !== 1 ? 's' : ''} awaiting review`}
          </p>
        </div>

        <DataTable
          tableKey="review-queue"
          columns={columns}
          data={scans}
          total={total}
          page={page}
          pageSize={PAGE_SIZE}
          onPageChange={setPage}
          filters={filters}
          filterDefs={FILTER_DEFS}
          onFiltersChange={setFilters}
          emptyMessage="No scans pending review"
        />
      </div>
    </div>
  )
}
