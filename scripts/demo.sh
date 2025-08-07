#!/bin/bash

# Script de démonstration 
set -e
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}--- Démonstration de l'API TODO ---${NC}"

echo ""
echo "--- 1. Statut de santé (/health) ---"
curl -s http://localhost:8003/health | jq .

echo ""
echo "--- 2. Liste des tâches (/api/tasks) ---"
curl -s http://localhost:8003/api/tasks | jq .

echo ""
echo "--- 3. Création d'une nouvelle tâche (POST) ---"
curl -s -X POST -H "Content-Type: application/json" \
    -d '{"title":"Démonstration finale réussie"}' \
    http://localhost:8003/api/tasks | jq .

echo ""
echo "--- 4. Statistiques des tâches (/api/stats) ---"
curl -s http://localhost:8003/api/stats | jq .

echo ""
echo -e "${CYAN}--- Démonstration terminée ---${NC}"