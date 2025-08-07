#!/bin/bash

# Script de test (Version ultra-simple et fiable)
set -e
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
ECHECS=0

echo "--- Démarrage des tests de l'infrastructure ---"

# Fonction de test simple
tester() {
    echo -n "Test: $1..."
    if eval "$2" > /dev/null 2>&1; then
        echo -e " ${GREEN}[RÉUSSI]${NC}"
    else
        echo -e " ${RED}[ÉCHEC]${NC}"
        ((ECHECS++))
    fi
}

# Exécution des tests
tester "Santé de l'API" "curl -f -s http://localhost:8003/health"
tester "Liste des tâches API" "curl -f -s http://localhost:8003/api/tasks"
tester "Création de tâche API" "curl -f -s -X POST -H 'Content-Type: application/json' -d '{\"title\":\"test\"}' http://localhost:8003/api/tasks"
tester "Dashboard Traefik" "curl -f -s http://localhost:8081/dashboard/"
tester "Interface Prometheus" "curl -f -s http://localhost:9090/graph"
tester "Interface Grafana" "curl -f -s http://localhost:3000/login"
tester "Connexion à la base de données" "docker compose exec -T db psql -U todo_user -d todo_app -c 'SELECT 1'"

echo "-----------------------------------------------"
if [ $ECHECS -eq 0 ]; then
    echo -e "${GREEN}✅ TOUS LES TESTS SONT RÉUSSIS !${NC}"
    exit 0
else
    echo -e "${RED}❌ $ECHECS TEST(S) ONT ÉCHOUÉ.${NC}"
    exit 1
fi
