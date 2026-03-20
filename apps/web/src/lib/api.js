import axios from 'axios'
import { supabase } from './supabase'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

const api = axios.create({ baseURL: API_URL })

// Attach the current user's JWT to every request
api.interceptors.request.use(async (config) => {
  const { data: { session } } = await supabase.auth.getSession()
  if (session?.access_token) {
    config.headers.Authorization = `Bearer ${session.access_token}`
  }
  return config
})

export async function fetchScans(offset = 0, limit = 20, filters = {}) {
  const params = { offset, limit }
  if (filters.status) params.status = filters.status
  if (filters.from)   params.from   = filters.from
  if (filters.to)     params.to     = filters.to
  const res = await api.get('/scans', { params })
  return res.data
}

export async function fetchScan(id) {
  const res = await api.get(`/scan/${id}`)
  return res.data
}

export async function verifyScan(id, verifiedData) {
  const res = await api.patch(`/scan/${id}`, {
    verified_data: verifiedData,
    status: 'verified',
  })
  return res.data
}

export async function deleteScan(id) {
  const res = await api.delete(`/scan/${id}`)
  return res.data
}

export async function retryScan(id) {
  const res = await api.post(`/scan/${id}/retry`)
  return res.data
}
