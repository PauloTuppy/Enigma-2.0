'use client'

import { useEffect } from 'react'
import { getSocket } from '@/lib/socket'
import { useFraudStore, FraudState } from '@/lib/store'
import { KPICards } from '@/components/KPICards'
import { TransactionList } from '@/components/TransactionList'
import { RiskChart } from '@/components/RiskChart'
import { FraudHeatmap } from '@/components/FraudHeatmap'

export default function Home() {
  const addTransaction = useFraudStore((state: FraudState) => state.addTransaction)

  useEffect(() => {
    const socket = getSocket()
    const channel = socket.channel('fraud:alerts', {})

    channel
      .join()
      .receive('ok', () => console.log('✅ Joined fraud:alerts'))
      .receive('error', (resp: any) => console.error('❌ Unable to join', resp))

    channel.on('new_batch', (payload: { frauds: any[] }) => {
      console.log('📨 New batch received:', payload)
      if (payload.frauds) {
        payload.frauds.forEach((tx: any) => addTransaction(tx))
      }
    })

    return () => {
      channel.leave()
    }
  }, [addTransaction])

  return (
    <main className="min-h-screen bg-gray-900 text-white p-8">
      <header className="mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
            ENIGMA <span className="text-gray-500 text-lg">v1.0</span>
          </h1>
          <p className="text-gray-400">Real-time Fraud Detection System</p>
        </div>
        <div className="flex gap-2">
          <span className="px-3 py-1 bg-green-900/50 text-green-400 rounded-full text-sm border border-green-800 flex items-center gap-2">
            <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
            System Online
          </span>
        </div>
      </header>

      <KPICards />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        <div className="lg:col-span-2">
          <RiskChart />
        </div>
        <div>
          <FraudHeatmap />
        </div>
      </div>

      <TransactionList />
    </main>
  )
}
