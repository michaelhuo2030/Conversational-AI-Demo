'use client'

import { useTranslations } from 'next-intl'
import { TriangleAlertIcon } from 'lucide-react'

import { useGlobalStore } from '@/store/global'
import { cn } from '@/lib/utils'

export const BrowserInfo = () => {
  const tCompatibility = useTranslations('compatibility')
  const { isRTCCompatible, setShowCompatibilityDialog } = useGlobalStore()

  if (isRTCCompatible) return null

  return (
    <div
      className={cn(
        'flex cursor-default items-center gap-2',
        !isRTCCompatible && 'cursor-pointer'
      )}
      onClick={() => setShowCompatibilityDialog(true)}
    >
      <TriangleAlertIcon className="h-4 w-4 text-destructive" />
      <p className="text-sm text-destructive">{tCompatibility('errorTitle')}</p>
    </div>
  )
}
