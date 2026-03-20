import { useState } from 'react'
import { NavLink } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'

const navItems = [
  { to: '/', label: 'Dashboard', icon: LayoutIcon },
  { to: '/review', label: 'Review', icon: ClipboardIcon },
]

function LayoutIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect width="7" height="9" x="3" y="3" rx="1" /><rect width="7" height="5" x="14" y="3" rx="1" /><rect width="7" height="9" x="14" y="12" rx="1" /><rect width="7" height="5" x="3" y="16" rx="1" />
    </svg>
  )
}

function ClipboardIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 2H9a1 1 0 0 0-1 1v2c0 .6.4 1 1 1h6c.6 0 1-.4 1-1V3c0-.6-.4-1-1-1Z" /><path d="M8 4H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2h-2" /><path d="M12 11h4" /><path d="M12 16h4" /><path d="M8 11h.01" /><path d="M8 16h.01" />
    </svg>
  )
}

function LogOutIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" x2="9" y1="12" y2="12" />
    </svg>
  )
}

function ChevronLeftIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m15 18-6-6 6-6" />
    </svg>
  )
}

function ChevronRightIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m9 18 6-6-6-6" />
    </svg>
  )
}

export default function Sidebar({ open, onClose }) {
  const { session, signOut } = useAuth()
  const email = session?.user?.email
  const [collapsed, setCollapsed] = useState(false)

  return (
    <>
      {/* Mobile backdrop */}
      <div
        className={`fixed inset-0 z-30 bg-black/40 transition-opacity md:hidden ${
          open ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'
        }`}
        onClick={onClose}
        aria-hidden="true"
      />

      {/* Sidebar panel */}
      <aside
        className={`
          fixed inset-y-0 left-0 z-40 flex flex-col h-screen
          border-r border-border bg-card
          transition-transform duration-200
          ${open ? 'translate-x-0' : '-translate-x-full'}
          md:static md:translate-x-0 md:z-auto
          ${collapsed ? 'md:w-16' : 'md:w-64'}
          w-64
        `}
      >
        {/* Header */}
        <div className={`p-4 border-b border-border flex items-center shrink-0 ${collapsed ? 'md:justify-center' : 'justify-between'}`}>
          <div className={`min-w-0 ${collapsed ? 'md:hidden' : ''}`}>
            <h1 className="text-xl font-bold text-foreground">ScriptFlow</h1>
            <p className="text-xs text-muted-foreground mt-1">Clinical Register Digitizer</p>
          </div>
          {/* Collapse toggle — desktop only */}
          <button
            onClick={() => setCollapsed((c) => !c)}
            className="hidden md:flex p-1.5 rounded-md text-muted-foreground hover:bg-accent hover:text-accent-foreground transition-colors shrink-0"
            title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            {collapsed ? <ChevronRightIcon /> : <ChevronLeftIcon />}
          </button>
        </div>

        {/* Nav */}
        <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              onClick={onClose}
              title={collapsed ? item.label : undefined}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors ${collapsed ? 'md:justify-center' : ''} ${
                  isActive
                    ? 'bg-primary text-primary-foreground'
                    : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
                }`
              }
            >
              <item.icon />
              <span className={collapsed ? 'md:hidden' : ''}>{item.label}</span>
            </NavLink>
          ))}
        </nav>

        {/* Footer */}
        <div className={`p-3 border-t border-border shrink-0 ${collapsed ? 'md:flex md:flex-col md:items-center' : 'space-y-2'}`}>
          {email && (
            <p className={`text-xs text-muted-foreground truncate mb-2 ${collapsed ? 'md:hidden' : ''}`} title={email}>
              {email}
            </p>
          )}
          <button
            onClick={signOut}
            title={collapsed ? 'Sign out' : undefined}
            className="flex items-center gap-2 text-xs text-muted-foreground hover:text-foreground transition-colors"
          >
            <LogOutIcon />
            <span className={collapsed ? 'md:hidden' : ''}>Sign out</span>
          </button>
        </div>
      </aside>
    </>
  )
}
