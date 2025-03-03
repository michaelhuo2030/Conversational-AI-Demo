'use client'

import * as React from 'react'
import { useTranslations, useLocale } from 'next-intl'
import { XIcon, ChevronUpIcon } from 'lucide-react'
import { type IMicrophoneAudioTrack } from 'agora-rtc-sdk-ng'

import { Button, type ButtonProps } from '@/components/ui/button'
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  StartCallIcon,
  LoadingSpinner,
  CustomSubtitleIcon,
  MicrophoneIcon,
  MicrophoneOffIcon,
  MicrophoneDisallowIcon,
} from '@/components/Icons'
import { cn } from '@/lib/utils'
import {
  EAgentRunningStatus,
  EConnectionStatus,
  EMicrophoneStatus,
  ERTCServicesEvents,
} from '@/type/rtc'
import { useMultibandTrackVolume } from '@/hooks/use-rtc'
import { getRtcService } from '@/services/rtc'
import { useRTCStore } from '@/store'

import { logger } from '@/lib/logger'

export const AgentActionStart = (
  props: ButtonProps & {
    isLoading?: boolean
  }
) => {
  const { className, isLoading, disabled, children, ...rest } = props
  const t = useTranslations('agent')
  return (
    <Button
      className={cn(
        'ag-custom-gradient-button',
        'font-inter',
        'h-[var(--ag-action-height)] w-fit px-8 [&_svg]:size-6',
        'text-lg',
        className
      )}
      disabled={disabled || isLoading}
      {...rest}
    >
      {isLoading ? <LoadingSpinner /> : <StartCallIcon />}
      {t('getStart')}
      {children}
    </Button>
  )
}

export const AgentActionSubtitle = (
  props: ButtonProps & {
    enabled?: boolean
  }
) => {
  const { enabled = false, ...rest } = props

  const locale = useLocale()

  const t = useTranslations('agent')

  return (
    <>
      <TooltipProvider>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button variant="action" size="action" {...rest}>
              <CustomSubtitleIcon
                isGradient={enabled}
                isZHCN={locale === 'zh-CN'}
              />
            </Button>
          </TooltipTrigger>
          <TooltipContent>
            <p>{enabled ? t('disableSubtitle') : t('enableSubtitle')}</p>
          </TooltipContent>
        </Tooltip>
      </TooltipProvider>
    </>
  )
}

export const AgentActionHangUp = (props: ButtonProps) => {
  const { className, ...rest } = props

  const t = useTranslations('agent')

  return (
    <>
      <TooltipProvider>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="action"
              size="action"
              className={cn('text-destructive hover:bg-brand-red', className)}
              {...rest}
            >
              <XIcon />
            </Button>
          </TooltipTrigger>
          <TooltipContent>
            <p>{t('hangUp')}</p>
          </TooltipContent>
        </Tooltip>
      </TooltipProvider>
    </>
  )
}

export const MicrophoneIconWithStatus = (
  props: React.SVGProps<SVGSVGElement> & {
    status?: EMicrophoneStatus
  }
) => {
  const { status = EMicrophoneStatus.ALLOW, className, ...rest } = props

  if (status === EMicrophoneStatus.DISALLOW) {
    return (
      <MicrophoneDisallowIcon
        className={cn('text-icontext-hover', className)}
        {...rest}
      />
    )
  }

  if (status === EMicrophoneStatus.OFF) {
    return (
      <MicrophoneOffIcon
        className={cn('text-destructive', className)}
        {...rest}
      />
    )
  }

  return <MicrophoneIcon className={className} {...rest} />
}

export const AgentActionMicrophone = (
  props: ButtonProps & {
    status?: EMicrophoneStatus
  }
) => {
  const { status = EMicrophoneStatus.ALLOW, ...rest } = props

  const t = useTranslations('agent')

  const tooltipContentMemo = React.useMemo(() => {
    if (status === EMicrophoneStatus.DISALLOW) {
      return 'tooltip-mic-current-disallow'
    }

    if (status === EMicrophoneStatus.OFF) {
      return 'tooltip-mic-current-disable'
    }

    return 'tooltip-mic-current-enable'
  }, [status])

  return (
    <>
      <TooltipProvider>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button variant="action" size="action" {...rest}>
              <MicrophoneIconWithStatus status={status} />
            </Button>
          </TooltipTrigger>
          <TooltipContent>
            <p>{t(tooltipContentMemo)}</p>
          </TooltipContent>
        </Tooltip>
      </TooltipProvider>
    </>
  )
}

export type TDeviceSelectItem = {
  label: string
  value: string
  deviceId: string
}

