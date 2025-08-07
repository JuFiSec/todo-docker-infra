#!/bin/bash

# Script de déploiement et gestion de l'infrastructure TODO
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

# Fonctions de log
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCÈS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[ATTENTION]${NC} $1"; }
log_error() { echo -e "${RED}[ERREUR]${NC} $1"; }

# Fonctions du script
verifier_dependances() {
    log_info "Vérification des dépendances..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé."
        exit 1
    fi
    log_success "Dépendances Docker trouvées."
}

verifier_fichier_env() {
    if [ ! -f ".env" ]; then
        log_warning "Fichier .env non trouvé. Création depuis .env.example..."
        cp .env.example .env
        log_success "Fichier .env créé."
    fi
}

construire_et_demarrer() {
    log_info "Construction des images et démarrage des services..."
    docker compose up -d --build
    log_info "Attente que les services soient opérationnels..."
    sleep 30
    verifier_sante_services
}

verifier_sante_services() {
    log_info "Vérification de la santé des services..."
    services_echec=()
    for service in app db traefik prometheus grafana; do
        if docker compose ps $service | grep -q "Up"; then
            log_success "Le service '$service' est en cours d'exécution."
        else
            log_error "Le service '$service' n'est pas en cours d'exécution."
            services_echec+=($service)
        fi
    done
    if [ ${#services_echec[@]} -eq 0 ]; then
        log_success "Tous les services principaux sont démarrés !"
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
}

afficher_logs() {
    if [ -z "$1" ]; then
        docker compose logs -f
    else
        docker compose logs -f "$1"
    fi
}

arreter_services() {
    log_info "Arrêt des services..."
    docker compose stop
    log_success "Services arrêtés."
}

nettoyer() {
    log_info "Nettoyage complet..."
    docker compose down -v --remove-orphans
    log_success "Nettoyage terminé."
}

afficher_statut() {
    log_info "Statut des services :"
    docker compose ps
}

afficher_aide() {
    echo "Usage: $0 [COMMANDE]"
    echo "Commandes:"
    echo "  start, up       - Démarrer tous les services"
    echo "  stop            - Arrêter tous les services"
    echo "  status, ps      - Afficher le statut des services"
    echo "  logs [service]  - Afficher les logs"
    echo "  test            - Lancer les tests d'intégration"
    echo "  cleanup         - Nettoyage complet"
    echo "  help            - Afficher cette aide"
}

# Logique principale
case "${1:-help}" in
    "start"|"up")
        verifier_dependances
        verifier_fichier_env
        construire_et_demarrer
        ;;
    "stop")
        arreter_services
        ;;
    "status"|"ps")
        afficher_statut
        ;;
    "logs")
        afficher_logs "$2"
        ;;
    "test")
        ./scripts/test-infrastructure.sh
        ;;
    "cleanup")
        nettoyer
        ;;
    "help"|"--help"|"-h")
        afficher_aide
        ;;
    *)
        log_error "Commande inconnue : $1"
        afficher_aide
        exit 1
        ;;
esac
