'use client'

import * as React from 'react'
import { useQueryState, parseAsBoolean } from 'nuqs'

import { AgentSettings } from '@/components/Agent/AgentSettings'
import { useGlobalStore } from '@/store'
import { DEV_MODE_QUERY_KEY } from '@/constants'
import { AgentBlock } from '@/components/Agent'

export const HomePageContent = () => {
  return (
    <>
      <div className="flex h-[var(--ag-main-min-height)] w-full justify-center">
        <AgentBlock />
        <AgentSettings />
      </div>
    </>
  )
}

// DevMode is a component that is used to set the dev mode(get from url query)
export const DevMode = () => {
  const [isUrlDevMode] = useQueryState(DEV_MODE_QUERY_KEY, parseAsBoolean)
  const { setIsDevMode } = useGlobalStore()

  React.useEffect(() => {
    setIsDevMode(isUrlDevMode ?? false)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isUrlDevMode])

  return null
}
