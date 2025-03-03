/* eslint-disable @typescript-eslint/no-explicit-any */
'use client'

import { logger } from '@/lib/logger'

type EventHandler<T extends any[]> = (...data: T) => void

export class EventService<T> {
  private _eventMap: Map<keyof T, EventHandler<any[]>[]> = new Map()

  once<Key extends keyof T>(evt: Key, cb: T[Key]) {
    const wrapper = (...args: any[]) => {
      this.off(evt, wrapper as any)
        ; (cb as any)(...args)
    }
    this.on(evt, wrapper as any)
    return this
  }

  on<Key extends keyof T>(evt: Key, cb: T[Key]) {
    const cbs = this._eventMap.get(evt) ?? []
    cbs.push(cb as any)
    this._eventMap.set(evt, cbs)
    logger.debug(`Subscribed to event: ${String(evt)}`)
    return this
  }

  off<Key extends keyof T>(evt: Key, cb: T[Key]) {
    const cbs = this._eventMap.get(evt)
    if (cbs) {
      this._eventMap.set(
        evt,
        cbs.filter((it) => it !== cb)
      )
      logger.debug(`Unsubscribed from event: ${String(evt)}`)
    }
    return this
  }

  removeAllEventListeners(): void {
    this._eventMap.clear()
    logger.debug('Removed all event listeners')
  }

  emit<Key extends keyof T>(evt: Key, ...args: any[]) {
    const cbs = this._eventMap.get(evt) ?? []
    for (const cb of cbs) {
      try {
        // eslint-disable-next-line @typescript-eslint/no-unused-expressions
        cb && cb(...args)
      } catch (e) {
        // cb exception should not affect other callbacks
        const error = e as Error
        const details = error.stack || error.message
        console.error(`Error handling event ${String(evt)}: ${details}`)
      }
    }
    logger.debug({ args }, `Emitted event: ${String(evt)}`)
    return this
  }
}
