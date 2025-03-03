import { create } from 'zustand'

import type {
  IMessageListItem,
} from '@/services/message'
export interface IChatStore {
  history: IMessageListItem[]
  setHistory: (
    history: IMessageListItem[]
  ) => void
  clearHistory: () => void
}

export const useChatStore = create<IChatStore>((set) => ({
  history: [],
  setHistory: (history) => set({ history }),
  clearHistory: () => set({ history: [] }),
}))
