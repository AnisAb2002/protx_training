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
