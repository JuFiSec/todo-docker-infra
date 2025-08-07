#!/bin/bash

# Script de déploiement et gestion
# Auteur: FIENI Dannie Innocent Junior
# Formation: MCS 26.2 Cybersécurité & Cloud Computing - IPSSI Nice

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration du projet
PROJECT_NAME="todo-docker-infra"
DOCKER_COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

# Fonctions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCÈS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERREUR]${NC} $1"
}

verifier_dependances() {
    log_info "Vérification des dépendances..."
    if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null || ! command -v curl &> /dev/null; then
        log_error "Docker, Docker Compose ou curl n'est pas installé."
        exit 1
    fi
    log_success "Toutes les dépendances sont installées."
}

verifier_fichier_env() {
    if [ ! -f "$ENV_FILE" ]; then
        log_warning "Fichier .env non trouvé. Création depuis .env.example..."
        cp .env.example .env
        log_success "Fichier .env créé."
    fi
}

construire_et_demarrer() {
    log_info "Construction et démarrage des services..."
    docker-compose -f $DOCKER_COMPOSE_FILE --project-name $PROJECT_NAME up -d --build
    log_info "Attente que les services soient opérationnels (peut prendre une minute)..."
    sleep 30
    verifier_sante_services
}

verifier_sante_services() {
    log_info "Vérification de la santé des services..."
    services_echec=()
    for service in app db traefik prometheus grafana postgres_exporter node_exporter; do
        if docker-compose -f $DOCKER_COMPOSE_FILE --project-name $PROJECT_NAME ps $service | grep -q "Up"; then
            log_success "$service est en cours d'exécution."
        else
            log_error "$service n'est pas en cours d'exécution."
            services_echec+=($service)
        fi
    done
    if [ ${#services_echec[@]} -eq 0 ]; then
        log_success "Tous les services sont en cours d'exécution !"
        afficher_urls
    else
        log_error "Certains services ont échoué: ${services_echec[*]}"
        exit 1
    fi
}

afficher_urls() {
    log_info "Les services sont maintenant accessibles aux URLs suivantes :"
    echo ""
    echo -e "${YELLOW}--- Interfaces Principales ---${NC}"
    echo -e "API TODO List :        ${CYAN}http://localhost:8003/api/tasks${NC}"
    echo -e "Dashboard Grafana :      ${CYAN}http://localhost:3000${NC} (Identifiants: admin / admin_securise_2025)"
    echo -e "Dashboard Traefik :      ${CYAN}http://localhost:8081${NC}"
    echo ""
    echo -e "${YELLOW}--- Interfaces de Monitoring & Débogage ---${NC}"
    echo -e "Interface Prometheus :   ${CYAN}http://localhost:9090${NC}"
}

tester_api() {
    log_info "Test des endpoints API..."
    if curl -f -s http://localhost:8003/health > /dev/null; then
        log_success "L'endpoint de santé (/health) fonctionne."
    else
        log_error "L'endpoint de santé (/health) ne répond pas."
        return 1
    fi
    if curl -f -s -X POST -H "Content-Type: application/json" -d '{"title":"Test"}' http://localhost:8003/api/tasks > /dev/null; then
        log_success "POST /api/tasks fonctionne."
    else
        log_error "POST /api/tasks ne fonctionne pas."
        return 1
    fi
    log_success "Tous les tests API sont réussis !"
}

afficher_logs() {
    if [ -z "$1" ]; then
        docker-compose logs -f
    else
        docker-compose logs -f "$1"
    fi
}

arreter_services() {
    log_info "Arrêt des services..."
    docker-compose stop
    log_success "Services arrêtés."
}

nettoyer() {
    log_info "Nettoyage complet..."
    docker-compose down -v --remove-orphans
    log_success "Nettoyage terminé."
}

afficher_statut() {
    log_info "Statut des services :"
    docker-compose ps
}

sauvegarder_donnees() {
    log_info "Création de la sauvegarde..."
    # ... (fonction de sauvegarde)
}

afficher_aide() {
    echo "Script de gestion de l'infrastructure Docker TODO"
    echo "Usage: $0 [COMMANDE]"
    # ... (fonction d'aide)
}

# Logique principale du script
case "${1:-help}" in
    "start"|"up")
        verifier_dependances
        verifier_fichier_env
        construire_et_demarrer
        ;;
    "stop")
        arreter_services
        ;;
    "restart")
        arreter_services
        sleep 5
        construire_et_demarrer
        ;;
    "status"|"ps")
        afficher_statut
        ;;
    "logs")
        afficher_logs "$2"
        ;;
    "test")
        tester_api
        ;;
    "cleanup")
        nettoyer
        ;;
    "backup")
        sauvegarder_donnees
        ;;
    *)
        log_error "Commande inconnue : $1"
        afficher_aide
        exit 1
        ;;
esac