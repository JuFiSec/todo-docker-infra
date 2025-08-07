#!/usr/bin/env python3
"""
API TODO - TP Docker Compose
Auteur: FIENI Dannie Innocent Junior
Formation: MCS 26.2 Cybersécurité & Cloud Computing - IPSSI Nice
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import sys
import logging
from datetime import datetime
import time
from prometheus_flask_exporter import PrometheusMetrics 

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)
metrics = PrometheusMetrics(app) 

# Configuration de la base de données
DB_HOST = os.environ.get('POSTGRES_HOST', 'localhost')
DB_NAME = os.environ.get('POSTGRES_DB', 'todo_app')
DB_USER = os.environ.get('POSTGRES_USER', 'todo_user')
DB_PASS = os.environ.get('POSTGRES_PASSWORD', 'password')

def attendre_base_donnees(max_tentatives=30, delai=1):
    """Attend que la base de données soit disponible"""
    for tentative in range(max_tentatives):
        try:
            conn = psycopg2.connect(host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS)
            conn.close()
            logger.info("Connexion à la base de données réussie")
            return True
        except psycopg2.OperationalError as e:
            logger.warning(f"Tentative de connexion {tentative + 1}/{max_tentatives} échouée: {e}")
            if tentative == max_tentatives - 1:
                logger.error("Impossible de se connecter à la base après le nombre maximum de tentatives")
                return False
            time.sleep(delai)
    return False

def obtenir_connexion_db():
    """Établit une connexion à la base de données"""
    try:
        conn = psycopg2.connect(host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS, cursor_factory=RealDictCursor)
        return conn
    except Exception as e:
        logger.error(f"Erreur de connexion à la base: {e}")
        raise

@app.route('/health', methods=['GET'])
def verifier_sante():
    """Endpoint de vérification de santé de l'application"""
    try:
        conn = obtenir_connexion_db()
        cur = conn.cursor()
        cur.execute("SELECT 1")
        cur.close()
        conn.close()
        
        return jsonify({
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "database": "connected",
            "service": "API TODO",
            "version": "1.0.0"
        }), 200
    except Exception as e:
        logger.error(f"Vérification de santé échouée: {e}")
        return jsonify({
            "status": "unhealthy",
            "timestamp": datetime.now().isoformat(),
            "database": "disconnected",
            "error": str(e)
        }), 503

@app.route('/api/tasks', methods=['GET'])
def obtenir_taches():
    """Récupère toutes les tâches"""
    try:
        conn = obtenir_connexion_db()
        cur = conn.cursor()
        cur.execute("SELECT id, title, description, completed, created_at, updated_at FROM tasks ORDER BY created_at DESC")
        
        taches = []
        for row in cur.fetchall():
            taches.append({
                "id": row['id'],
                "title": row['title'],
                "description": row['description'],
                "completed": row['completed'],
                "created_at": row['created_at'].isoformat() if row['created_at'] else None,
                "updated_at": row['updated_at'].isoformat() if row['updated_at'] else None
            })
        
        cur.close()
        conn.close()
        
        logger.info(f"Récupération de {len(taches)} tâches")
        return jsonify({"tasks": taches, "count": len(taches), "timestamp": datetime.now().isoformat()}), 200
        
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des tâches: {e}")
        return jsonify({"error": "Erreur interne du serveur", "details": str(e)}), 500

@app.route('/api/tasks', methods=['POST'])
def creer_tache():
    """Crée une nouvelle tâche"""
    try:
        donnees = request.get_json()
        
        if not donnees or 'title' not in donnees or not donnees['title'].strip():
            return jsonify({"error": "Le titre est requis et ne peut être vide"}), 400
            
        titre = donnees['title'].strip()
        description = donnees.get('description', '').strip()
        
        conn = obtenir_connexion_db()
        cur = conn.cursor()
        cur.execute("INSERT INTO tasks (title, description) VALUES (%s, %s) RETURNING id, title, description, completed, created_at, updated_at", (titre, description))
        
        tache = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        resultat = {
            "id": tache['id'],
            "title": tache['title'],
            "description": tache['description'],
            "completed": tache['completed'],
            "created_at": tache['created_at'].isoformat(),
            "updated_at": tache['updated_at'].isoformat(),
            "message": "Tâche créée avec succès"
        }
        
        logger.info(f"Tâche créée {tache['id']}: {tache['title']}")
        return jsonify(resultat), 201
        
    except Exception as e:
        logger.error(f"Erreur lors de la création de la tâche: {e}")
        return jsonify({"error": "Erreur interne du serveur", "details": str(e)}), 500

@app.route('/api/stats', methods=['GET'])
def obtenir_statistiques():
    """Récupère les statistiques des tâches"""
    try:
        conn = obtenir_connexion_db()
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE completed = true) as completed, COUNT(*) FILTER (WHERE completed = false) as pending FROM tasks")
        
        stats = cur.fetchone()
        cur.close()
        conn.close()
        
        resultat = {
            "total_tasks": stats['total'],
            "completed_tasks": stats['completed'], 
            "pending_tasks": stats['pending'],
            "completion_rate": round((stats['completed'] / stats['total'] * 100) if stats['total'] > 0 else 0, 2),
            "timestamp": datetime.now().isoformat()
        }
        
        return jsonify(resultat), 200
        
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des statistiques: {e}")
        return jsonify({"error": "Erreur interne du serveur", "details": str(e)}), 500

if __name__ == '__main__':
    logger.info("Démarrage de l'API TODO...")
    
    if not attendre_base_donnees():
        logger.error("Échec de connexion à la base. Arrêt.")
        sys.exit(1)
        
    logger.info("Démarrage de l'application Flask...")
    app.run(host='0.0.0.0', port=5000, debug=False)