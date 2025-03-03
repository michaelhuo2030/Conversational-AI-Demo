'use client'

import * as React from 'react'
import { useTranslations } from 'next-intl'
import dynamic from 'next/dynamic'

import { cn } from '@/lib/utils'
import { BrandLogo } from '@/components/Icons'
import { RoomInfo } from '@/components/Layout/RoomInfo'
import { BrowserInfo } from '@/components/Layout/BrowserInfo'
import { DevModeBadge } from '@/components/Layout/DevModeBadge'
import { NetWorkInfo } from '@/components/Layout/NetWorkInfo'
import { UserInfo } from '@/components/Layout/UserInfo'
import { ConversationTimer } from '@/components/Layout/ConversationTimer'
import { useRTCStore, useUserInfoStore } from '@/store'
import { More } from '@/components/Layout/More'
import { LoginPanel } from '@/components/Layout/LoginPanel'

const UploadLogButtonDynamic = dynamic(
  () => import('@/components/Button/UploadLog'),
  {
    ssr: false,
  }
)

export const Header = (props: { className?: string }) => {
  const { className } = props

  const t = useTranslations('homePage')
  const { accountUid } = useUserInfoStore()
  const {agent_id}=useRTCStore()

  return (
    <header
      className={cn(
        'flex h-[var(--ag-header-height)] items-center justify-between',
        className
      )}
    >
      {/* Left Side */}
      <div className="flex items-center gap-2">
        <BrandLogo className="h-7 w-7 text-brand-main" />
        <h1 className="hidden text-base font-semibold leading-none md:block">
          {t('title')}
        </h1>
        <DevModeBadge />
      </div>
      {/* Right Side */}
      <div className="flex items-center gap-2">
        {accountUid && (
          <>
            <ConversationTimer />
            <BrowserInfo />
            <NetWorkInfo />
            <More>
              <RoomInfo />
              {agent_id && <UploadLogButtonDynamic />}
            </More>
          </>
        )}
        <React.Suspense fallback={null}>
          <UserInfo />
        </React.Suspense>
      </div>
      <LoginPanel />
    </header>
  )
}
