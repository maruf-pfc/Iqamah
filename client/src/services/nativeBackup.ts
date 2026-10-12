interface NativeBackupResult {
  requestId: string
  status: 'success' | 'cancelled' | 'error'
  content?: string
}
let sequence = 0

/** Correlation IDs are not secrets; do not require secure-context randomUUID on file origins. */
export function requestNativeBackup(request: { action: 'shareBackup'; content: string; filename: string } | { action: 'pickBackup' }): Promise<NativeBackupResult> | undefined {
  const channel = (window as unknown as { IqamahNative?: { postMessage(message: string): void } }).IqamahNative
  if (!channel) return undefined
  return new Promise((resolve, reject) => {
    const requestId = `backup-${Date.now()}-${++sequence}`
    const finish = () => { clearTimeout(timeout); window.removeEventListener('iqamah-backup-result', onResult) }
    const onResult = (event: Event) => {
      const detail: unknown = (event as CustomEvent).detail
      if (!detail || typeof detail !== 'object' || !('requestId' in detail) || detail.requestId !== requestId) return
      finish()
      if ('status' in detail && (detail.status === 'success' || detail.status === 'cancelled')) resolve(detail as NativeBackupResult)
      else reject(new Error('Native backup operation failed or is unavailable.'))
    }
    const timeout = setTimeout(() => { finish(); reject(new Error('Native backup operation did not respond.')) }, 120000)
    window.addEventListener('iqamah-backup-result', onResult)
    try { channel.postMessage(JSON.stringify({ ...request, requestId })) }
    catch (error) { finish(); reject(error) }
  })
}
