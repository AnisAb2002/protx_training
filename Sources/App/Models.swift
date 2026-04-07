import Foundation

// MARK: - Enums de Progression
// définition de les niveaux d'utilisateurs pour les classer
enum Niveaux: String, Codable, Sendable {
    case debutant = "Débutant"
    case intermediaire = "Intermédiaire"
    case pro = "Pro"
    case monstre = "Monstre"
    case dragon = "Dragon"
    case saiyan = "Saiyan"
    case saitama = "Saitama"

    static func determiner(score: Int) -> Niveaux {
        switch score {
        case ..<100: return .debutant
        case 100..<500: return .intermediaire
        case 500..<1500: return .pro
        case 1500..<3000: return .monstre
        case 3000..<6000: return .dragon
        case 6000..<10000: return .saiyan
        default: return .saitama
        }
    }
}

// MARK: - Utilisateur
struct Utilisateur: Codable, Sendable {
    var login: String  // identifiant unique et clé primaire
    var motDePasse: String  // pour se connecter
    var nom: String
    var prenom: String
    var dateNaissance: Date
    var poids: Double  // kg
    var taille: Double  // cm
    var objectif: String  // "Perte de poids", "Gain de muscle" ...
    var scoreTotal: Int  // Somme des scores des séances déjà faites

    // calcule de l'IMC
    var imc: Double {
        guard taille > 0 else { return 0 }
        let tailleMetres = taille / 100
        return (poids / (tailleMetres * tailleMetres)).rounded()
    }

    // determiner le nieveau de l'utilisateur
    var niveau: Niveaux {
        return Niveaux.determiner(score: scoreTotal)
    }
}

// MARK: - Exercice
struct Exercice: Codable, Sendable {
    var id: Int?  // Auto-incrémenté dans sqlite
    var nom: String
    var dureeEstimee: Int  // minutes
    var musclePrincipal: String  // Pour la logique de récupération des muscles (Pecs, Dos, etc.)
    var objectifCible: String  // "Force", "Endurance"
    var scoreCalories: Int  // Points gagnés en faisant l'exercice
    var imageURL: String  // Chemin vers image
}

// MARK: - Séance
struct Seance: Codable, Sendable {
    var id: Int?  // Auto-incrémenté dans sqlite
    var utilisateurLogin: String  // id de l'utilisateur (login)
    var titre: String
    var dateSeance: Date
    var estValidee: Bool  // si la date est passée et l'utilisateur à validé
    var scoreSeance: Int  // Total des points de la séance
    var exercices: [Exercice] = []
}
