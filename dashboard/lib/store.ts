import { create } from 'zustand'

export interface Transaction {
    id: string
    transaction_id: string
    user_id: string
    amount_brl: number
    fraud_score: number
    fraud_status: string
    fraud_reason: string
    processed_at: string
    [key: string]: any
}

export interface FraudState {
    transactions: Transaction[]
    alerts: Transaction[]
    stats: {
        totalTransactions: number
        fraudCount: number
        fraudRate: number
        blockedAmount: number
    }
    addTransaction: (tx: Transaction) => void
    setTransactions: (txs: Transaction[]) => void
}

export const useFraudStore = create<FraudState>((set) => ({
    transactions: [],
    alerts: [],
    stats: {
        totalTransactions: 0,
        fraudCount: 0,
        fraudRate: 0,
        blockedAmount: 0,
    },
    addTransaction: (tx: Transaction) =>
        set((state: FraudState) => {
            const newTransactions = [tx, ...state.transactions].slice(0, 100) // Keep last 100
            const newAlerts =
                tx.fraud_status === 'fraud'
                    ? [tx, ...state.alerts].slice(0, 50)
                    : state.alerts

            const totalTransactions = state.stats.totalTransactions + 1
            const fraudCount =
                tx.fraud_status === 'fraud'
                    ? state.stats.fraudCount + 1
                    : state.stats.fraudCount
            const blockedAmount =
                tx.fraud_status === 'fraud'
                    ? state.stats.blockedAmount + Number(tx.amount_brl)
                    : state.stats.blockedAmount

            return {
                transactions: newTransactions,
                alerts: newAlerts,
                stats: {
                    totalTransactions,
                    fraudCount,
                    fraudRate: (fraudCount / totalTransactions) * 100,
                    blockedAmount,
                },
            }
        }),
    setTransactions: (txs: Transaction[]) => set({ transactions: txs }),
}))
