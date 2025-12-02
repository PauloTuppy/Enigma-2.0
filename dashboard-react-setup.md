# Bet Fraud Detection Platform - React/Next.js Dashboard Component

## INSTALAÇÃO E SETUP

```bash
# Create Next.js project
npx create-next-app@latest fraud-detection --typescript --tailwind

cd fraud-detection

# Instalar dependências
npm install \
  recharts \
  zustand \
  socket.io-client \
  firebase \
  "@google-cloud/vertexai" \
  zod \
  date-fns \
  react-hot-toast

# Variáveis de ambiente (.env.local)
NEXT_PUBLIC_API_URL=http://localhost:3001
NEXT_PUBLIC_SOCKET_URL=ws://localhost:3001
NEXT_PUBLIC_FIREBASE_CONFIG=...
GEMINI_API_KEY=...
GCP_PROJECT_ID=...
```

## ESTRUTURA DE PASTAS

```
src/
├── app/
│   ├── layout.tsx
│   ├── page.tsx  (Dashboard Principal)
│   └── api/
│       ├── transactions/route.ts
│       ├── fraud-score/route.ts
│       └── reports/route.ts
├── components/
│   ├── Dashboard/
│   │   ├── Header.tsx
│   │   ├── KPICards.tsx
│   │   ├── TransactionStream.tsx
│   │   ├── RiskDistribution.tsx
│   │   ├── GeographicHeatmap.tsx
│   │   ├── MoneyFlowSankey.tsx
│   │   ├── OperatorNetworkGraph.tsx
│   │   └── ActionButtons.tsx
│   ├── UI/
│   │   ├── Card.tsx
│   │   ├── Badge.tsx
│   │   └── Modal.tsx
│   └── Filters/
│       ├── DateRangeFilter.tsx
│       └── RiskFilter.tsx
├── hooks/
│   ├── useRealtimeTransactions.ts
│   ├── useFraudMetrics.ts
│   └── useWebSocket.ts
├── lib/
│   ├── firebase.ts
│   ├── gemini.ts
│   ├── vertexai.ts
│   └── types.ts
├── styles/
│   └── globals.css
└── utils/
    ├── formatters.ts
    └── validators.ts
```

## TIPOS TYPESCRIPT

```typescript
// lib/types.ts

export interface Transaction {
  id: string;
  timestamp: Date;
  betSite: string;
  userId: string;
  amountBRL: number;
  paymentMethod: 'pix' | 'credit_card' | 'bank_transfer';
  errorMessage?: string;
  userIp: string;
  userLocation: string;
  deviceFingerprint: string;
  fraudScore: number;
  riskLevel: 'LOW' | 'MEDIUM' | 'HIGH';
  detectedPatterns: string[];
  operatorId?: string;
  suspectedFaction?: string;
}

export interface FraudAlert {
  id: string;
  transactionId: string;
  alertType: 'ARTIFICIAL_WITHDRAWAL_BLOCKS' | 'CYCLE_DETECTED' | 'IP_CORRELATION' | 'VELOCITY_SPIKE';
  confidence: number;
  timestamp: Date;
  details: Record<string, any>;
}

export interface Operator {
  id: string;
  primaryEmail: string;
  associatedIps: string[];
  domains: string[];
  totalAmount: number;
  victimCount: number;
  suspectedFaction?: 'PCC' | 'COMANDO_VERMELHO' | 'UNKNOWN';
  confidenceScore: number;
}

export interface GeminiAnalysis {
  operatorId: string;
  gangConnection: number; // 0-10 score
  modusOperandi: string;
  sophisticationLevel: 'LOW' | 'MEDIUM' | 'HIGH';
  investigationPriority: 'LOW' | 'MEDIUM' | 'HIGH';
  recommendations: string[];
}

export interface DashboardMetrics {
  totalTransactions: number;
  highRiskTransactions: number;
  totalVictims: number;
  totalLaundered: number;
  operatorsIdentified: number;
  modelAccuracy: number;
}
```

## COMPONENTS PRINCIPAIS

