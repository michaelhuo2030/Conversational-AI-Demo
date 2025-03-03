'use client'

import * as React from 'react'
import { useTranslations } from 'next-intl'
import Typewriter, { type TypewriterClass } from 'typewriter-effect'

import { EConnectionStatus } from '@/type/rtc'
import { useRTCStore, useChatStore } from '@/store'

export function GreetingTypewriter() {
  const { agentStatus, remote_rtc_uid } = useRTCStore()
  const { history } = useChatStore()

  const typewriterRef = React.useRef<TypewriterClass>(null)

  const tAgentGreeting = useTranslations('agent.greeting')

  const isUserSubtitleExistMemo = history.some(
    (item) => item.uid === remote_rtc_uid
  )

  React.useEffect(() => {
    if (!typewriterRef.current) {
      return
    }
    if (agentStatus === EConnectionStatus.CONNECTING) {
      typewriterRef.current
        .deleteAll(1)
        .typeString(tAgentGreeting('hi'))
        .start()
        .pauseFor(1000)
        .typeString(tAgentGreeting('connecting'))
      return
    }
    if (agentStatus === EConnectionStatus.CONNECTED) {
      typewriterRef.current
        .deleteAll(1)
        .typeString(tAgentGreeting('hi'))
        .start()
        .pauseFor(1000)
        .typeString(tAgentGreeting('connected'))
        .pauseFor(1000)
        .deleteAll(1)
        .typeString(tAgentGreeting('speakLoudly'))
        .pauseFor(3000)
        .deleteAll(1)
        .typeString(tAgentGreeting('hi'))
        .typeString(tAgentGreeting('connected'))
      return
    }
    if (agentStatus === EConnectionStatus.ERROR) {
      typewriterRef.current
        .deleteAll(1)
        .typeString(tAgentGreeting('hi'))
        .start()
        .pauseFor(1000)
        .typeString(tAgentGreeting('failed'))
    }
    if (
      agentStatus === EConnectionStatus.UNKNOWN ||
      agentStatus === EConnectionStatus.DISCONNECTED
    ) {
      typewriterRef.current
        .deleteAll(1)
        .typeString(tAgentGreeting('hi'))
        .start()
        .pauseFor(1000)
        .typeString(tAgentGreeting('human'))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [agentStatus])

  if (isUserSubtitleExistMemo && agentStatus === EConnectionStatus.CONNECTED) {
    return null
  }

  return (
    <>
      <Typewriter
        options={{ cursor: '' }}
        onInit={(typewriter) => {
          typewriterRef.current = typewriter
          typewriter
            .typeString(tAgentGreeting('hi'))
            .start()
            .pauseFor(1000)
            .typeString(tAgentGreeting('human'))
        }}
      />
    </>
  )
}
