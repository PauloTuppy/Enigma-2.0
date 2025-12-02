# FASE 3: Pipeline Confluent + Vertex AI - Detecção de Padrões

## 1. CONFLUENT KAFKA TOPICS

### Topic: `bets-transactions`
```properties
partitions=10  # Por região geográfica (hash do user_location)
replication-factor=3
retention.ms=604800000  # 7 dias
cleanup.policy=delete
```

**Schema (Avro):**
```json
{
  "type": "record",
  "name": "BetTransaction",
  "fields": [
    {"name": "transaction_id", "type": "string"},
    {"name": "timestamp", "type": "long"},
    {"name": "bet_site_domain", "type": "string"},
    {"name": "user_id", "type": "string"},
    {"name": "amount_brl", "type": "double"},
    {"name": "payment_method", "type": "string"},
    {"name": "error_code", "type": ["null", "string"]},
    {"name": "user_ip", "type": "string"},
    {"name": "user_location", "type": "string"},
    {"name": "device_fingerprint", "type": "string"}
  ]
}
```

### Topic: `fraud-alerts`
```properties
partitions=5
replication-factor=3
retention.ms=2592000000  # 30 dias (evidência para justiça)
cleanup.policy=delete
```

### Topic: `osint-leads`
```properties
partitions=3
replication-factor=2
retention.ms=7776000000  # 90 dias
cleanup.policy=delete
```

---

## 2. KAFKA STREAMS + FLINK PROCESSING

### Padrão 1: Detecção de Bloqueios Artificiais
```java
// Kafka Streams - Java
StreamsBuilder builder = new StreamsBuilder();

KStream<String, BetTransaction> transactions = builder.stream("bets-transactions");

// Detectar múltiplas tentativas de saque falhadas em 5 minutos
transactions
  .filter((k, v) -> v.error_code != null && v.error_code.contains("Saque"))
  .groupByKey()
  .windowedBy(TimeWindows.of(Duration.ofMinutes(5)))
  .count()
  .filter((k, count) -> count > 3)  // Mais de 3 erros em 5 min = suspeito
  .toStream()
  .map((k, v) -> {
    // Enviar para Vertex AI scoring
    return new KeyValue<>(k.key(), new FraudAlert(
      k.key(), 
      "ARTIFICIAL_WITHDRAWAL_BLOCKS", 
      0.85  // Confiança 85%
    ));
  })
  .to("fraud-alerts");
```

### Padrão 2: Detecção de Ciclos de Lavagem
```python
# Flink Python - Detecção de ciclos
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.datastream.functions import MapFunction, FilterFunction

class MoneyLaunderingCycleDetector(MapFunction):
    def map(self, transaction):
        # Dados em 24h para mesmo user
        if self.is_cycle(transaction):
            return {
                'type': 'CYCLE_DETECTED',
                'amount_total': transaction['cycle_sum'],
                'confidence': 0.92,
                'pattern': 'deposit->bet->withdrawal->repeat'
            }
        return None
    
    def is_cycle(self, txn):
        # Depósito seguido de saque em <2h = padrão de lavagem
        return (txn['pattern'] == 'DEPOSIT_THEN_WITHDRAW' and 
                txn['time_delta_minutes'] < 120)
```

### Padrão 3: Correlação de IPs + Dispositivos
```sql
-- ksqlDB Query
CREATE STREAM FRAUD_IPS AS
SELECT 
  user_ip,
  COUNT(DISTINCT bet_site_domain) as num_sites,
  COUNT(DISTINCT user_id) as num_accounts,
  SUM(amount_brl) as total_volume,
  COLLECT_LIST(DISTINCT device_fingerprint) as devices
FROM bets_transactions
WINDOW TUMBLING (SIZE 1 HOUR)
GROUP BY user_ip
HAVING COUNT(DISTINCT bet_site_domain) > 5  -- Mesmo IP em 5+ sites
EMIT CHANGES;
```

---

## 3. VERTEX AI - FRAUD RISK SCORING

### Modelo 1: AutoML Tabular (Treinamento)
```python
from google.cloud import aiplatform

# Dataset com 100k transações histórias (labeled)
dataset = aiplatform.TabularDataset.create(
    display_name="bet-fraud-training",
    gcs_source="gs://fraud-detection-bucket/training_data.csv"
)

# Features para o modelo
features = [
    "amount_brl",
    "time_since_last_transaction",
    "num_failed_attempts_24h",
    "ip_reputation_score",
    "device_entropy",
    "bet_site_age_days",
    "velocity_score"  # Transações por minuto
]

# Treinamento
job = aiplatform.AutoMLTabularTrainingJob(
    display_name="fraud-risk-model",
    optimization_prediction_type="classification",
    column_transformations=[
        {"auto": {"column_name": "fraud_label"}}
    ]
)

model = job.run(
    dataset=dataset,
    target_column="fraud_label",
    training_fraction_split=0.8,
    validation_fraction_split=0.1,
    test_fraction_split=0.1,
    model_display_name="fraud-detection-v1"
)
```

