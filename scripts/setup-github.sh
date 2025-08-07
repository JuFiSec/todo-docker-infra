#!/bin/bash

# Script de configuration du repository GitHub (Version Finale et Robuste)
# Auteur: FIENI Dannie Innocent Junior
# Formation: MCS 26.2 Cybersécurité & Cloud Computing - IPSSI Nice

set -e

# --- Configuration ---
NOM_REPO="todo-docker-infra"
NOM_UTILISATEUR_GITHUB="JuFiSec"
URL_GITHUB="https://github.com/${NOM_UTILISATEUR_GITHUB}/${NOM_REPO}.git"

# --- Couleurs ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Fonctions ---
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_succes() { echo -e "${GREEN}[SUCCÈS]${NC} $1"; }
log_attention() { echo -e "${YELLOW}[ATTENTION]${NC} $1"; }
log_erreur() { echo -e "${RED}[ERREUR]${NC} $1"; }

verifier_git() {
    if ! command -v git &> /dev/null; then
        log_erreur "Git n'est pas installé. Veuillez l'installer avant de continuer."
        exit 1
    fi
}

configurer_repo_git() {