export const AgentActionMicSelector = (
  props: ButtonProps & {
    audioTrack?: IMicrophoneAudioTrack
  }
) => {
  const { className, audioTrack, ...rest } = props

  const t = useTranslations('agent')

  const [selectedMic, setSelectedMic] = React.useState('default')
  const [items, setItems] = React.useState<TDeviceSelectItem[]>([])
  const microphoneListRef = React.useRef<TDeviceSelectItem[]>([])

  const setMicrophoneList = async () => {
    const rtcService = getRtcService()
    const list = await rtcService.agoraRTC.getMicrophones()

    if (!list.length) {
      return
    }
    const newMicrophoneList = list.map((item) => ({
      label: item.label,
      value: item.label,
      deviceId: item.deviceId,
    }))
    setItems([...newMicrophoneList])
    microphoneListRef.current = newMicrophoneList
  }
  const setCurrentMic = React.useCallback(async () => {
    const currentTrackLabel = audioTrack?.getTrackLabel()
    const inList = microphoneListRef.current?.find(
      (item) => item.label === currentTrackLabel
    )
    if (currentTrackLabel && inList) {
      setSelectedMic(currentTrackLabel)
      return
    }
    if (microphoneListRef.current.length > 0) {
      setSelectedMic(microphoneListRef.current[0].label)
    }
  }, [audioTrack])

  const setLocalMicDevice = async () => {
    await setMicrophoneList()
    setCurrentMic()
  }

  React.useEffect(() => {
    setMicrophoneList()
    const rtcService = getRtcService()
    rtcService.on(ERTCServicesEvents.MICROPHONE_CHANGED, setLocalMicDevice)
    return () => {
      rtcService.off(ERTCServicesEvents.MICROPHONE_CHANGED, setLocalMicDevice)
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  React.useEffect(() => {
    setCurrentMic()
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [audioTrack, items])

  const onChange = async (value: string) => {
    const target = items.find((item) => item.value === value)
    if (target) {
      setSelectedMic(target.value)
      if (audioTrack) {
        await audioTrack.setDevice(target.deviceId)
      }
    }
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="action"
          size="action"
          className={cn('h-11 w-11 [&_svg]:size-4', className)}
          {...rest}
        >
          <ChevronUpIcon />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="max-w[calc(90vw)] w-fit">
        <DropdownMenuLabel>{t('switchMic')}</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuRadioGroup value={selectedMic} onValueChange={onChange}>
          {items.map((mic) => (
            <DropdownMenuRadioItem key={mic.value} value={mic.value}>
              {mic.label}
            </DropdownMenuRadioItem>
          ))}
        </DropdownMenuRadioGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

const MAX_BAR_HEIGHT = 32
const MIN_BAR_HEIGHT = 8
const BAR_WIDTH = 6
const BORDER_RADIUS = 8

export const AgentActionVolumeIndicator = (props: {
  className?: string
  frequencies?: Float32Array[]
}) => {
  const { className, frequencies = [] } = props

  const summedFrequencies = React.useMemo(() => {
    return frequencies
      .map((bandFrequencies) => {
        const sum = bandFrequencies.reduce((a, b) => a + b, 0)
        if (sum <= 0) {
          return 0
        }
        return Math.sqrt(sum / bandFrequencies.length)
      })
      .slice(-4)
  }, [frequencies])

  return (
    <div
      className={cn(
        'flex items-center justify-center gap-[6px]',
        '[&>*]:bg-icontext-hover',
        {
          ['[&>*]:bg-brand-main']: true,
        },
        className
      )}
    >
      {summedFrequencies.map((frequency, index) => {
        const style = {
          height:
            MIN_BAR_HEIGHT +
            frequency * (MAX_BAR_HEIGHT - MIN_BAR_HEIGHT) +
            'px',
          borderRadius: BORDER_RADIUS + 'px',
          width: BAR_WIDTH + 'px',
          transition:
            'background-color 0.35s ease-out, transform 0.25s ease-out',
        }

        return <span key={index} style={style} />
      })}
    </div>
  )
}

export const AgentActionAudio = (props: {
  className?: string
  audioTrack?: IMicrophoneAudioTrack
}) => {
  const { className, audioTrack } = props

  const [audioMute, setAudioMute] = React.useState(false)
  const [mediaStreamTrack, setMediaStreamTrack] =
    React.useState<MediaStreamTrack>()

  React.useEffect(() => {
    audioTrack?.on('track-updated', onAudioTrackupdated)
    if (audioTrack) {
      try {
        setMediaStreamTrack(audioTrack?.getMediaStreamTrack())
      } catch (error) {
        logger.error({ error }, 'audio track error')
      }
    }

    return () => {
      audioTrack?.off('track-updated', onAudioTrackupdated)
    }
  }, [audioTrack])

  React.useEffect(() => {
    try {
      logger.info({ audioMute }, 'audio mute')
      audioTrack?.setMuted(audioMute)
    } catch (error) {
      logger.error({ error }, 'Failed to set audio mute')
    }
  }, [audioTrack, audioMute])

  const subscribedVolumes = useMultibandTrackVolume(mediaStreamTrack, 20)

  const onAudioTrackupdated = (track: MediaStreamTrack) => {
    logger.info({ track }, 'audio track updated')
    setMediaStreamTrack(track)
  }

  const onClickMute = () => {
    setAudioMute(!audioMute)
  }

  return (
    <div
      className={cn(
        'flex w-fit items-center gap-1',
        'rounded-full bg-block',
        className
      )}
    >
      <AgentActionMicrophone
        className="bg-transparent shadow-none"
        status={
          audioTrack
            ? audioMute
              ? EMicrophoneStatus.OFF
              : EMicrophoneStatus.ALLOW
            : EMicrophoneStatus.DISALLOW
        }
        disabled={!audioTrack}
        onClick={onClickMute}
      />
      <AgentActionVolumeIndicator
        className="hidden md:flex"
        frequencies={subscribedVolumes}
      />
      <AgentActionMicSelector
        className="bg-transparent shadow-none"
        audioTrack={audioTrack}
      />
    </div>
  )
}

/** @deprecated */
export const AgentConnectionStatus = (props: {
  status?: EConnectionStatus
  className?: string
}) => {
  const { status, className } = props
  const [showReminder, setShowReminder] = React.useState(true)

  const t = useTranslations('status')
  const tAgent = useTranslations('agent')

  React.useEffect(() => {
    if (showReminder) {
      setTimeout(() => {
        setShowReminder(false)
      }, 3000)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  if (status === EConnectionStatus.ERROR) {
    return (
      <div
        className={cn(
          'inline-flex items-center justify-center gap-2 whitespace-nowrap text-sm font-medium',
          'h-fit rounded-xl border border-input bg-brand-white px-4 py-3 text-destructive shadow-sm hover:bg-brand-white',
          className
        )}
      >
        <p>{tAgent('agentAborted')}</p>
      </div>
    )
  }

  if (
    status === EConnectionStatus.CONNECTING ||
    status === EConnectionStatus.RECONNECTING
  ) {
    return (
      <div className={cn('flex w-fit items-center justify-center', className)}>
        <div className="relative z-10 flex w-full cursor-default items-center overflow-hidden rounded-full border p-[1.5px]">
          <div className="absolute inset-0 h-full w-full animate-rotate rounded-full bg-[conic-gradient(#0ea5e9_20deg,transparent_120deg)]"></div>
          <div className="relative z-20 flex w-full whitespace-nowrap rounded-full bg-background px-4 py-3 text-sm font-medium">
            {status === EConnectionStatus.CONNECTING
              ? t(EConnectionStatus.CONNECTING)
              : tAgent('tmpDisconnected')}
          </div>
        </div>
      </div>
    )
  }

  if (status === EConnectionStatus.CONNECTED && showReminder) {
    return (
      <div
        className={cn(
          'inline-flex items-center justify-center gap-2 text-sm font-medium',
          'h-fit rounded-xl border border-input bg-background px-4 py-3 text-icontext shadow-sm',
          className
        )}
      >
        <p>{tAgent('reminder.firstSpeaking')}</p>
      </div>
    )
  }

  return <div className={className} />
}

export function AgentAudioTrack(props: { audioTrack?: IMicrophoneAudioTrack }) {
  const { audioTrack } = props
  const { agentRunningStatus, updateAgentRunningStatus } = useRTCStore()
  const [volumes, setVolumes] = React.useState<number[]>([])

  React.useEffect(() => {
    if (!audioTrack) return

    logger.info({ audioTrack }, 'audio track')

    const interval = setInterval(() => {
      const volume = audioTrack.getVolumeLevel()
      setVolumes((prev) => [...prev.slice(-2), volume])
    }, 100)

    return () => clearInterval(interval)
  }, [audioTrack])

  React.useEffect(() => {
    if (volumes.length < 2) return

    const isAllZero = volumes.every((v) => v === 0)

    if (isAllZero && agentRunningStatus === EAgentRunningStatus.SPEAKING) {
      logger.info('[AgentAudioTrack] agent is speaking -> listening')
      updateAgentRunningStatus(EAgentRunningStatus.LISTENING)
      return
    }

    if (!isAllZero && agentRunningStatus === EAgentRunningStatus.LISTENING) {
      logger.info('[AgentAudioTrack] agent is listening -> speaking')
      updateAgentRunningStatus(EAgentRunningStatus.SPEAKING)
    }
  }, [volumes, agentRunningStatus, updateAgentRunningStatus])

  return null
}
