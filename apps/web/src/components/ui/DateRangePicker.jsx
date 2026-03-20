const CalendarIcon = () => (
  <svg
    className="w-4 h-4 text-muted-foreground"
    aria-hidden="true"
    xmlns="http://www.w3.org/2000/svg"
    fill="none"
    viewBox="0 0 24 24"
  >
    <path
      stroke="currentColor"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="2"
      d="M4 10h16m-8-3V4M7 7V4m10 3V4M5 20h14a1 1 0 0 0 1-1V7a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1Zm3-7h.01v.01H8V13Zm4 0h.01v.01H12V13Zm4 0h.01v.01H16V13Zm-8 4h.01v.01H8V17Zm4 0h.01v.01H12V17Zm4 0h.01v.01H16V17Z"
    />
  </svg>
)

// input-level class shared by both fields
const inputCls = [
  'block w-full pl-9 pr-3 py-1.5',
  'rounded-md border border-border bg-background',
  'text-sm text-foreground',
  'focus:outline-none focus:ring-2 focus:ring-ring',
  // Push the browser's native clear/spinner icons out of the way so our
  // icon doesn't overlap them. Most browsers show calendar icon on the right.
].join(' ')

/**
 * DateRangePicker
 *
 * Renders two native <input type="date"> fields ("From" and "To") with
 * hard min/max constraints so an invalid range can never be submitted:
 *   • "To" input has min={from}  → can't pick a date before "From"
 *   • "From" input has max={to}  → can't pick a date after "To"
 *   • If the user somehow sets from > to (e.g. clears "To" then picks
 *     a later "From"), "To" is auto-cleared.
 *
 * Values are ISO date strings (YYYY-MM-DD) or undefined when not set.
 */
export default function DateRangePicker({ from, to, onFromChange, onToChange }) {
  function handleFromChange(e) {
    const val = e.target.value || undefined
    onFromChange(val)
    // If the new start is after the existing end, clear the end
    if (val && to && val > to) {
      onToChange(undefined)
    }
  }

  function handleToChange(e) {
    onToChange(e.target.value || undefined)
  }

  function handleClear() {
    onFromChange(undefined)
    onToChange(undefined)
  }

  return (
    <div className="flex items-center gap-2">
      {/* From */}
      <div className="relative">
        <span className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
          <CalendarIcon />
        </span>
        <input
          type="date"
          value={from || ''}
          max={to || undefined}
          onChange={handleFromChange}
          className={inputCls}
        />
      </div>

      <span className="shrink-0 text-sm text-muted-foreground select-none">to</span>

      {/* To */}
      <div className="relative">
        <span className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
          <CalendarIcon />
        </span>
        <input
          type="date"
          value={to || ''}
          min={from || undefined}
          onChange={handleToChange}
          className={inputCls}
        />
      </div>

      {/* Clear */}
      {(from || to) && (
        <button
          type="button"
          onClick={handleClear}
          aria-label="Clear date range"
          className="shrink-0 text-lg leading-none text-muted-foreground hover:text-foreground transition-colors"
        >
          ×
        </button>
      )}
    </div>
  )
}
