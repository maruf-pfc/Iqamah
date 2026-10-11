/** Optional preferences must not prevent startup when browser storage is blocked. */
export function readPreference(key: string): string | null {
  try { return localStorage.getItem(key) } catch { return null }
}
