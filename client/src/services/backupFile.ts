import { requestNativeBackup } from './nativeBackup'

/** Native acknowledgement is required; posting a message is not evidence of a saved backup. */
export async function shareBackupFile(content: string, filename: string): Promise<'success' | 'cancelled' | 'download-requested'> {
  const pending = requestNativeBackup({ action: 'shareBackup', content, filename })
  if (!pending) {
    const url = URL.createObjectURL(new Blob([content], { type: 'application/json' }))
    const anchor = document.createElement('a')
    anchor.href = url
    anchor.download = filename
    anchor.click()
    setTimeout(() => URL.revokeObjectURL(url), 10000)
    return 'download-requested'
  }
  const result = await pending
  if (result.status === 'error') throw new Error('Native backup operation failed.')
  return result.status
}
