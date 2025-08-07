#!/bin/bash

# Script de configuration complète du TP Docker Compose
# Auteur: FIENI Dannie Innocent Junior
# Formation: MCS 26.2 Cybersécurité & Cloud Computing - IPSSI Nice

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_succes() {
    echo -e "${GREEN}[SUCCÈS]${NC} $1"
}

log_attention() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

log_erreur() {
    echo -e "${RED}[ERREUR]${NC} $1"
}

log_titre() {
    echo -e "${PURPLE}[ÉTAPE]${NC} $1"
}

afficher_banniere() {
    clear
    echo "================================================================="
    echo "          TP DOCKER COMPOSE - CONFIGURATION COMPLÈTE"
    echo "================================================================="
    echo "Auteur: FIENI Dannie Innocent Junior"
    echo "Formation: MCS 26.2 Cybersécurité & Cloud Computing - IPSSI Nice"
    echo "École: IPSSI Nice"
    echo ""
    echo "Ce script va :"
    echo "1. Créer la structure complète du projet"
    echo "2. Démarrer l'infrastructure Docker"
    echo "3. Tester tous les composants"
    echo "4. Configurer le repository GitHub"
    echo "5. Générer une démonstration complète"
    echo "================================================================="
    echo ""
    read -p "Appuyez sur Entrée pour commencer..."
}

