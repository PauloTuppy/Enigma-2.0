# 📚 REFERENCE GUIDE - Componentes Principais

## 1️⃣ KOMPONENTY FRONTEND (React)

### Header.tsx
```typescript
export default function Header() {
  return (
    <header className="bg-slate-900 border-b border-slate-700 p-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-white">
          🚨 Fraud Detection Platform
        </h1>
        <div className="text-sm text-slate-400">
          Real-time monitoring | {new Date().toLocaleTimeString('pt-BR')}
        </div>
      </div>
    </header>
  );
}
```

### KPICards.tsx
```typescript
interface Props {
  metrics: {
    totalTransactions: number;
    highRiskTransactions: number;
    totalVictims: number;
    totalLaundered: number;
    operatorsIdentified: number;
    modelAccuracy: number;
  };
}

export default function KPICards({ metrics }: Props) {
  const cards = [
    { label: 'Total Transactions', value: metrics.totalTransactions, color: 'teal' },
    { label: 'High Risk', value: metrics.highRiskTransactions, color: 'red' },
    { label: 'Victims', value: metrics.totalVictims, color: 'orange' },
    { label: 'Laundered', value: `R$ ${metrics.totalLaundered.toLocaleString()}`, color: 'purple' },
    { label: 'Operators', value: metrics.operatorsIdentified, color: 'blue' },
    { label: 'Accuracy', value: `${(metrics.modelAccuracy * 100).toFixed(1)}%`, color: 'green' }
  ];

  return (
    <div className="grid grid-cols-6 gap-4">
      {cards.map((card) => (
        <div key={card.label} className={`bg-${card.color}-900/30 border border-${card.color}-500/50 rounded p-4`}>
          <p className="text-xs text-slate-400 mb-2">{card.label}</p>
          <p className="text-2xl font-bold text-white">{card.value}</p>
        </div>
      ))}
    </div>
  );
}
```

---

## 2️⃣ BACKEND ENDPOINTS

### POST /api/transactions/score
Submete transação para scoring de fraude

**Request:**
```json
{
  "transaction_id": "txn_abc123",
  "user_id": "user_xyz",
  "bet_site": "betfake.com.br",
  "amount_brl": 500,
  "payment_method": "pix",
  "user_ip": "189.45.67.89",
  "user_location": "São Paulo, SP",
  "device_fingerprint": "fp_device123"
}
```

**Response:**
```json
{
  "transaction_id": "txn_abc123",
  "fraud_score": 0.87,
  "risk_level": "HIGH",
  "detected_patterns": ["velocity_spike", "withdrawal_blocks"]
}
```

### POST /api/sites/block
Bloqueia site fraudulento

**Request:**
```json
{
  "domain": "betfake.com.br",
  "reason": "FRAUD_CONFIRMED"
}
```

**Response:**
```json
{
  "success": true,
  "domain": "betfake.com.br",
  "blocked_at": "2025-12-01T08:35:00Z"
}
```

### POST /api/reports/generate
Gera relatório formal para autoridades

**Request:**
```json
{
  "operator_id": "op_scammer001",
  "report_type": "AUTHORITY_FORMAL"
}
```

**Response:**
```json
{
  "report_id": "report_1234567890",
  "status": "GENERATING",
  "eta_seconds": 120
}
```

---

## 3️⃣ KAFKA MESSAGES

### Topic: bets-transactions
```json
{
  "transaction_id": "txn_001",
  "timestamp": 1701417300000,
  "bet_site_domain": "betfake.com.br",
  "user_id": "user_123",
  "amount_brl": 500.00,
  "payment_method": "pix",
  "error_code": "WITHDRAWAL_LIMIT_EXCEEDED",
  "user_ip": "189.45.67.89",
  "user_location": "São Paulo, SP",
  "device_fingerprint": "fp_device123"
}
```

