import { useState, useCallback } from 'react'
import { Outlet } from 'react-router-dom'
import Sidebar from './Sidebar'
import { Toaster } from 'sonner'

export default function AppLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const closeSidebar = useCallback(() => setSidebarOpen(false), [])
  const openSidebar = useCallback(() => setSidebarOpen(true), [])

  return (
    <div className="flex h-screen bg-background overflow-hidden">
      <Sidebar open={sidebarOpen} onClose={closeSidebar} />
      <main className="flex-1 overflow-auto min-w-0">
        <Outlet context={{ onMenuClick: openSidebar }} />
      </main>
      <Toaster position="top-right" richColors />
    </div>
  )
}
