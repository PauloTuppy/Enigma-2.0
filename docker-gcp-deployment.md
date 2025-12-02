# Docker Compose + GCP Deployment Guide

## 1. LOCAL DEVELOPMENT - docker-compose.yml

```yaml
version: '3.9'

services:
  # Zookeeper (required for Kafka)
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"
    networks:
      - fraud-detection

  # Kafka Broker
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
      - "29092:29092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
    networks:
      - fraud-detection

  # Kafka UI (opcional, para visualização)
  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    depends_on:
      - kafka
    ports:
      - "8080:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:29092
      KAFKA_CLUSTERS_0_ZOOKEEPER: zookeeper:2181
    networks:
      - fraud-detection

  # Firestore Emulator (local)
  firestore-emulator:
    image: google/cloud-firestore-emulator:latest
    ports:
      - "8088:8088"
    environment:
      FIRESTORE_EMULATOR_HOST: firestore-emulator:8088
    networks:
      - fraud-detection

  # Redis (para caching + rate limiting)
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    networks:
      - fraud-detection

  # PostgreSQL (opcional, para dados estruturados)
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: fraud_detection
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - fraud-detection

  # Node.js API Gateway
  api:
    build:
      context: ./backend-api
      dockerfile: Dockerfile
    ports:
      - "3001:3001"
    environment:
      NODE_ENV: development
      PORT: 3001
      KAFKA_BROKERS: kafka:29092
      FIRESTORE_EMULATOR_HOST: firestore-emulator:8088
      REDIS_URL: redis://redis:6379
      DATABASE_URL: postgresql://dev:dev@postgres:5432/fraud_detection
      GCP_PROJECT_ID: fraud-detection-local
    depends_on:
      - kafka
      - firestore-emulator
      - redis
      - postgres
    volumes:
      - ./backend-api:/app
      - /app/node_modules
    command: npm run dev
    networks:
      - fraud-detection

  # Elixir Workers
  workers:
    build:
      context: ./fraud-workers
      dockerfile: Dockerfile
    ports:
      - "4000:4000"
    environment:
      MIX_ENV: dev
      KAFKA_BROKERS: kafka:29092
      FIRESTORE_EMULATOR_HOST: firestore-emulator:8088
      REDIS_URL: redis://redis:6379
    depends_on:
      - kafka
      - firestore-emulator
      - redis
    volumes:
      - ./fraud-workers:/app
    command: mix phx.server
    networks:
      - fraud-detection

  # React/Next.js Frontend
  frontend:
    build:
      context: ./fraud-detection-frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:3001
      NEXT_PUBLIC_SOCKET_URL: ws://localhost:3001
    depends_on:
      - api
    volumes:
      - ./fraud-detection-frontend:/app
      - /app/node_modules
    command: npm run dev
    networks:
      - fraud-detection

volumes:
  postgres_data:

networks:
  fraud-detection:
    driver: bridge
```

---

## 2. START LOCAL ENVIRONMENT

```bash
# Clone repo
git clone https://github.com/yourname/fraud-detection.git
cd fraud-detection

# Start all services
docker-compose up -d

# Check services
docker-compose ps

# View logs
docker-compose logs -f api
docker-compose logs -f workers
docker-compose logs -f frontend

# Stop all
docker-compose down
```

**Access Points:**
- Frontend: http://localhost:3000
- API: http://localhost:3001
- Kafka UI: http://localhost:8080
- Firestore Emulator: http://localhost:8088

---

## 3. GCP DEPLOYMENT

### Prerequisites
```bash
# Install gcloud CLI
curl https://sdk.cloud.google.com | bash

# Login
gcloud auth login
gcloud auth application-default login

# Create GCP project
gcloud projects create fraud-detection --name="Fraud Detection Platform"
gcloud config set project fraud-detection

# Enable APIs
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  firestore.googleapis.com \
  bigquery.googleapis.com \
  storage-api.googleapis.com \
  vertexai.googleapis.com \
  container.googleapis.com
```

### Step 1: Push Images to Container Registry

```bash
# Configure Docker auth
gcloud auth configure-docker

# Build and push API
docker build -t gcr.io/fraud-detection/api:latest ./backend-api
docker push gcr.io/fraud-detection/api:latest

# Build and push Workers
docker build -t gcr.io/fraud-detection/workers:latest ./fraud-workers
docker push gcr.io/fraud-detection/workers:latest

# Build and push Frontend
docker build -t gcr.io/fraud-detection/frontend:latest ./fraud-detection-frontend
docker push gcr.io/fraud-detection/frontend:latest
```

### Step 2: Deploy API Gateway to Cloud Run

```bash
gcloud run deploy fraud-api \
  --image gcr.io/fraud-detection/api:latest \
  --platform managed \
  --region us-central1 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 3600 \
  --allow-unauthenticated \
  --set-env-vars \
    KAFKA_BROKERS=confluent-kafka-broker:9092,\
    FIRESTORE_DATABASE=projects/fraud-detection/databases/default,\
    REDIS_URL=redis://redis-instance:6379,\
    GCP_PROJECT_ID=fraud-detection \
  --service-account fraud-api-sa@fraud-detection.iam.gserviceaccount.com
```

### Step 3: Deploy Elixir Workers to Cloud Run

```bash
gcloud run deploy fraud-workers \
  --image gcr.io/fraud-detection/workers:latest \
  --platform managed \
  --region us-central1 \
  --memory 1Gi \
  --cpu 1 \
  --timeout 3600 \
  --set-env-vars \
    MIX_ENV=prod,\
    KAFKA_BROKERS=confluent-kafka-broker:9092,\
    FIRESTORE_DATABASE=projects/fraud-detection/databases/default,\
    REDIS_URL=redis://redis-instance:6379
```