### 1. Dashboard Layout Principal

```typescript
// app/page.tsx

'use client';

import { useEffect, useState } from 'react';
import Header from '@/components/Dashboard/Header';
import KPICards from '@/components/Dashboard/KPICards';
import TransactionStream from '@/components/Dashboard/TransactionStream';
import RiskDistribution from '@/components/Dashboard/RiskDistribution';
import GeographicHeatmap from '@/components/Dashboard/GeographicHeatmap';
import MoneyFlowSankey from '@/components/Dashboard/MoneyFlowSankey';
import OperatorNetworkGraph from '@/components/Dashboard/OperatorNetworkGraph';
import ActionButtons from '@/components/Dashboard/ActionButtons';
import { useFraudMetrics } from '@/hooks/useFraudMetrics';
import { useRealtimeTransactions } from '@/hooks/useRealtimeTransactions';

export default function Dashboard() {
  const [dateRange, setDateRange] = useState({
    start: new Date(Date.now() - 24 * 60 * 60 * 1000),
    end: new Date()
  });
  
  const metrics = useFraudMetrics(dateRange);
  const transactions = useRealtimeTransactions();

  return (
    <main className="bg-slate-900 min-h-screen p-6">
      <Header />
      
      <KPICards metrics={metrics} />
      
      <div className="grid grid-cols-3 gap-6 mt-8">
        {/* Column 1: Real-time Stream */}
        <div className="col-span-1">
          <TransactionStream transactions={transactions} />
        </div>
        
        {/* Column 2: Risk Distribution */}
        <div className="col-span-1">
          <RiskDistribution transactions={transactions} />
        </div>
        
        {/* Column 3: Geographic Heatmap */}
        <div className="col-span-1">
          <GeographicHeatmap transactions={transactions} />
        </div>
      </div>

      {/* Money Flow & Operator Network */}
      <div className="grid grid-cols-2 gap-6 mt-8">
        <MoneyFlowSankey transactions={transactions} />
        <OperatorNetworkGraph transactions={transactions} />
      </div>

      {/* Action Buttons */}
      <ActionButtons />
    </main>
  );
}
```

### 2. Real-time Transaction Stream

```typescript
// components/Dashboard/TransactionStream.tsx

'use client';

import { Transaction } from '@/lib/types';
import Badge from '@/components/UI/Badge';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';

interface Props {
  transactions: Transaction[];
}

export default function TransactionStream({ transactions }: Props) {
  const getRiskColor = (riskLevel: string) => {
    switch (riskLevel) {
      case 'HIGH':
        return 'bg-red-500/20 border-red-500/50';
      case 'MEDIUM':
        return 'bg-yellow-500/20 border-yellow-500/50';
      default:
        return 'bg-green-500/20 border-green-500/50';
    }
  };

  const getRiskBadge = (riskLevel: string) => {
    const styles = {
      HIGH: 'bg-red-900 text-red-300',
      MEDIUM: 'bg-yellow-900 text-yellow-300',
      LOW: 'bg-green-900 text-green-300'
    };
    return styles[riskLevel as keyof typeof styles] || styles.LOW;
  };

  return (
    <div className="bg-slate-800 rounded-lg border border-slate-700 p-4">
      <h3 className="text-lg font-semibold text-white mb-4">
        Real-Time Transactions
      </h3>
      
      <div className="space-y-3 max-h-96 overflow-y-auto">
        {transactions.slice(0, 20).map((txn) => (
          <div
            key={txn.id}
            className={`p-3 rounded border ${getRiskColor(txn.riskLevel)}`}
          >
            <div className="flex justify-between items-start mb-2">
              <div>
                <p className="text-sm font-mono text-teal-300">
                  {txn.id.slice(0, 12)}...
                </p>
                <p className="text-xs text-slate-400 mt-1">
                  {txn.betSite}
                </p>
              </div>
              <Badge className={getRiskBadge(txn.riskLevel)}>
                {txn.fraudScore.toFixed(2)}
              </Badge>
            </div>
            
            <div className="grid grid-cols-2 gap-2 text-xs text-slate-300">
              <span>R$ {txn.amountBRL.toFixed(2)}</span>
              <span>{txn.userLocation}</span>
              <span>{txn.paymentMethod}</span>
              <span>{format(txn.timestamp, 'HH:mm:ss')}</span>
            </div>
            
            {txn.detectedPatterns.length > 0 && (
              <div className="mt-2 flex flex-wrap gap-1">
                {txn.detectedPatterns.map((pattern) => (
                  <span
                    key={pattern}
                    className="text-xs bg-slate-700 text-slate-200 px-2 py-1 rounded"
                  >
                    {pattern}
                  </span>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
```

