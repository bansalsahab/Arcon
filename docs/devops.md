# DevOps Walkthrough: Docker, K8s & Jenkins

## Infrastructure Overview
We have containerized the Arcon application and established the foundation for a GitOps CI/CD pipeline.

### Components
1.  **Dockerization**:
    - `backend/Dockerfile`: Gunicorn-based Flask production image.
    - `frontend/Dockerfile`: Multi-stage build (Flutter build -> Nginx serve).
    - `docker-compose.yml`: Local development orchestration.

2.  **Kubernetes Manifests (`k8s/`)**:
    - `backend-deployment.yaml`: Replicas, Services, Liveness Probes.
    - `frontend-deployment.yaml`: Nginx frontend deployment.
    - `ingress.yaml`: Routing logic.
    - `argocd-app.yaml`: Application definition for ArgoCD.

3.  **CI/CD**:
    - `Jenkinsfile`: Defines the Build -> Release -> Update Manifests pipeline.

## How to Run Locally (Docker Compose)
Use this to verify the containers on your machine quickly.

1.  **Stop existing services**:
    Ensure ports `5000` (Backend) and `80` (Frontend) are free. Stop your current python/flutter runs.

2.  **Build and Run**:
    ```bash
    docker-compose up --build
    ```

3.  **Access**:
    - Frontend: http://localhost
    - Backend API: http://localhost:5000/api/health

## How to Deploy (Kubernetes)
*Assuming you have Minikube or a Cluster connection.*

1.  **Apply Manifests**:
    ```bash
    kubectl apply -f k8s/
    ```

2.  **Check Status**:
    ```bash
    kubectl get pods
    kubectl get services
    ```

## CI/CD Workflow
1.  Commit code to `main`.
2.  Jenkins triggers (via Webhook):
    - Builds new Docker images.
    - Pushes to Docker Registry.
    - Updates image tags in `k8s/*.yaml`.
    - Commits changes back to Git.
3.  ArgoCD detects Git change and syncs the cluster state automatically.
