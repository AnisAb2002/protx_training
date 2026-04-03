import Foundation
import SQLite

// Connection uses an internal serial queue, so it is safe to mark Sendable.
extension Connection: @unchecked @retroactive Sendable {}

struct Database {

    // Definitions for the Table

    // MARK: - Tables

    let utilisateurs = Table("utilisateurs")
    let exercices = Table("exercices")
    let seances = Table("seances")

    // MARK: - Colonnes Utilisateur
    let login = Expression<String>("login")
    let nom = Expression<String>("nom")
    let prenom = Expression<String>("prenom")
    let dateNaissance = Expression<Date>("dateNaissance")
    let motDePasse = Expression<String>("motDePasse")
    let objectif = Expression<String>("objectif")
    let poids = Expression<Double>("poids")
    let taille = Expression<Double>("taille")
    let IMC = Expression<Double>("IMC")
    let scoreUtilisateur = Expression<Int>("scoreUtilisateur")

    // MARK: - Colonnes Exercice
    let idExercice = Expression<Int>("idExercice")
    let nomExercice = Expression<String>("nom")
    let duree = Expression<Int>("duree")
    let muscles = Expression<String>("muscles")  // JSON
    let objectifExercice = Expression<String>("objectif")
    let scoreExercice = Expression<Int>("score")
    let image = Expression<String>("image")

    // MARK: - Colonnes Séance
    let idSeance = Expression<Int>("idSeance")
    let loginSeance = Expression<String>("loginUtilisateur")
    let dureeSeance = Expression<Int>("duree")
    let objectifSeance = Expression<String>("objectif")
    let scoreSeance = Expression<Int>("score")
    let dateSeance = Expression<Date>("date")
    let exercicesSeance = Expression<String>("exercices")
}
