#!/bin/bash

echo "🚀 Deploying Security Project to Kubernetes..."

# Enable buildx for multiplatform builds (dla punktów)
docker buildx create --use &> /dev/null || true

# Build Docker images with proper build args
echo "📦 Building Docker images..."

# Build backend (multiplatform dla 5 punktów dodatkowych)
echo "Building backend..."
docker buildx build --platform linux/amd64,linux/arm64 \
  -t security-project/backend:latest \
  --load ./backend

# Build frontend for localhost (POPRAWIONE!)
echo "Building frontend for localhost..."
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg REACT_APP_KEYCLOAK_URL="http://localhost:8080" \
  --build-arg REACT_APP_KEYCLOAK_REALM="bezpieczenstwo_projekt_realm" \
  --build-arg REACT_APP_KEYCLOAK_CLIENT_ID="frontend-app" \
  --build-arg REACT_APP_API_URL="http://localhost:5001" \
  -t security-project/frontend:localhost \
  --load ./frontend

# Load images to minikube (POPRAWIONE nazwy obrazów!)
if command -v minikube &> /dev/null; then
    echo "📋 Loading images to minikube..."
    minikube image load security-project/frontend:localhost
    minikube image load security-project/backend:latest
fi

# Enable ingress addon PRZED deploymentem
if command -v minikube &> /dev/null; then
    echo "🔌 Enabling minikube ingress addon..."
    minikube addons enable ingress
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
kubectl wait --for=condition=ready pod -l app=keycloak -n security-project --timeout=180s

kubectl apply -f k8s/06-backend.yaml
echo "✅ Backend deployed"

kubectl apply -f k8s/07-frontend.yaml
echo "✅ Frontend deployed"

# POPRAWIONE - ustaw poprawny obraz frontend!
kubectl set image deployment/frontend-deployment frontend=security-project/frontend:localhost -n security-project
echo "✅ Frontend image updated to localhost version"

kubectl apply -f k8s/08-ingress.yaml
echo "✅ Ingress configured"

# Dodaj HPA dla punktów
kubectl apply -f k8s/09-hpa.yaml &> /dev/null || echo "⚠️ HPA not applied (metrics-server may not be available)"
echo "✅ HPA configured (if metrics-server available)"

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "🌐 Uruchamianie port-forward dla localhost..."

# Kill previous port-forwards
pkill -f "kubectl port-forward" &> /dev/null || true

# Start port-forwards automatically
kubectl port-forward -n security-project service/frontend-service 3000:80 &> /dev/null &
kubectl port-forward -n security-project service/keycloak-service 8080:8080 &> /dev/null &
kubectl port-forward -n security-project service/backend-service 5001:5001 &> /dev/null &

# Wait for port-forwards to establish
sleep 3

echo ""
echo "✅ Port-forward uruchomiony!"
echo ""
echo "📱 Aplikacja dostępna na:"
echo "   Frontend:       http://localhost:3000"
echo "   Keycloak Admin: http://localhost:8080/admin (admin/admin)"
echo "   Backend API:    http://localhost:5001"
echo ""
echo "👤 Dane logowania:"
echo "   Username: testuser"
echo "   Password: password"
echo ""
echo "🔧 Status aplikacji:"
kubectl get pods -n security-project
echo ""
echo "🛑 Aby zatrzymać: pkill -f 'kubectl port-forward'"