### Topic: fraud-alerts
```json
{
  "alert_id": "alert_001",
  "transaction_id": "txn_001",
  "alert_type": "ARTIFICIAL_WITHDRAWAL_BLOCKS",
  "confidence": 0.92,
  "timestamp": 1701417305000,
  "operator_id": "op_scammer001"
}
```

---

## 4️⃣ VERTEX AI FEATURES (Fraud Scoring)

```python
features = {
    "amount_brl": 500.0,
    "time_since_last_transaction": 300,
    "num_failed_attempts_24h": 5,
    "ip_reputation_score": 0.8,  # 0=good, 1=bad
    "device_entropy": 0.42,       # 0=low entropy, 1=high
    "bet_site_age_days": 180,
    "velocity_score": 0.75        # transações por minuto
}

# Output esperado:
{
    "fraud_probability": 0.87,
    "risk_level": "HIGH",
    "top_features": [
        "num_failed_attempts_24h",
        "ip_reputation_score",
        "velocity_score"
    ]
}
```

---

## 5️⃣ GEMINI PROMPTS

### Análise de Operador
```
Analise essa rede de operadores de fraude em apostas:

Dados:
- Operador primário: scammer@domain.com
- IPs associados: 189.45.67.89, 201.12.34.56
- Domínios: betfake.com.br, bettrick.com, cashwin.com
- Padrão de transações: 150-200 transações/hora
- Valor acumulado: R$ 1.2M
- Vítimas: 3421

Determine:
1. Força da conexão com crime organizado (score 0-10)
2. Modus operandi específico
3. Possível conexão com PCC/Comando Vermelho
4. Nível de sofisticação técnica (LOW/MEDIUM/HIGH)
5. Recomendações para investigação
```

---

## 6️⃣ DATABASE SCHEMAS

### Firestore Collections

**transactions**
```
/transactions/{transaction_id}
├── timestamp: Timestamp
├── betSite: String
├── userId: String
├── amountBRL: Number
├── fraudScore: Number
├── riskLevel: String (LOW|MEDIUM|HIGH)
├── patterns: Array<String>
└── operatorId: String
```

**operators**
```
/operators/{operator_id}
├── email: String
├── ips: Array<String>
├── domains: Array<String>
├── totalAmount: Number
├── victimCount: Number
├── suspectedFaction: String (PCC|CV|UNKNOWN)
├── confidenceScore: Number
└── lastUpdated: Timestamp
```

**fraud_alerts**
```
/fraud_alerts/{alert_id}
├── transactionId: String
├── alertType: String
├── confidence: Number
├── timestamp: Timestamp
├── geminiAnalysis: String
└── reportGenerated: Boolean
```

---

## 7️⃣ REGEX PATTERNS (Fraud Detection)

```javascript
// IP Reputation
const suspiciousIpPattern = /^189\.|^201\./;

// Email domains conhecido de scammers
const scamEmailPattern = /(?:gmail|hotmail|outlook).*@scam|fraud/i;

// Error messages que indicam bloqueio artificial
const artificialBlockPattern = /saque|limite|temporári|bloqueado|suspeito/i;

// Pattern de ciclo de lavagem (deposit -> bet -> withdraw)
const launderingCyclePattern = /^DEPOSIT_THEN_WITHDRAW|RAPID_CYCLE$/;

// Velocity anomaly (múltiplas transações em curto período)
const velocityAnomalyPattern = /\d+\s+(?:transactions|transações)\s+in\s+(?:minute|segundo)/i;
```

---

## 8️⃣ ELIXIR PATTERN MATCHING

```elixir
# Match gang connection by domain
defp analyze_operator(%{"domains" => domains}) do
  case Enum.any?(domains, &pcc_domain?/1) do
    true -> {:gang_connection, 92, "PCC"}
    false -> check_cv_connection(domains)
  end
end

# Match lavagem cycle
defp is_money_laundering_cycle(%{"pattern" => pattern, "time_delta_minutes" => delta}) do
  case {pattern, delta} do
    {"DEPOSIT_THEN_WITHDRAW", t} when t < 120 -> true
    _ -> false
  end
end

# Match velocity spike
defp is_velocity_spike(transactions) do
  count = Enum.count(transactions)
  case count do
    n when n > 50 -> true  # Mais de 50 transações = spike
    _ -> false
  end
end
```

