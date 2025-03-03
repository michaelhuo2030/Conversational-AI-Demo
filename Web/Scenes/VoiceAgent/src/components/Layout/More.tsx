'use client'

import * as React from 'react'
import { LogOutIcon, XIcon } from 'lucide-react'
import { useTranslations } from 'next-intl'
import dynamic from 'next/dynamic'
import Cookies from 'js-cookie'

import { Button } from '@/components/ui/button'
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from '@/components/ui/sheet'
import { Separator } from '@/components/ui/separator'
import {
  InfoLabel,
  InfoContent,
  InfoBlock,
  InfoItem,
  InfoItemLabel,
} from '@/components/Card/InfoCard'
import { MoreIcon } from '@/components/Icons'
import { useIsMobile } from '@/hooks/use-mobile'
import { RoomInfoBlock } from '@/components/Layout/RoomInfo'
import { useUserInfoStore, useRTCStore } from '@/store'
import { EUploadLogStatus } from '@/type/rtc'

const UploadLogButtonDynamic = dynamic(
  () => import('@/components/Button/UploadLog'),
  {
    ssr: false,
  }
)

export const More = (props: { children?: React.ReactNode }) => {
  const { children } = props
  const [isOpen, setIsOpen] = React.useState(false)

  const isMobile = useIsMobile()
  const tMore = useTranslations('moreInfo')
  const { upload_log_status } = useRTCStore()

  const handleOpenChange = (open: boolean) => {
    if (upload_log_status === EUploadLogStatus.UPLOADING) {
      return
    }
    setIsOpen(open)
  }

  if (!isMobile) {
    return <>{children}</>
  }

  return (
    <Sheet open={isOpen} onOpenChange={handleOpenChange}>
      <SheetTrigger asChild>
        <Button variant="info" size="icon" onClick={() => setIsOpen(true)}>
          <MoreIcon className="h-4 w-4" />
        </Button>
      </SheetTrigger>
      <SheetContent>
        <SheetHeader>
          <SheetTitle className="flex items-center justify-between text-sm font-semibold text-icontext">
            {tMore('title')}
            <Button
              variant="ghost"
              size="icon"
              className="rounded-full items-center justify-end ring-0 focus-visible:ring-0 hover:bg-transparent bg-transparent"
              disabled={upload_log_status === EUploadLogStatus.UPLOADING}
              onClick={() => setIsOpen(false)}
            >
              <XIcon className="h-4 w-4" />
            </Button>
          </SheetTitle>
        </SheetHeader>
        <div className="my-6 w-full space-y-6">
          <RoomInfoBlock />
          <MoreBlock />
        </div>
      </SheetContent>
    </Sheet>
  )
}

const MoreBlock = () => {
  const tMore = useTranslations('moreInfo')
  const tUserInfo = useTranslations('userInfo')
  const { clearUserInfo } = useUserInfoStore()
  const {  agent_id } =
    useRTCStore()

  const handleLogout = () => {
    clearUserInfo()
    Cookies.remove('token')
  }

  return (
    <InfoBlock>
      <InfoLabel>{tMore('title')}</InfoLabel>
      <InfoContent>
        <InfoItem>
          {agent_id && (
            <UploadLogButtonDynamic className="h-5 w-full justify-between border-none p-0" />
          )}
        </InfoItem>
        <Separator />
        <InfoItem>
          <Button
            variant="ghost"
            onClick={handleLogout}
            className="h-5 w-full justify-between border-none p-0"
          >
            <InfoItemLabel>{tUserInfo('logout')}</InfoItemLabel>
            <LogOutIcon />
          </Button>
        </InfoItem>
      </InfoContent>
    </InfoBlock>
  )
}
