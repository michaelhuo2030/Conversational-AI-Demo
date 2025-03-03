'use client'

import * as React from 'react'
import { useTranslations } from 'next-intl'
import { LogOutIcon } from 'lucide-react'
import Cookies from 'js-cookie'
import { parseAsString, useQueryState } from 'nuqs'

import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { UserIcon, DropdownIcon } from '@/components/Icons'
import { LoginPanelButton } from '@/components/Button/LoginButton'
import { useUserInfoStore } from '@/store'
import { SSO_LOGIN_ID, SSO_STATE, SSO_TOKEN } from '@/constants'
import { getUserInfo, login } from '@/services/agent'

export function UserInfo() {
  const [code] = useQueryState(SSO_TOKEN, parseAsString)

  const tUserInfo = useTranslations('userInfo')
  const {
    accountUid,
    displayName,
    clearUserInfo,
    updateUserInfo,
    updateGlobalLoading,
  } = useUserInfoStore()


  const handleLogout = () => {
    clearUserInfo()
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new Event('stop-agent'))
    }
    Cookies.remove('token')
  }

  const getSSOUserInfo = React.useCallback(async () => {
    try {
      updateGlobalLoading(true)
      let authToken = Cookies.get('token')
      if (!!accountUid) {
        return
      }
      if (code) {
        const {
          data: { token },
        } = await login(code)
        const url = new URL(window.location.href)
        url.searchParams.delete(SSO_TOKEN)
        url.searchParams.delete(SSO_LOGIN_ID)
        url.searchParams.delete(SSO_STATE)
        window.history.replaceState({}, document.title, url.toString())
        authToken = token
      }
      if (authToken) {
        const { data: userInfo } = await getUserInfo()
        if (userInfo) {
          updateUserInfo(userInfo)
        }
      }
    } catch (error) {
      console.error(error)
    } finally {
      updateGlobalLoading(false)
    }
  }, [accountUid, code, updateGlobalLoading, updateUserInfo])

  React.useEffect(() => {
    getSSOUserInfo()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  if (!accountUid) {
    return <LoginPanelButton />
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="info"
          size="icon"
          className="w-fit gap-0 p-1 [&_svg]:size-6 hidden md:inline-flex"
        >
          <UserIcon className="size-7 text-icontext" />
          <DropdownIcon className="size-7 text-icontext-hover" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="bg-background">
        <DropdownMenuLabel>{displayName}</DropdownMenuLabel>
        <DropdownMenuSeparator className="bg-border" />
        <DropdownMenuItem className="cursor-pointer" onClick={handleLogout}>
          <LogOutIcon />
          <span>{tUserInfo('logout')}</span>
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
