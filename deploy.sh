#!/bin/bash

echo "🚀 Deploying Security Project to Kubernetes..."

# Build Docker images
echo "📦 Building Docker images..."
docker build -t security-project/frontend:latest ./frontend
docker build -t security-project/backend:latest ./backend

# Load images to minikube (if using minikube)
if command -v minikube &> /dev/null; then
    echo "📋 Loading images to minikube..."
    minikube image load security-project/frontend:latest
    minikube image load security-project/backend:latest
fi

# Apply Kubernetes manifests in order
echo "🔧 Applying Kubernetes manifests..."

kubectl apply -f k8s/01-namespace.yaml
echo "✅ Namespace created"

kubectl apply -f k8s/02-secrets.yaml
echo "✅ Secrets created"

kubectl apply -f k8s/03-configmap.yaml
echo "✅ ConfigMap created"

kubectl apply -f k8s/04-postgres.yaml
echo "✅ PostgreSQL deployed"

# Wait for postgres to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n security-project --timeout=60s

kubectl apply -f k8s/05-keycloak.yaml
echo "✅ Keycloak deployed"

# Wait for keycloak to be ready
echo "⏳ Waiting for Keycloak to be ready..."
kubectl wait --for=condition=ready pod -l app=keycloak -n security-project --timeout=120s

kubectl apply -f k8s/06-backend.yaml
echo "✅ Backend deployed"

kubectl apply -f k8s/07-frontend.yaml
echo "✅ Frontend deployed"

kubectl apply -f k8s/08-ingress.yaml
echo "✅ Ingress configured"

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "📊 Check deployment status:"
echo "kubectl get pods -n security-project"
echo ""
echo "🌐 Access the application:"
echo "Frontend: http://security-project.local (add to /etc/hosts)"
echo "Keycloak: http://security-project.local/auth"
echo "API: http://security-project.local/api"
echo ""
echo "🔧 Useful commands:"
echo "kubectl logs -f deployment/backend-deployment -n security-project"
echo "kubectl get services -n security-project"
echo "kubectl describe pod <pod-name> -n security-project"