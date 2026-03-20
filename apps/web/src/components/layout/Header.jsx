import { useOutletContext } from 'react-router-dom'

function HamburgerIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="4" x2="20" y1="6" y2="6" /><line x1="4" x2="20" y1="12" y2="12" /><line x1="4" x2="20" y1="18" y2="18" />
    </svg>
  )
}

export default function Header({ title }) {
  const { onMenuClick } = useOutletContext() ?? {}

  return (
    <header className="h-14 md:h-16 border-b border-border bg-card px-4 md:px-6 flex items-center justify-between shrink-0">
      <div className="flex items-center gap-3">
        {/* Hamburger — mobile only */}
        <button
          className="md:hidden p-1.5 rounded-md text-muted-foreground hover:bg-accent hover:text-accent-foreground transition-colors"
          onClick={onMenuClick}
          aria-label="Open menu"
        >
          <HamburgerIcon />
        </button>
        <h2 className="text-base md:text-lg font-semibold text-foreground">{title}</h2>
      </div>
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-sm font-medium">
          A
        </div>
      </div>
    </header>
  )
}
