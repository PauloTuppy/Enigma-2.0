'use client'

import { useFraudStore, FraudState } from '@/lib/store'
import {
    ScatterChart,
    Scatter,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
    Cell,
} from 'recharts'

export function RiskChart() {
    const transactions = useFraudStore((state: FraudState) => state.transactions)

    const data = transactions.map((tx) => ({
        x: Number(tx.amount_brl),
        y: tx.fraud_score * 100,
        status: tx.fraud_status,
        id: tx.transaction_id,
    }))

    return (
        <div className="bg-gray-800 rounded-xl border border-gray-700 p-4 h-[400px]">
            <h3 className="text-lg font-semibold text-white mb-4">Risk Analysis</h3>
            <ResponsiveContainer width="100%" height="90%">
                <ScatterChart margin={{ top: 20, right: 20, bottom: 20, left: 20 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                    <XAxis
                        type="number"
                        dataKey="x"
                        name="Amount"
                        unit="R$"
                        stroke="#9CA3AF"
                    />
                    <YAxis
                        type="number"
                        dataKey="y"
                        name="Risk Score"
                        unit="%"
                        stroke="#9CA3AF"
                    />
                    <Tooltip
                        cursor={{ strokeDasharray: '3 3' }}
                        contentStyle={{
                            backgroundColor: '#1F2937',
                            borderColor: '#374151',
                            color: '#F3F4F6',
                        }}
                    />
                    <Scatter name="Transactions" data={data} fill="#8884d8">
                        {data.map((entry: any, index: number) => (
                            <Cell
                                key={`cell-${index}`}
                                fill={
                                    entry.status === 'fraud'
                                        ? '#EF4444'
                                        : entry.status === 'review'
                                            ? '#F59E0B'
                                            : '#10B981'
                                }
                            />
                        ))}
                    </Scatter>
                </ScatterChart>
            </ResponsiveContainer>
        </div>
    )
}