---

## 9️⃣ DOCKER COMMANDS

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# View logs
docker-compose logs -f api
docker-compose logs -f workers
docker-compose logs -f frontend

# Build images
docker-compose build --no-cache

# Execute command in container
docker-compose exec api npm run build
docker-compose exec workers iex -S mix

# Remove everything
docker-compose down -v
```

---

## 🔟 GCP COMMANDS

```bash
# Project
gcloud config set project fraud-detection
gcloud projects list

# Services
gcloud services enable vertexai.googleapis.com
gcloud services list --enabled

# Deploy
gcloud run deploy fraud-api --image gcr.io/fraud-detection/api:latest
gcloud run services list

# BigQuery
bq ls
bq query --use_legacy_sql=false 'SELECT * FROM `fraud-detection.fraud_analytics.transactions`'

# Firestore
gcloud firestore databases list
gcloud firestore databases describe

# Logs
gcloud logging read "resource.type=cloud_run_revision" --limit 50
gcloud logging read "resource.type=cloud_run_revision" --stream
```

---

## 📊 TESTE DE CARGA (Load Testing)

```bash
# Instale k6
brew install k6  # macOS

# Crie script k6 (load-test.js)
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '1m', target: 100 },  // Ramp-up
    { duration: '3m', target: 1000 }, // Pico
    { duration: '1m', target: 0 },    // Ramp-down
  ]
};

export default function() {
  let payload = JSON.stringify({
    transaction_id: `txn_${Date.now()}`,
    user_id: `user_${Math.random()}`,
    bet_site: 'test.com',
    amount_brl: 500,
    user_ip: '189.45.67.89'
  });

  let res = http.post('http://localhost:3001/api/transactions/score', payload, {
    headers: { 'Content-Type': 'application/json' }
  });

  check(res, {
    'status is 200': (r) => r.status === 200,
    'fraud_score exists': (r) => r.body.includes('fraud_score')
  });

  sleep(1);
}

# Rode teste
k6 run load-test.js
```

---

## 🔗 POSTMAN COLLECTION

```json
{
  "info": { "name": "Fraud Detection API" },
  "item": [
    {
      "name": "Health Check",
      "request": {
        "method": "GET",
        "url": "http://localhost:3001/health"
      }
    },
    {
      "name": "Score Transaction",
      "request": {
        "method": "POST",
        "url": "http://localhost:3001/api/transactions/score",
        "body": {
          "mode": "raw",
          "raw": "{\"transaction_id\": \"test\", \"user_id\": \"user123\"}"
        }
      }
    },
    {
      "name": "Block Site",
      "request": {
        "method": "POST",
        "url": "http://localhost:3001/api/sites/block",
        "body": {
          "mode": "raw",
          "raw": "{\"domain\": \"betfake.com.br\"}"
        }
      }
    }
  ]
}
```

---

## 📌 QUICK REFERENCE

| Item | Command/Code |
|------|--------------|
| Start Dev | `docker-compose up -d` |
| Logs | `docker-compose logs -f api` |
| Create Topic | `kafka-topics --create --topic bets-transactions` |
| View Topic | `kafka-console-consumer --topic fraud-alerts` |
| Frontend Dev | `cd frontend && npm run dev` |
| Backend Dev | `cd backend && npm run dev` |
| Workers Dev | `cd workers && iex -S mix` |
| Deploy API | `gcloud run deploy fraud-api --image gcr.io/...` |
| Query BQ | `bq query 'SELECT * FROM fraud_analytics.transactions'` |
| Monitor | `gcloud logging read --stream` |

---

**🎯 Ready to start? Pick a section and dive in!**