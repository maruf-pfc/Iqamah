import { afterEach, describe, expect, it, vi } from 'vitest'
import { shareBackupFile } from '@/services/backupFile'
import { pickNativeBackup } from '@/services/backupPicker'

function channel(status: string, content?: string) {
  Object.assign(window, { IqamahNative: { postMessage(message: string) {
    const request = JSON.parse(message)
    queueMicrotask(() => window.dispatchEvent(new CustomEvent('iqamah-backup-result', { detail: { requestId: request.requestId, status, content } })))
  } } })
}
afterEach(() => { Reflect.deleteProperty(window, 'IqamahNative'); vi.useRealTimers(); vi.restoreAllMocks() })
describe('native backup acknowledgement', () => {
  it('only confirms an acknowledged share', async () => {
    channel('success')
    await expect(shareBackupFile('{}', 'iqamah_backup_test.json')).resolves.toBe('success')
  })
  it('reports cancellation rather than success', async () => {
    channel('cancelled')
    await expect(shareBackupFile('{}', 'iqamah_backup_test.json')).resolves.toBe('cancelled')
  })
  it('reports native failure', async () => {
    channel('error')
    await expect(shareBackupFile('{}', 'iqamah_backup_test.json')).rejects.toThrow('Native backup operation failed')
  })
  it('reads native selected content and distinguishes cancellation', async () => {
    channel('success', '{"version":1}')
    await expect(pickNativeBackup()).resolves.toBe('{"version":1}')
    channel('cancelled')
    await expect(pickNativeBackup()).resolves.toBeNull()
  })
  it('uses HTML input only on standalone web', async () => {
    await expect(pickNativeBackup()).resolves.toBeUndefined()
  })
  it('times out an unacknowledged operation and removes its listener', async () => {
    vi.useFakeTimers()
    Object.assign(window, { IqamahNative: { postMessage() {} } })
    const removed = vi.spyOn(window, 'removeEventListener')
    const failed = pickNativeBackup().catch((error: unknown) => error)
    await vi.advanceTimersByTimeAsync(120000)
    expect(await failed).toEqual(new Error('Native backup operation did not respond.'))
    expect(removed).toHaveBeenCalledWith('iqamah-backup-result', expect.any(Function))
  })
})
