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
    log_info "Configuration du repository Git local..."
    if [ ! -d ".git" ]; then
        git init
        log_succes "Repository Git initialisé."
    fi
    if [ -f ".env" ] && ! grep -q "^\.env$" .gitignore 2>/dev/null; then
        echo -e "\n# Fichiers d'environnement locaux\n.env" >> .gitignore
        log_succes "Le fichier .env a été ajouté à .gitignore."
    fi
}

configurer_remote() {
    log_info "Configuration du remote GitHub..."
    if git remote | grep -q "origin"; then
        git remote set-url origin "$URL_GITHUB"
        log_info "L'URL du remote 'origin' a été mise à jour."
    else
        git remote add origin "$URL_GITHUB"
        log_succes "Le remote 'origin' a été ajouté."
    fi
}

creer_workflow_github() {
    log_info "Création du workflow GitHub Actions (CI/CD)..."
    mkdir -p .github/workflows
    
    cat > .github/workflows/ci.yml << 'EOF'
name: Test et Validation de l'Infrastructure

on:
  push:
    branches: [ "main", "master" ]
  pull_request:
    branches: [ "main", "master" ]

jobs:
  test-infrastructure:
    name: Test Fonctionnel de l'Infrastructure
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout du code
      uses: actions/checkout@v4
      
    - name: Création du fichier .env à partir de l'exemple
      run: cp .env.example .env
        
    - name: Démarrage de l'infrastructure Docker
      run: docker compose up -d --build
      
    - name: Attente active de la disponibilité de l'API
      run: |
        echo "Attente de l'endpoint /health (max 2 minutes)..."
        timeout 120s bash -c 'until curl -s --fail http://localhost:8003/health; do echo "En attente..."; sleep 5; done'
        
    - name: Exécution des tests d'intégration
      run: |
        chmod +x scripts/test-infrastructure.sh
        ./scripts/test-infrastructure.sh
        
    - name: Affichage du statut des services en cas de succès
      if: success()
      run: docker compose ps

    - name: Affichage des logs en cas d'échec
      if: failure()
      run: docker compose logs

  scan-securite:
    name: Scan de Sécurité des Vulnérabilités
    runs-on: ubuntu-latest
    needs: test-infrastructure
    
    steps:
    - name: Checkout du code
      uses: actions/checkout@v4
      
    - name: Exécution du scanner de vulnérabilités Trivy
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
        ignore-unfixed: true
        severity: 'CRITICAL,HIGH'

    - name: Upload des résultats Trivy vers GitHub Security
      uses: github/codeql-action/upload-sarif@v3
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'
EOF
    log_succes "Workflow GitHub Actions (.github/workflows/ci.yml) créé."
}

creer_fichiers_github() {
    log_info "Création des fichiers de la communauté (LICENSE, CONTRIBUTING.md)..."
    
    cat > CONTRIBUTING.md << 'EOF'
# Guide de Contribution

Ce projet est un travail pédagogique. Les contributions visant à améliorer les bonnes pratiques sont les bienvenues.

1. Forkez le repository.
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/amelioration`).
3. Committez vos changements (`git commit -m 'feat: Ajout de mon amélioration'`).
4. Pushez vers la branche (`git push origin feature/amelioration`).
5. Ouvrez une Pull Request.
EOF

    cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2025 FIENI Dannie Innocent Junior

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
    log_succes "Fichiers CONTRIBUTING.md et LICENSE créés."
}

pousser_vers_github() {
    log_info "Préparation du commit final et poussée vers GitHub..."
    
    git add .
    
    if git diff --staged --quiet; then
        log_info "Aucun nouveau changement à committer."
    else
        git commit -m "feat: Finalisation du projet et ajout de la configuration GitHub"
        log_succes "Changements finaux committés."
    fi
    
    branche_actuelle=$(git branch --show-current)
    if [ -z "$branche_actuelle" ]; then
        branche_actuelle="main"
    fi
    
    log_info "Poussée du code vers la branche '$branche_actuelle' sur GitHub..."
    if git push -u origin "$branche_actuelle"; then
        log_succes "Code poussé avec succès vers ${URL_GITHUB}"
    else
        log_erreur "Le push automatique a échoué. Veuillez vérifier votre connexion et vos identifiants Git, puis poussez manuellement."
    fi
}

# --- Fonction Principale ---
main() {
    log_info "Démarrage de la configuration finale du projet pour GitHub..."
    echo "------------------------------------------------------------"
    
    verifier_git
    configurer_repo_git
    configurer_remote
    creer_workflow_github
    creer_fichiers_github
    pousser_vers_github
    
    echo "------------------------------------------------------------"
    log_succes "Configuration du projet pour GitHub terminée !"
}

# --- Exécution ---
if [ ! -f "docker-compose.yml" ]; then
    log_erreur "Ce script doit être exécuté depuis la racine de votre projet."
    exit 1
fi

main
