-- ================================================
--  SCRIPT SQL - Gestion des Congés et Absences
--  Projet de Fin d'Études | Java + JavaFX + MySQL
-- ================================================

CREATE DATABASE IF NOT EXISTS gestion_conges
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE gestion_conges;

-- ────────────────────────────────────────
-- TABLE : type_conge
-- ────────────────────────────────────────
CREATE TABLE type_conge (
  id_type        INT          NOT NULL AUTO_INCREMENT,
  libelle        VARCHAR(100) NOT NULL,
  nb_jours_annuels INT        NOT NULL DEFAULT 0,
  PRIMARY KEY (id_type)
);

-- ────────────────────────────────────────
-- TABLE : employe
-- ────────────────────────────────────────
CREATE TABLE employe (
  id_employe     INT          NOT NULL AUTO_INCREMENT,
  nom            VARCHAR(100) NOT NULL,
  prenom         VARCHAR(100) NOT NULL,
  email          VARCHAR(150) NOT NULL UNIQUE,
  mot_de_passe   VARCHAR(255) NOT NULL,
  poste          VARCHAR(100),
  solde_conge    INT          NOT NULL DEFAULT 0,
  role           ENUM('employe', 'admin') NOT NULL DEFAULT 'employe',
  PRIMARY KEY (id_employe)
);

-- ────────────────────────────────────────
-- TABLE : conge
-- ────────────────────────────────────────
CREATE TABLE conge (
  id_conge       INT          NOT NULL AUTO_INCREMENT,
  id_employe     INT          NOT NULL,
  id_type        INT          NOT NULL,
  date_debut     DATE         NOT NULL,
  date_fin       DATE         NOT NULL,
  statut         ENUM('en attente', 'approuvé', 'refusé') NOT NULL DEFAULT 'en attente',
  motif          TEXT,
  PRIMARY KEY (id_conge),
  CONSTRAINT fk_conge_employe FOREIGN KEY (id_employe) REFERENCES employe(id_employe) ON DELETE CASCADE,
  CONSTRAINT fk_conge_type    FOREIGN KEY (id_type)    REFERENCES type_conge(id_type)
);

-- ────────────────────────────────────────
-- TABLE : absence
-- ────────────────────────────────────────
CREATE TABLE absence (
  id_absence     INT          NOT NULL AUTO_INCREMENT,
  id_employe     INT          NOT NULL,
  date_absence   DATE         NOT NULL,
  type_absence   VARCHAR(100),
  justifie       ENUM('O', 'N') NOT NULL DEFAULT 'N',
  motif          TEXT,
  PRIMARY KEY (id_absence),
  CONSTRAINT fk_absence_employe FOREIGN KEY (id_employe) REFERENCES employe(id_employe) ON DELETE CASCADE
);

-- ────────────────────────────────────────
-- TRIGGER 1 : Déduction automatique du solde
--             quand une demande est approuvée
-- ────────────────────────────────────────
DELIMITER //
CREATE TRIGGER maj_solde_apres_approbation
AFTER UPDATE ON conge
FOR EACH ROW
BEGIN
  IF NEW.statut = 'approuvé' AND OLD.statut != 'approuvé' THEN
    UPDATE employe
    SET solde_conge = solde_conge - (DATEDIFF(NEW.date_fin, NEW.date_debut) + 1)
    WHERE id_employe = NEW.id_employe;
  END IF;
END;
//
DELIMITER ;

-- ────────────────────────────────────────
-- TRIGGER 2 : Remboursement du solde
--             si une demande approuvée est refusée
-- ────────────────────────────────────────
DELIMITER //
CREATE TRIGGER remboursement_solde_si_refuse
AFTER UPDATE ON conge
FOR EACH ROW
BEGIN
  IF NEW.statut = 'refusé' AND OLD.statut = 'approuvé' THEN
    UPDATE employe
    SET solde_conge = solde_conge + (DATEDIFF(NEW.date_fin, NEW.date_debut) + 1)
    WHERE id_employe = NEW.id_employe;
  END IF;
END;
//
DELIMITER ;

-- ────────────────────────────────────────
-- DONNÉES DE TEST
-- ────────────────────────────────────────

-- Types de congés
INSERT INTO type_conge (libelle, nb_jours_annuels) VALUES
  ('Congé annuel',    18),
  ('Congé maladie',   30),
  ('Congé sans solde', 0),
  ('Congé maternité', 98);

-- Employés (mot de passe = "1234" hashé en MD5 pour exemple)
INSERT INTO employe (nom, prenom, email, mot_de_passe, poste, solde_conge, role) VALUES
  ('Admin',   'Système',  'admin@rh.ma',   MD5('admin123'), 'Responsable RH', 18, 'admin'),
  ('El Amri', 'Ahmed',    'ahmed@rh.ma',   MD5('1234'),     'Développeur',    18, 'employe'),
  ('Benali',  'Sara',     'sara@rh.ma',    MD5('1234'),     'Designer',       18, 'employe'),
  ('Idrissi', 'Youssef',  'youssef@rh.ma', MD5('1234'),     'Comptable',      18, 'employe');

-- Demandes de congé
INSERT INTO conge (id_employe, id_type, date_debut, date_fin, statut, motif) VALUES
  (2, 1, '2025-07-01', '2025-07-10', 'approuvé',   'Vacances d''été'),
  (3, 2, '2025-06-15', '2025-06-20', 'en attente', 'Maladie'),
  (4, 1, '2025-08-01', '2025-08-05', 'refusé',     'Raisons personnelles');

-- Absences
INSERT INTO absence (id_employe, date_absence, type_absence, justifie, motif) VALUES
  (2, '2025-05-10', 'Absence maladie',    'O', 'Certificat médical fourni'),
  (3, '2025-05-20', 'Absence injustifiée','N', NULL),
  (4, '2025-06-01', 'Absence familiale',  'O', 'Décès dans la famille');

-- ────────────────────────────────────────
-- REQUÊTES UTILES (pour le projet Java)
-- ────────────────────────────────────────

-- 1. Voir toutes les demandes en attente
-- SELECT e.nom, e.prenom, c.date_debut, c.date_fin, t.libelle
-- FROM conge c
-- JOIN employe e ON c.id_employe = e.id_employe
-- JOIN type_conge t ON c.id_type = t.id_type
-- WHERE c.statut = 'en attente';

-- 2. Solde de congé d'un employé
-- SELECT nom, prenom, solde_conge
-- FROM employe
-- WHERE id_employe = 2;

-- 3. Historique des congés d'un employé
-- SELECT c.date_debut, c.date_fin, t.libelle, c.statut
-- FROM conge c
-- JOIN type_conge t ON c.id_type = t.id_type
-- WHERE c.id_employe = 2
-- ORDER BY c.date_debut DESC;

-- 4. Absences du mois en cours
-- SELECT e.nom, e.prenom, a.date_absence, a.justifie
-- FROM absence a
-- JOIN employe e ON a.id_employe = e.id_employe
-- WHERE MONTH(a.date_absence) = MONTH(CURDATE())
--   AND YEAR(a.date_absence)  = YEAR(CURDATE());

-- 5. Statistiques tableau de bord admin
-- SELECT
--   (SELECT COUNT(*) FROM conge WHERE statut = 'en attente') AS en_attente,
--   (SELECT COUNT(*) FROM conge WHERE statut = 'approuvé')   AS approuves,
--   (SELECT COUNT(*) FROM conge WHERE statut = 'refusé')     AS refuses,
--   (SELECT COUNT(*) FROM absence WHERE MONTH(date_absence) = MONTH(CURDATE())) AS absences_mois;
