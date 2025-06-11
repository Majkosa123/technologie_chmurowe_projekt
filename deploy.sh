#!/bin/bash

echo "🚀 Deploying Security Project to Kubernetes..."

# utworzenie nowego builder context z multiplatform
docker buildx create --use &> /dev/null || true

#budowanie obrazow docker z odpowiednimi argumentami
echo "📦 Building Docker images..."

# Budowanie backendu
echo "Building backend..."
docker buildx build --platform linux/amd64,linux/arm64 \
  -t security-project/backend:latest \
  --load ./backend

# budowanie backendu dla localhost
echo "Building frontend for localhost..."
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg REACT_APP_KEYCLOAK_URL="http://localhost:8080" \
  --build-arg REACT_APP_KEYCLOAK_REALM="bezpieczenstwo_projekt_realm" \
  --build-arg REACT_APP_KEYCLOAK_CLIENT_ID="frontend-app" \
  --build-arg REACT_APP_API_URL="http://localhost:5001" \
  -t security-project/frontend:localhost \
  --load ./frontend


#ładowanie obrazów do minikube
if command -v minikube &> /dev/null; then
    echo "📋 Loading images to minikube..."
    minikube image load security-project/frontend:localhost
    minikube image load security-project/backend:latest
fi

#  ingress addon PRZED deploymentem
if command -v minikube &> /dev/null; then
    echo "🔌 Enabling minikube ingress addon..."
    minikube addons enable ingress
fi

#manifesty kubernetes w kolejnosci 
echo "🔧 Applying Kubernetes manifests..."

kubectl apply -f k8s/01-namespace.yaml
echo "✅ Namespace created"

kubectl apply -f k8s/02-secrets.yaml
echo "✅ Secrets created"

kubectl apply -f k8s/03-configmap.yaml
echo "✅ ConfigMap created"

kubectl apply -f k8s/04-postgres.yaml
echo "✅ PostgreSQL deployed"

# czekam na postgre 
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n security-project --timeout=60s

kubectl apply -f k8s/05-keycloak.yaml
echo "✅ Keycloak deployed"

# czekam na keycloack
echo "⏳ Waiting for Keycloak to be ready..."
kubectl wait --for=condition=ready pod -l app=keycloak -n security-project --timeout=180s

kubectl apply -f k8s/06-backend.yaml
echo "✅ Backend deployed"

kubectl apply -f k8s/07-frontend.yaml
echo "✅ Frontend deployed"

# poprawny obraz frontend
kubectl set image deployment/frontend-deployment frontend=security-project/frontend:localhost -n security-project
echo "✅ Frontend image updated to localhost version"

kubectl apply -f k8s/08-ingress.yaml
echo "✅ Ingress configured"


kubectl apply -f k8s/09-hpa.yaml &> /dev/null || echo "⚠️ HPA not applied (metrics-server may not be available)"
echo "✅ HPA configured (if metrics-server available)"

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "🌐 Uruchamianie port-forward dla localhost..."

# Kill previous port-forwards
pkill -f "kubectl port-forward" &> /dev/null || true

# Start port-forwards automatycznie
kubectl port-forward -n security-project service/frontend-service 3000:80 &> /dev/null &
kubectl port-forward -n security-project service/keycloak-service 8080:8080 &> /dev/null &
kubectl port-forward -n security-project service/backend-service 5001:5001 &> /dev/null &

# czekaj na port-forwards 
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
echo "   Username: user"
echo "   Password: haslo"
echo ""
echo "🔧 Status aplikacji:"
kubectl get pods -n security-project
echo ""
echo "🛑 Aby zatrzymać: pkill -f 'kubectl port-forward'"