import { useFraudStore } from '@/lib/store'
import { AlertTriangle, DollarSign, Activity, ShieldCheck } from 'lucide-react'

export function KPICards() {
    const stats = useFraudStore((state) => state.stats)

    return (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div className="bg-gray-800 p-4 rounded-xl border border-gray-700">
                <div className="flex justify-between items-center">
                    <div>
                        <p className="text-gray-400 text-sm">Fraud Rate</p>
                        <p className="text-2xl font-bold text-white">
                            {stats.fraudRate.toFixed(2)}%
                        </p>
                    </div>
                    <Activity className="text-blue-400 w-8 h-8" />
                </div>
            </div>

            <div className="bg-gray-800 p-4 rounded-xl border border-gray-700">
                <div className="flex justify-between items-center">
                    <div>
                        <p className="text-gray-400 text-sm">Fraud Count</p>
                        <p className="text-2xl font-bold text-red-500">
                            {stats.fraudCount}
                        </p>
                    </div>
                    <AlertTriangle className="text-red-500 w-8 h-8" />
                </div>
            </div>

            <div className="bg-gray-800 p-4 rounded-xl border border-gray-700">
                <div className="flex justify-between items-center">
                    <div>
                        <p className="text-gray-400 text-sm">Blocked Amount</p>
                        <p className="text-2xl font-bold text-green-400">
                            R$ {stats.blockedAmount.toLocaleString('pt-BR')}
                        </p>
                    </div>
                    <DollarSign className="text-green-400 w-8 h-8" />
                </div>
            </div>

            <div className="bg-gray-800 p-4 rounded-xl border border-gray-700">
                <div className="flex justify-between items-center">
                    <div>
                        <p className="text-gray-400 text-sm">Total Transactions</p>
                        <p className="text-2xl font-bold text-white">
                            {stats.totalTransactions}
                        </p>
                    </div>
                    <ShieldCheck className="text-purple-400 w-8 h-8" />
                </div>
            </div>
        </div>
    )
}
