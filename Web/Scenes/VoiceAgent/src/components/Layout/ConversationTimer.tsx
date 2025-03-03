'use client'

import * as React from 'react'
import { useTranslations } from 'next-intl'
import { motion } from 'motion/react'
import NextImage from 'next/image'

import { Dialog, DialogContent, DialogFooter } from '@/components/ui/dialog'
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip'
import { Button } from '@/components/ui/button'
import { useAgentSettingsStore, useGlobalStore } from '@/store'
import { Countdown } from '@/components/Countdown'
import { cn } from '@/lib/utils'

export const ConversationTimer = () => {
  const [showTip, setShowTip] = React.useState(true)
  const [shouldWarnTime, setShouldWarnTime] = React.useState(false)

  const t = useTranslations('conversationTimer')
  const {
    conversationDuration,
    conversationTimerEndTimestamp,
    setConversationTimerEndTimestamp,
  } = useAgentSettingsStore()
  const { setShowTimeoutDialog } = useGlobalStore()

  React.useEffect(() => {
    if (!conversationTimerEndTimestamp) return

    const checkTimeLeft = () => {
      const now = new Date().getTime()
      const timeLeft = conversationTimerEndTimestamp - now
      // less than 1 minute
      if (timeLeft < 1000 * 60) {
        console.log('[ConversationTimer] timeLeft', timeLeft)
        setShouldWarnTime(true)
      }
      const shouldShowTip = timeLeft >= conversationDuration * 1000 - 1000 * 10
      if (!showTip && shouldShowTip) {
        setShowTip(true)
      } else if (showTip && !shouldShowTip) {
        setShowTip(false)
      }
    }

    const interval = setInterval(checkTimeLeft, 1000)
    checkTimeLeft() // Check immediately on mount

    return () => clearInterval(interval)
  }, [conversationDuration, conversationTimerEndTimestamp, showTip])

  return (
    <>
      {conversationTimerEndTimestamp && (
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger>
              <Countdown
                endTimestamp={conversationTimerEndTimestamp}
                className={cn(shouldWarnTime && 'ag-warn-time-pulse')}
                postComplete={() => {
                  console.log('[ConversationTimer] postComplete')
                  setShowTimeoutDialog(true)
                  setConversationTimerEndTimestamp(null)
                  if (typeof window !== 'undefined') {
                    window.dispatchEvent(new Event('stop-agent'))
                  }
                }}
              >
                {showTip && (
                  <Tip>
                    {t('tip', {
                      minutes: Math.floor(conversationDuration / 60),
                    })}
                  </Tip>
                )}
              </Countdown>
            </TooltipTrigger>
            <TooltipContent>
              <p>
                {t('tip', { minutes: Math.floor(conversationDuration / 60) })}
              </p>
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
      )}
      <TimeoutDialog />
    </>
  )
}

function Tip({ children }: { children: React.ReactNode }) {
  return (
    <motion.span
      initial={{ color: 'var(--ai_green6)' }}
      animate={{
        color: [
          'var(--ai_brand_main6)',
          'var(--ai_green6)',
          'var(--ai_brand_main6)',
          'var(--ai_green6)',
          'var(--ai_brand_main6)',
          'var(--ai_green6)',
        ],
        transition: {
          duration: 3,
          times: [0, 0.2, 0.4, 0.6, 0.8, 1],
          ease: 'linear',
        },
      }}
    >
      {children}
    </motion.span>
  )
}

function TimeoutDialog() {
  const { showTimeoutDialog, setShowTimeoutDialog } = useGlobalStore()
  const { conversationDuration } = useAgentSettingsStore()
  const t = useTranslations('conversationTimer')

  return (
    <Dialog open={showTimeoutDialog} onOpenChange={setShowTimeoutDialog}>
      <DialogContent className="flex flex-col items-center gap-4 pt-0 text-center sm:max-w-[280px]">
        <NextImage
          src="/img/sandglass-20250222.png"
          alt="sandglass"
          width={240}
          height={140}
          className="h-auto w-full"
        />
        <p className="text-center text-sm font-semibold">{t('title')}</p>
        <p className="text-center text-sm">
          {t('description', { minutes: Math.floor(conversationDuration / 60) })}
        </p>
        <DialogFooter className="w-full">
          <Button
            className="w-full bg-brand-main hover:bg-brand-main-7"
            onClick={() => {
              setShowTimeoutDialog(false)
            }}
          >
            {t('button')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
