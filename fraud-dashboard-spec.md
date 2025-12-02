# Bet Fraud Detection Dashboard - Especificação Técnica

## Seções do Dashboard

### 1. **Real-Time Transactions Stream**
- Widget com transações chegando via WebSocket (Kafka -> Node.js -> WebSocket)
- Filtros: Por valor, bet site, tipo de erro, localização geográfica
- Cor-codificação: Verde (legítimo), Amarelo (suspeito), Vermelho (fraude confirmada)
- Paginação com 50 transações/página

### 2. **Fraud Risk Heatmap**
- Mapa geográfico do Brasil mostrando concentração de fraudes por região
- Cidades com mais vítimas destacadas
- Integração com dados de renda per capita para correlação com vulnerabilidade

### 3. **Money Laundering Patterns**
- Gráfico de Sankey: Origem → Bet Site → Operador → Destino Final
- Mostra fluxo de dinheiro e valores acumulados
- Detecta ciclos (indicador de lavagem)

### 4. **Operator Network Graph**
- Grafo de conexões entre operadores identificados
- Nós: pessoas, emails, IPs, domínios
- Arestas: força de conexão (co-ocorrência em múltiplos sites)
- Comunidades detectadas automaticamente por Gemini

### 5. **Risk Scoring Dashboard**
- Score de 0-100 para cada transação (calculado por Vertex AI)
- Distribuição em tempo real: % baixo risco, médio, alto
- Threshold customizável para alertas

### 6. **Authority Reports Queue**
- Lista de relatórios gerados e prontos para envio
- Status: Em processamento, Pronto, Enviado, Confirmado
- PDF gerado automaticamente com evidências

### 7. **Model Performance Metrics**
- Acurácia, Precisão, Recall do modelo de detecção
- Confusion matrix atualizada a cada batch
- Drift detection: monitora mudanças nos padrões de fraude

### 8. **Quick Actions**
- Botão "Block Site": adiciona domínio à blacklist em tempo real
- Botão "Flag for OSINT": dispara investigação manual
- Botão "Generate Report": cria relatório para autoridades
- Botão "Notify Users": alerta vítimas em potencial

## Dados em Tempo Real (via Confluent)

```json
{
  "transaction_id": "txn_abc123",
  "timestamp": "2025-12-01T08:35:00Z",
  "bet_site": "betfake.com.br",
  "user_id": "usr_xyz789",
  "amount": 500.00,
  "currency": "BRL",
  "payment_method": "pix",
  "error_message": "Saque limitado temporariamente",
  "user_ip": "189.45.67.89",
  "user_location": "São Paulo, SP",
  "device_fingerprint": "fp_device123",
  "fraud_score": 0.87,
  "risk_level": "HIGH",
  "detected_patterns": [
    "multiple_failed_withdrawals",
    "same_ip_multiple_accounts",
    "velocity_spike"
  ],
  "operator_id": "op_scammer001",
  "suspected_faction": "PCC_suspected"
}
```

## Stack Frontend

```
React/Next.js 14
├── TypeScript
├── Tailwind CSS + custom design system
├── Recharts (gráficos)
├── Cytoscape.js (grafo OSINT)
├── Mapbox GL (mapa geográfico)
├── Socket.io (WebSocket para real-time)
├── TanStack Query (data fetching)
└── Zod (validação)
```

## Stack Backend (Node.js API Gateway)

```javascript
Express.js
├── TypeScript
├── WebSocket para real-time updates
├── Confluent Kafka client
├── BigQuery client
├── Firestore admin SDK
├── Gemini API client
└── JWT + Rate limiting
```

## Stack Backend (Elixir Workers)

```elixir
Phoenix/Elixir
├── GenServer para processamento assíncrono
├── Kafka consumer
├── Pattern matching para regras de fraude
├── Ecto queries otimizadas
└── Task queue para relatórios
```