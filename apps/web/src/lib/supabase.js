import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export function subscribeToScans(onInsert) {
  const channel = supabase
    .channel('scans-realtime')
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'scans' },
      (payload) => onInsert(payload.new)
    )
    .subscribe()

  return () => supabase.removeChannel(channel)
}
