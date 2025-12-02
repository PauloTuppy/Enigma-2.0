# ENIGMA Project

ENIGMA is a comprehensive system designed for real-time fraud detection, featuring a robust backend, an interactive dashboard, and an advanced data processing pipeline.

## Table of Contents
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Technologies Used](#technologies-used)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Setup](#setup)
  - [Running the Project](#running-the-project)
- [Project Structure](#project-structure)
- [Further Documentation](#further-documentation)

## Project Overview

The ENIGMA project aims to provide a scalable and efficient solution for identifying and mitigating fraudulent activities. It integrates various components to process data, detect anomalies, and present actionable insights through a user-friendly interface.

## Architecture

ENIGMA's architecture comprises several key components:
- **Backend Services:** Built with Node.js and Elixir, responsible for business logic, API endpoints, and interaction with the fraud detection system.
- **Fraud Detection System:** A dedicated component (`fraud_system`) that employs advanced algorithms to identify fraudulent patterns.
- **Dashboard (Frontend):** A React-based single-page application (`dashboard`) for visualizing fraud alerts, system metrics, and configuration.
- **Data Pipeline:** Utilizes Confluent (Kafka) for real-time data streaming and Google Vertex AI for machine learning model deployment and inference.

## Technologies Used

- **Backend:** Node.js, Elixir
- **Frontend:** React
- **Containerization:** Docker, Docker Compose
- **Data Streaming:** Confluent (Kafka)
- **Machine Learning/AI:** Google Vertex AI
- **Programming Languages:** JavaScript, Elixir, Python (for fraud system/ML aspects)

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:
- Docker and Docker Compose
- Node.js (for frontend development if not using Docker exclusively)
- Elixir (for backend development if not using Docker exclusively)
- Python and `pip` (for fraud system/ML development)

### Setup

1.  **Clone the repository:**
    ```bash
    git clone [repository-url]
    cd ENIGMA
    ```

2.  **Environment Variables:**
    Create a `.env` file in the root directory based on `docker-compose.yml` or `docker-compose.prod.yml` requirements. This file will contain sensitive information and configurations for services like database connections, API keys, etc.

3.  **Install Dependencies:**
    For the frontend (if developing outside Docker):
    ```bash
    cd dashboard
    npm install
    cd ..
    ```
    For the backend (if developing outside Docker):
    (Refer to `backend-nodejs-elixir.md` for specific instructions)

    For the fraud system (if developing outside Docker):
    ```bash
    cd fraud_system
    python -m venv .venv
    source .venv/bin/activate # On Windows, use `.venv\Scripts\activate`
    pip install -r requirements.txt # (Assuming a requirements.txt exists)
    deactivate
    cd ..
    ```

### Running the Project

To run the entire ENIGMA system using Docker Compose:

1.  **Build and start the services:**
    ```bash
    docker-compose up --build
    ```
    For production environment, use:
    ```bash
    docker-compose -f docker-compose.prod.yml up --build
    ```

2.  Access the dashboard in your web browser (usually `http://localhost:3000` or as configured in `docker-compose.yml`).

## Project Structure

- `dashboard/`: Contains the React frontend application.
- `fraud_system/`: Houses the fraud detection logic and related components.
- `reports/`: Generated reports and analytics.
- `.venv/`: Python virtual environment.
- `.git/`: Git version control.
- `.github/`: GitHub Actions and CI/CD workflows.
- `docker-compose.yml`: Docker Compose configuration for development.
- `docker-compose.prod.yml`: Docker Compose configuration for production.
- `backend-nodejs-elixir.md`: Documentation for backend setup.
- `dashboard-react-setup.md`: Documentation for React dashboard setup.
- `pipeline-confluent-vertexai.md`: Documentation for the data pipeline.

## Further Documentation

Please refer to the following documents for more detailed information:
- [Start Here (`COMECE-AQUI.md`)](COMECE-AQUI.md)
- [ENIGMA Start Here (`ENIGMA-START-HERE.md`)](ENIGMA-START-HERE.md)
- [Backend (Node.js & Elixir) Setup](backend-nodejs-elixir.md)
- [Dashboard (React) Setup](dashboard-react-setup.md)
- [Docker & GCP Deployment](docker-gcp-deployment.md)
- [ENIGMA 6-Week Roadmap](enigma-6week-roadmap.md)
- [ENIGMA Modern Framework](enigma-moderno-framework.md)
- [ENIGMA Complete Operations](enigma-operacoes-completas.md)
- [Executive Summary](executive-summary.md)
- [Fraud Dashboard Specification](fraud-dashboard-spec.md)
- [Pipeline (Confluent & Vertex AI)](pipeline-confluent-vertexai.md)
- [Quick Start Guide](quick-start.md)
- [Reference Guide](reference-guide.md)
- [Implementation Roadmap](roadmap-implementacao.md)