### 3. Action Buttons Component

```typescript
// components/Dashboard/ActionButtons.tsx

'use client';

import { useState } from 'react';
import toast from 'react-hot-toast';

export default function ActionButtons() {
  const [loading, setLoading] = useState<string | null>(null);

  const handleBlockSite = async (domain: string) => {
    setLoading('block');
    try {
      const res = await fetch('/api/block-site', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ domain })
      });
      
      if (res.ok) {
        toast.success(`${domain} adicionado à blacklist`);
      }
    } catch (error) {
      toast.error('Erro ao bloquear site');
    } finally {
      setLoading(null);
    }
  };

  const handleGenerateReport = async (operatorId: string) => {
    setLoading('report');
    try {
      const res = await fetch('/api/generate-report', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ operatorId })
      });
      
      if (res.ok) {
        const { reportUrl } = await res.json();
        window.open(reportUrl, '_blank');
        toast.success('Relatório gerado e pronto para download');
      }
    } catch (error) {
      toast.error('Erro ao gerar relatório');
    } finally {
      setLoading(null);
    }
  };

  const handleFlagOSINT = async (operatorId: string) => {
    setLoading('osint');
    try {
      const res = await fetch('/api/flag-osint', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ operatorId })
      });
      
      if (res.ok) {
        toast.success('Operador marcado para investigação OSINT');
      }
    } catch (error) {
      toast.error('Erro ao marcar para OSINT');
    } finally {
      setLoading(null);
    }
  };

  return (
    <div className="mt-8 flex gap-4">
      <button
        onClick={() => handleBlockSite('betfake.com.br')}
        disabled={loading === 'block'}
        className="px-6 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold disabled:opacity-50"
      >
        {loading === 'block' ? 'Bloqueando...' : '🚫 Block Site'}
      </button>
      
      <button
        onClick={() => handleGenerateReport('op_001')}
        disabled={loading === 'report'}
        className="px-6 py-3 bg-teal-600 hover:bg-teal-700 text-white rounded-lg font-semibold disabled:opacity-50"
      >
        {loading === 'report' ? 'Gerando...' : '📄 Generate Report'}
      </button>
      
      <button
        onClick={() => handleFlagOSINT('op_001')}
        disabled={loading === 'osint'}
        className="px-6 py-3 bg-purple-600 hover:bg-purple-700 text-white rounded-lg font-semibold disabled:opacity-50"
      >
        {loading === 'osint' ? 'Marcando...' : '🔍 Flag OSINT'}
      </button>
    </div>
  );
}
```

## HOOKS DE DADOS

### WebSocket em Tempo Real

```typescript
// hooks/useRealtimeTransactions.ts

import { useEffect, useState } from 'react';
import { io } from 'socket.io-client';
import { Transaction } from '@/lib/types';

export function useRealtimeTransactions() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);

  useEffect(() => {
    const socket = io(process.env.NEXT_PUBLIC_SOCKET_URL, {
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionDelayMax: 5000,
      reconnectionAttempts: 5
    });

    socket.on('new-transaction', (transaction: Transaction) => {
      setTransactions((prev) => [transaction, ...prev].slice(0, 100));
    });

    socket.on('fraud-alert', (alert) => {
      console.log('🚨 Fraud Alert:', alert);
    });

    return () => socket.disconnect();
  }, []);

  return transactions;
}
```

Este é o **scaffolding completo**. Próximos passos: