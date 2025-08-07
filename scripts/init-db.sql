-- Script d'initialisation de la base de données TODO (Corrigé)
-- Auteur: FIENI Dannie Innocent Junior
-- Formation: MCS 26.2 Cybersécurité & Cloud Computing - IPSSI Nice

-- Création de la table des tâches avec champs complets
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL CHECK (char_length(trim(title)) > 0),
    description TEXT DEFAULT '',
    completed BOOLEAN DEFAULT FALSE,
    priority INTEGER DEFAULT 1 CHECK (priority >= 1 AND priority <= 5),
    due_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Création des index pour améliorer les performances des requêtes
CREATE INDEX IF NOT EXISTS idx_tasks_completed ON tasks(completed);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);

-- Création de la fonction trigger pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Application du trigger à la table tasks
-- On s'assure de ne pas le créer s'il existe déjà pour éviter des erreurs au redémarrage
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'update_tasks_updated_at'
    ) THEN
        CREATE TRIGGER update_tasks_updated_at
            BEFORE UPDATE ON tasks
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END
$$;

-- Insertion de données d'exemple pour la démonstration
-- ON CONFLICT (id) DO NOTHING permet de ne pas réinsérer les données si le script est relancé
INSERT INTO tasks (id, title, description, completed, priority) VALUES 
    (1, 'Configurer Docker Compose', 'Mettre en place l''infrastructure complète avec Docker Compose', false, 5),
    (2, 'Implémenter l''API REST', 'Développer les endpoints CRUD pour la gestion des tâches', true, 4),
    (3, 'Configurer Traefik', 'Mettre en place le reverse proxy avec Traefik', false, 4),
    (4, 'Configurer Prometheus', 'Mettre en place la collecte de métriques', false, 3),
    (5, 'Configurer Grafana', 'Créer les dashboards de monitoring', false, 3),
    (6, 'Tests et documentation', 'Tester l''infrastructure et rédiger la documentation', false, 2),
    (7, 'Tâche terminée exemple', 'Exemple d''une tâche déjà terminée pour les tests', true, 1)
ON CONFLICT (id) DO NOTHING;

-- Réinitialiser la séquence pour que les nouvelles insertions ne créent pas de conflit d'ID
SELECT setval('tasks_id_seq', (SELECT MAX(id) FROM tasks));