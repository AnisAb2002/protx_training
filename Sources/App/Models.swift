import Foundation

// MARK: - Utilisateur
struct Utilisateur: Codable, Sendable {
    var login: String
    var nom: String
    var prenom: String
    var dateNaissance: Date
    var motDePasse: String
    var objectif: String
    var poids: Double
    var taille: Double
    var IMC: Double
    var scoreUtilisateur: Int
}

// MARK: - Exercice
struct Exercice: Codable, Sendable {
    var idExercice: Int
    var nom: String
    var duree: Int
    var muscles: [String]
    var objectif: String
    var score: Int
    var image: String
}

// MARK: - Séance
struct Seance: Codable, Sendable {
    var idSeance: Int
    var loginUtilisateur: String
    var duree: Int
    var objectif: String
    var score: Int
    var date: Date
    var exercices: [Exercice]
}
