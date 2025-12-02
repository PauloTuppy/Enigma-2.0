import { useFraudStore, FraudState } from '@/lib/store'
import { format } from 'date-fns'
import { clsx } from 'clsx'

export function TransactionList() {
    const transactions = useFraudStore((state: FraudState) => state.transactions)

    return (
        <div className="bg-gray-800 rounded-xl border border-gray-700 overflow-hidden">
            <div className="p-4 border-b border-gray-700">
                <h3 className="text-lg font-semibold text-white">Live Transactions</h3>
            </div>
            <div className="overflow-x-auto">
                <table className="w-full text-sm text-left text-gray-400">
                    <thead className="text-xs text-gray-400 uppercase bg-gray-700/50">
                        <tr>
                            <th className="px-4 py-3">Time</th>
                            <th className="px-4 py-3">User ID</th>
                            <th className="px-4 py-3">Amount</th>
                            <th className="px-4 py-3">Score</th>
                            <th className="px-4 py-3">Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        {transactions.map((tx) => (
                            <tr
                                key={tx.transaction_id}
                                className="border-b border-gray-700 hover:bg-gray-700/50 transition-colors"
                            >
                                <td className="px-4 py-3">
                                    {tx.processed_at
                                        ? format(new Date(tx.processed_at), 'HH:mm:ss')
                                        : '-'}
                                </td>
                                <td className="px-4 py-3 font-mono">{tx.user_id}</td>
                                <td className="px-4 py-3 text-white">
                                    R$ {Number(tx.amount_brl).toFixed(2)}
                                </td>
                                <td className="px-4 py-3">
                                    <div className="w-full bg-gray-700 rounded-full h-2.5">
                                        <div
                                            className={clsx(
                                                'h-2.5 rounded-full',
                                                tx.fraud_score > 0.8
                                                    ? 'bg-red-500'
                                                    : tx.fraud_score > 0.5
                                                        ? 'bg-yellow-500'
                                                        : 'bg-green-500'
                                            )}
                                            style={{ width: `${tx.fraud_score * 100}%` }}
                                        ></div>
                                    </div>
                                </td>
                                <td className="px-4 py-3">
                                    <span
                                        className={clsx(
                                            'px-2 py-1 rounded text-xs font-medium',
                                            tx.fraud_status === 'fraud'
                                                ? 'bg-red-900/50 text-red-400 border border-red-800'
                                                : tx.fraud_status === 'review'
                                                    ? 'bg-yellow-900/50 text-yellow-400 border border-yellow-800'
                                                    : 'bg-green-900/50 text-green-400 border border-green-800'
                                        )}
                                    >
                                        {tx.fraud_status.toUpperCase()}
                                    </span>
                                </td>
                            </tr>
                        ))}
                        {transactions.length === 0 && (
                            <tr>
                                <td colSpan={5} className="px-4 py-8 text-center text-gray-500">
                                    Waiting for transactions...
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    )
}