### Modelo 2: Predictions em Tempo Real
```python
from google.cloud import aiplatform

# Deploy do modelo
endpoint = model.deploy(
    machine_type="n1-standard-4",
    accelerator_type="NVIDIA_TESLA_K80"
)

# Prediction batch via Kafka
def predict_fraud_score(transaction):
    prediction = endpoint.predict(
        instances=[{
            "amount_brl": transaction['amount_brl'],
            "time_since_last_transaction": 300,
            "num_failed_attempts_24h": transaction['failed_attempts'],
            "ip_reputation_score": get_ip_reputation(transaction['user_ip']),
            "device_entropy": calculate_entropy(transaction['device_fp']),
            "bet_site_age_days": get_site_age(transaction['bet_site']),
            "velocity_score": calculate_velocity(transaction['user_id'])
        }]
    )
    
    fraud_probability = prediction.predictions[0][0]
    return {
        'transaction_id': transaction['transaction_id'],
        'fraud_score': fraud_probability,
        'risk_level': 'HIGH' if fraud_probability > 0.7 else 'MEDIUM' if fraud_probability > 0.4 else 'LOW'
    }
```

---

## 4. GEMINI API - CONTEXT & OSINT ANALYSIS

### Análise de Operadores
```python
import anthropic

client = anthropic.Anthropic(api_key="GEMINI_API_KEY")

def analyze_operator_network(operator_data):
    prompt = f"""
    Analise essa rede de operadores de fraude em apostas:
    
    Dados:
    - Operador primário: {operator_data['primary_email']}
    - IPs associados: {operator_data['ips']}
    - Domínios: {operator_data['domains']}
    - Padrão de transações: {operator_data['transaction_pattern']}
    - Valor acumulado: R$ {operator_data['total_amount']}
    - Vítimas: {operator_data['victim_count']}
    
    Determine:
    1. Força da conexão com crime organizado (score 0-10)
    2. Modus operandi específico
    3. Possível conexão com PCC/Comando Vermelho
    4. Nível de sofisticação técnica
    5. Recomendações para investigação
    """
    
    analysis = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1500,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )
    
    return {
        'operator_id': operator_data['id'],
        'gemini_analysis': analysis.content[0].text,
        'confidence': 0.92,
        'investigation_priority': 'HIGH'
    }
```

### Geração de Relatórios para Autoridades
```python
def generate_authority_report(fraud_cluster):
    """Gera PDF com evidências formatadas para PF/Ministerio Publico"""
    
    prompt = f"""
    Prepare um relatório formal para autoridades brasileiras sobre essa operação de fraude:
    
    OPERAÇÃO: {fraud_cluster['operation_name']}
    Período: {fraud_cluster['date_range']}
    Vítimas: {fraud_cluster['victim_count']}
    Valor roubado: R$ {fraud_cluster['total_stolen']}
    Suspeitos: {len(fraud_cluster['operators'])}
    
    Estruture assim:
    1. SUMÁRIO EXECUTIVO
    2. CRONOLOGIA DA OPERAÇÃO
    3. ANÁLISE TÉCNICA (servidores, domínios, infraestrutura)
    4. FLUXO DE DINHEIRO E LAVAGEM
    5. ANÁLISE DE OPERADORES
    6. CONEXÕES COM CRIME ORGANIZADO (se houver)
    7. RECOMENDAÇÕES PARA INVESTIGAÇÃO
    8. EVIDÊNCIAS COLETADAS (URLs, IPs, emails)
    
    Formato: Pronto para tribunal, com todas as evidências rastreáveis.
    """
    
    report = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=3000,
        messages=[{"role": "user", "content": prompt}]
    )
    
    # Gerar PDF
    from reportlab.lib.pagesizes import letter
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.platypus import SimpleDocTemplate, Paragraph
    
    doc = SimpleDocTemplate(f"relatorio_fraude_{fraud_cluster['operation_id']}.pdf")
    doc.build([Paragraph(report.content[0].text, getSampleStyleSheet()['Normal'])])
    
    return {
        'pdf_path': f"relatorio_fraude_{fraud_cluster['operation_id']}.pdf",
        'report_content': report.content[0].text
    }
```

---

## 5. INTEGRAÇÃO END-TO-END

### Pipeline Arquitetura

```
Kafka Source (Transações)
    ↓
Kafka Streams (Pattern Detection)
    ├→ Padrão 1: Bloqueios Artificiais
    ├→ Padrão 2: Ciclos de Lavagem  
    └→ Padrão 3: Correlação IP/Device
    ↓
Vertex AI Scoring (85ms latência)
    ↓
Gemini Analysis (Contexto + OSINT)
    ↓
Report Generation
    ├→ Dashboard (Real-time)
    ├→ Firestore (Storage)
    ├→ BigQuery (Analytics)
    └→ PDF (Autoridades)
```

### Performance Targets
- **Latência E2E**: < 500ms (transação → score → dashboard)
- **Throughput**: 10k transações/segundo
- **Disponibilidade**: 99.9% SLA
- **Retenção de Evidências**: 1 ano imutável em Cloud Storage