creer_structure_projet() {
    log_titre "1. CRÉATION DE LA STRUCTURE DU PROJET"
    
    # Créer les répertoires
    mkdir -p {app,traefik,prometheus,grafana/{provisioning/{datasources,dashboards},dashboards},scripts}
    log_succes "Structure des répertoires créée"
    
    # Créer le fichier .env depuis l'exemple
    if [ ! -f ".env" ]; then
        cp .env.example .env
        log_succes "Fichier .env créé depuis l'exemple"
        log_attention "Pensez à personnaliser les mots de passe dans .env"
    fi
    
    # Rendre les scripts exécutables
    chmod +x scripts/*.sh 2>/dev/null || true
    log_succes "Scripts rendus exécutables"
    
    echo ""
}

demarrer_infrastructure() {
    log_titre "2. DÉMARRAGE DE L'INFRASTRUCTURE DOCKER"
    
    log_info "Construction et démarrage des services..."
    ./scripts/deploy.sh start
    
    log_info "Attente de la stabilisation des services (30 secondes)..."
    sleep 30
    
    log_succes "Infrastructure démarrée avec succès"
    echo ""
}

executer_tests() {
    log_titre "3. EXÉCUTION DES TESTS"
    
    log_info "Lancement des tests automatisés..."
    if ./scripts/test-infrastructure.sh; then
        log_succes "Tous les tests sont passés avec succès"
    else
        log_erreur "Certains tests ont échoué"
        log_attention "Vérification des logs..."
        docker-compose ps
        exit 1
    fi
    
    echo ""
}

configurer_github() {
    log_titre "4. CONFIGURATION DU REPOSITORY GITHUB"
    
    if [ -d ".git" ]; then
        log_info "Repository Git déjà existant"
    else
        log_info "Configuration du repository GitHub..."
        ./scripts/setup-github.sh
        log_succes "Repository GitHub configuré"
    fi
    
    echo ""
}

generer_demonstration() {
    log_titre "5. GÉNÉRATION DE LA DÉMONSTRATION"
    
    log_info "Exécution de la démonstration complète..."
    ./scripts/demo.sh
    
    echo ""
}

generer_preuves_fonctionnement() {
    log_titre "6. GÉNÉRATION DES PREUVES DE FONCTIONNEMENT"
    
    # Créer un répertoire pour les preuves
    mkdir -p preuves
    
    log_info "Capture de l'état des services..."
    docker-compose ps > preuves/services-status.txt
    
    log_info "Capture des logs récents..."
    docker-compose logs --tail=50 > preuves/logs-recents.txt
    
    log_info "Test de l'API et sauvegarde des réponses..."
    curl -s http://localhost/health | jq . > preuves/api-health.json
    curl -s http://localhost/api/tasks | jq . > preuves/api-tasks.json
    curl -s http://localhost/api/stats | jq . > preuves/api-stats.json
    
    log_info "Capture des métriques Prometheus..."
    curl -s "http://localhost:9090/api/v1/targets" | jq . > preuves/prometheus-targets.json
    
    log_info "Test de Grafana..."
    curl -s http://localhost:3000/api/health | jq . > preuves/grafana-health.json
    
    log_info "Informations sur les réseaux Docker..."
    docker network ls | grep todo-docker-infra > preuves/docker-networks.txt
    
    log_info "Informations sur les volumes Docker..."
    docker volume ls | grep todo-docker-infra > preuves/docker-volumes.txt
    
    log_info "Utilisation des ressources..."
    docker stats --no-stream > preuves/resource-usage.txt
    
    # Créer un rapport de synthèse
    cat > preuves/RAPPORT-SYNTHESE.md << EOF
# Rapport de Synthèse - TP Docker Compose

**Auteur:** FIENI Dannie Innocent Junior  
**Formation:** MCS 26.2 Cybersécurité & Cloud Computing - IPSSI Nice  
**Date:** $(date)

## Statut de l'Infrastructure

L'infrastructure Docker Compose a été déployée avec succès et tous les tests sont passés.

## Services Déployés

- **Application Flask** : API REST fonctionnelle
- **PostgreSQL** : Base de données opérationnelle  
- **Traefik** : Reverse proxy configuré
- **Prometheus** : Collecte de métriques active
- **Grafana** : Dashboards de monitoring accessibles
- **Exporters** : Métriques système et base de données

## Tests Réalisés

-  Tous les services démarrent correctement
-  API REST complètement fonctionnelle (CRUD)
-  Base de données accessible et opérationnelle
-  Monitoring stack opérationnelle
-  Reverse proxy fonctionnel
-  Health checks passés
-  Réseaux Docker isolés correctement

## URLs d'Accès

- API: http://localhost/api/tasks
- Traefik: http://localhost:8081
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090

## Fichiers de Preuve

- \`services-status.txt\` : État des services Docker
- \`api-*.json\` : Réponses de l'API
- \`prometheus-targets.json\` : Targets Prometheus
- \`grafana-health.json\` : État de Grafana
- \`logs-recents.txt\` : Logs récents des services

## Conclusion

L'infrastructure est parfaitement fonctionnelle et répond à tous les objectifs du TP.
EOF
    
    log_succes "Preuves de fonctionnement générées dans le répertoire 'preuves/'"
    echo ""
}

afficher_urls_finales() {
    log_titre "7. RÉCAPITULATIF FINAL"
    
    echo ""
    echo "================================================================="
    echo "           INFRASTRUCTURE DÉPLOYÉE AVEC SUCCÈS"
    echo "================================================================="
    echo ""
    echo " Services accessibles :"
    echo "   • API TODO:         http://localhost/api/tasks"
    echo "   • Health Check:     http://localhost/health"
    echo "   • Traefik:          http://localhost:8080"
    echo "   • Grafana:          http://localhost:3000 (admin/admin_securise_2025)"
    echo "   • Prometheus:       http://localhost:9090"
    echo ""
    echo " Repository GitHub:   https://github.com/JuFiSec/todo-docker-infra"
    echo ""
    echo "  Commandes utiles :"
    echo "   • Voir les logs:     docker-compose logs [service]"
    echo "   • Arrêter:          ./scripts/deploy.sh stop"
    echo "   • Redémarrer:       ./scripts/deploy.sh restart"
    echo "   • Tester:           ./scripts/deploy.sh test"
    echo "   • Nettoyer:         ./scripts/deploy.sh cleanup"
    echo ""
    echo " Preuves générées dans le répertoire 'screenshots/'"
    echo ""
    echo "================================================================="
    echo "Auteur: FIENI Dannie Innocent Junior"
    echo "Formation: MCS 26.2 Cybersécurité & Cloud Computing - IPSSI Nice"
    echo "================================================================="
}

# Vérification des prérequis
verifier_prerequis() {
    log_info "Vérification des prérequis..."
    
    if ! command -v docker &> /dev/null; then
        log_erreur "Docker n'est pas installé"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_erreur "Docker Compose n'est pas installé"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        log_erreur "Git n'est pas installé"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log_erreur "curl n'est pas installé"
        exit 1
    fi
    
    # Installer jq si nécessaire (pour le formatage JSON)
    if ! command -v jq &> /dev/null; then
        log_attention "jq n'est pas installé, essai d'installation..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        else
            log_attention "Installation automatique de jq impossible"
        fi
    fi
    
    log_succes "Prérequis vérifiés"
    echo ""
}

# Fonction principale
main() {
    afficher_banniere
    verifier_prerequis
    creer_structure_projet
    demarrer_infrastructure
    executer_tests
    configurer_github
    generer_demonstration
    generer_preuves_fonctionnement
    afficher_urls_finales
    
    log_succes "Configuration complète terminée avec succès !"
}

# Exécution du script principal
main