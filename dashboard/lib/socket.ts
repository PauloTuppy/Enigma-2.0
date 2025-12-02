import { Socket } from 'phoenix'

let socket: Socket | null = null

export function getSocket(): Socket {
  if (typeof window !== 'undefined' && !socket) {
    const wsUrl = process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:4000/socket'
    socket = new Socket(wsUrl, {
      params: { token: '' },
      heartbeatIntervalMs: 30000,
    })
    socket.connect()
    socket.onOpen(() => console.log('✅ WebSocket connected'))
    socket.onClose(() => console.log('❌ WebSocket closed'))
    socket.onError((error) => console.error('❌ WebSocket error:', error))
  }
  return socket as Socket
}
