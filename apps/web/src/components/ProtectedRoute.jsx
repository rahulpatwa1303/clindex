import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export default function ProtectedRoute() {
  const { session } = useAuth()

  // Still checking session — render nothing to avoid flash
  if (session === undefined) return null

  if (!session) return <Navigate to="/login" replace />

  return <Outlet />
}