### Step 4: Deploy Frontend to Cloud Run

```bash
gcloud run deploy fraud-frontend \
  --image gcr.io/fraud-detection/frontend:latest \
  --platform managed \
  --region us-central1 \
  --memory 512Mi \
  --cpu 1 \
  --allow-unauthenticated \
  --set-env-vars \
    NEXT_PUBLIC_API_URL=https://fraud-api-xxxxx.a.run.app,\
    NEXT_PUBLIC_SOCKET_URL=wss://fraud-api-xxxxx.a.run.app
```

### Step 5: Setup Managed Kafka (Confluent)

```bash
# Create Confluent cluster (GCP Marketplace)
gcloud marketplace deployments create fraud-kafka \
  --product-name confluent-cloud \
  --tier ENTERPRISE \
  --region us-central1

# Or use Pub/Sub as alternative (cheaper)
gcloud pubsub topics create bets-transactions
gcloud pubsub topics create fraud-alerts
gcloud pubsub topics create osint-leads
gcloud pubsub subscriptions create fraud-alerts-sub \
  --topic fraud-alerts \
  --push-endpoint https://fraud-api-xxxxx.a.run.app/webhooks/fraud-alert
```

### Step 6: Setup BigQuery Dataset

```bash
# Create dataset
bq mk \
  --dataset \
  --location=us \
  --description="Fraud Detection Analytics" \
  fraud_detection_analytics

# Create tables
bq mk --table \
  fraud_detection_analytics.transactions \
  transaction_id:STRING,timestamp:TIMESTAMP,bet_site:STRING,amount:FLOAT64,fraud_score:FLOAT64

bq mk --table \
  fraud_detection_analytics.operators \
  operator_id:STRING,email:STRING,ips:ARRAY<STRING>,fraud_amount:INT64,victim_count:INT64
```

### Step 7: Setup Firestore

```bash
# Create Firestore database
gcloud firestore databases create \
  --location=us-central1 \
  --type=datastore-mode

# Or for native Firestore:
gcloud firestore databases create \
  --location=us-central1 \
  --type=firestore-native
```

### Step 8: CI/CD Pipeline (Cloud Build)

Create `cloudbuild.yaml`:

```yaml
steps:
  # Build API
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/api:$SHORT_SHA', './backend-api']
  
  # Build Workers
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/workers:$SHORT_SHA', './fraud-workers']
  
  # Build Frontend
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/frontend:$SHORT_SHA', './fraud-detection-frontend']
  
  # Push images
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/api:$SHORT_SHA']
  
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/workers:$SHORT_SHA']
  
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/frontend:$SHORT_SHA']
  
  # Deploy to Cloud Run
  - name: 'gcr.io/cloud-builders/gke-deploy'
    args:
      - run
      - --filename=k8s/
      - --image=gcr.io/$PROJECT_ID/api:$SHORT_SHA
      - --location=us-central1
      - --cluster=fraud-detection-cluster

images:
  - 'gcr.io/$PROJECT_ID/api:$SHORT_SHA'
  - 'gcr.io/$PROJECT_ID/workers:$SHORT_SHA'
  - 'gcr.io/$PROJECT_ID/frontend:$SHORT_SHA'

options:
  logging: CLOUD_LOGGING_ONLY
  machineType: 'N1_HIGHCPU_8'
```

### Step 9: Connect Cloud Build to GitHub

```bash
# Connect repo
gcloud builds connect --repo-name=fraud-detection \
  --repo-owner=yourname \
  --region=us-central1

# Create trigger
gcloud builds triggers create github \
  --name=fraud-detection-deploy \
  --repo-name=fraud-detection \
  --repo-owner=yourname \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

---

## 4. MONITORING + LOGGING

```bash
# Create monitoring dashboard
gcloud monitoring dashboards create --config-from-file=- <<EOF
{
  "displayName": "Fraud Detection Platform",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "API Request Rate",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_run_revision\" metric.type=\"run.googleapis.com/request_count\""
                }
              }
            }]
          }
        }
      }
    ]
  }
}
EOF

# View logs
gcloud logging read "resource.type=cloud_run_revision" --limit 50

# Real-time logs
gcloud logging read "resource.type=cloud_run_revision" --stream
```

---

## 5. USEFUL COMMANDS

```bash
# Local development
docker-compose up -d
docker-compose logs -f api

# Kafka operations
docker exec fraud-detection_kafka_1 kafka-topics \
  --list --bootstrap-server localhost:9092

docker exec fraud-detection_kafka_1 kafka-console-consumer \
  --topic fraud-alerts \
  --bootstrap-server localhost:9092 \
  --from-beginning

# GCP
gcloud services list --enabled
gcloud run services list
gcloud compute instances list
bq ls
bq query --use_legacy_sql=false 'SELECT * FROM `fraud-detection.fraud_detection_analytics.transactions` LIMIT 10'

# Clean up
docker-compose down -v
gcloud projects delete fraud-detection
```

---

## 6. TROUBLESHOOTING

**Problem: Kafka connection refused**
```bash
docker-compose logs kafka
docker-compose restart kafka zookeeper
```

**Problem: Firestore emulator not connecting**
```bash
export FIRESTORE_EMULATOR_HOST=localhost:8088
npm test  # Should now use emulator
```

**Problem: Cloud Run deployment fails**
```bash
# Check build logs
gcloud builds log --limit=50
# Check service account permissions
gcloud projects get-iam-policy fraud-detection
```

---

## NEXT: Qual serviço você quer configurar primeiro?