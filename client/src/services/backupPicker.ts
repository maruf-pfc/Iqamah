import { requestNativeBackup } from './nativeBackup'

/** Returns undefined on standalone web (use HTML input), null on cancellation. */
export async function pickNativeBackup(): Promise<string | null | undefined> {
  const pending = requestNativeBackup({ action: 'pickBackup' })
  if (!pending) return undefined
  const result = await pending
  if (result.status === 'cancelled') return null
  if (result.status !== 'success' || typeof result.content !== 'string') throw new Error('Unable to read backup file.')
  return result.content
}
