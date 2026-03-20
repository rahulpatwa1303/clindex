import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { fetchScan, verifyScan } from '../lib/api'
import Header from '../components/layout/Header'
import Badge from '../components/ui/Badge'
import Button from '../components/ui/Button'

export default function ReviewPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [scan, setScan] = useState(null)
  const [editData, setEditData] = useState(null)
  const [hoveredField, setHoveredField] = useState(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    fetchScan(id).then((data) => {
      setScan(data)
      // Use verified_data if available, else raw_ai_response
      setEditData(structuredClone(data.verified_data || data.raw_ai_response))
    }).catch(() => toast.error('Failed to load scan'))
  }, [id])

  const updateRecordField = (recordIndex, field, value) => {
    setEditData((prev) => {
      const updated = structuredClone(prev)
      updated.records[recordIndex][field].value = value
      return updated
    })
  }

  const handleVerify = async () => {
    setSaving(true)
    try {
      await verifyScan(id, editData)
      toast.success('Scan verified successfully')
      navigate('/')
    } catch (err) {
      toast.error('Failed to verify scan')
    } finally {
      setSaving(false)
    }
  }

  // Convert box_2d [y1, x1, y2, x2] (0-1000) to CSS percentages
  const getOverlayStyle = (box) => {
    if (!box || box.length !== 4) return null
    const [y1, x1, y2, x2] = box
    return {
      left: `${(x1 / 1000) * 100}%`,
      top: `${(y1 / 1000) * 100}%`,
      width: `${((x2 - x1) / 1000) * 100}%`,
      height: `${((y2 - y1) / 1000) * 100}%`,
    }
  }

  if (!scan || !editData) {
    return (
      <div>
        <Header title="Review" />
        <div className="flex items-center justify-center h-64 text-muted-foreground text-sm">
          Loading…
        </div>
      </div>
    )
  }

  // Collect all box_2d overlays from the currently hovered field
  const activeOverlay = hoveredField
    ? getOverlayStyle(hoveredField.box_2d)
    : null

  return (
    <div className="flex flex-col" style={{ height: '100dvh' }}>
      <Header title="Review Scan" />

      {/* Toolbar */}
      <div className="px-6 py-3 border-b border-border flex items-center justify-between bg-card">
        <div className="flex items-center gap-3">
          <Button variant="ghost" onClick={() => navigate('/')}>
            &larr;
          </Button>
          <Badge status={scan.status} />
        </div>
        <Button onClick={handleVerify} disabled={saving}>
          {saving ? 'Saving...' : 'Verify & Save'}
        </Button>
      </div>

      {/* Split View */}
      <div className="flex-1 flex flex-col md:flex-row overflow-hidden">
        {/* Image panel */}
        <div className="md:flex-1 overflow-auto p-4 bg-muted/30 max-h-[45vh] md:max-h-none">
          <div className="relative inline-block">
            <img
              src={scan.image_url}
              alt="Scanned document"
              className="max-w-full rounded-lg shadow-md"
            />
            {/* Coordinate overlay */}
            {activeOverlay && (
              <div
                className="absolute bg-blue-500/20 border-2 border-blue-500 rounded-sm transition-all duration-200 pointer-events-none"
                style={activeOverlay}
              />
            )}
          </div>
        </div>

        {/* Editable form panel */}
        <div className="w-full md:w-[480px] border-t md:border-t-0 md:border-l border-border overflow-auto p-4 md:p-6 bg-card">
          {/* Header fields */}
          {editData.header && (
            <div className="mb-6">
              <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-3">
                Header
              </h3>
              <div className="space-y-3">
                <FieldInput
                  label="Date"
                  field={editData.header.date}
                  onChange={(val) => {
                    setEditData((prev) => {
                      const updated = structuredClone(prev)
                      updated.header.date.value = val
                      return updated
                    })
                  }}
                  onHover={setHoveredField}
                />
              </div>
            </div>
          )}

          {/* Records */}
          <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-3">
            Records ({editData.records?.length || 0})
          </h3>
          <div className="space-y-4">
            {editData.records?.map((record, idx) => (
              <div
                key={idx}
                className="border border-border rounded-lg p-4 space-y-3"
              >
                <div className="text-sm font-medium text-foreground">
                  Record #{idx + 1}
                </div>
                <FieldInput
                  label="Patient Name"
                  field={record.patient_name}
                  onChange={(val) => updateRecordField(idx, 'patient_name', val)}
                  onHover={setHoveredField}
                />
                <FieldInput
                  label="Treatment"
                  field={record.treatment}
                  onChange={(val) => updateRecordField(idx, 'treatment', val)}
                  onHover={setHoveredField}
                />
                <FieldInput
                  label="Amount"
                  field={record.amount}
                  type="number"
                  onChange={(val) => updateRecordField(idx, 'amount', Number(val))}
                  onHover={setHoveredField}
                />
                <FieldInput
                  label="Mode"
                  field={record.mode}
                  onChange={(val) => updateRecordField(idx, 'mode', val)}
                  onHover={setHoveredField}
                />
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function FieldInput({ label, field, type = 'text', onChange, onHover }) {
  if (!field) return null

  const confidence = field.confidence ?? 1
  const confidenceColor =
    confidence >= 0.8
      ? 'text-green-600'
      : confidence >= 0.5
        ? 'text-amber-600'
        : 'text-red-600'

  return (
    <div
      onMouseEnter={() => onHover(field)}
      onMouseLeave={() => onHover(null)}
    >
      <div className="flex items-center justify-between mb-1">
        <label className="text-xs font-medium text-muted-foreground">{label}</label>
        <span className={`text-xs ${confidenceColor}`}>
          {Math.round(confidence * 100)}%
        </span>
      </div>
      <input
        type={type}
        value={field.value ?? ''}
        onChange={(e) => onChange(e.target.value)}
        className="w-full px-3 py-2 text-sm border border-border rounded-md bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
      />
    </div>
  )
}
