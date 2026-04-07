import Foundation
import Hummingbird
import SQLite

struct Database: @unchecked Sendable {
    let connection: Connection

    // --- Définition des Tables ---
    let utilisateurs = Table("utilisateurs")
    let exercices = Table("exercices")
    let seances = Table("seances")
    let seanceExercices = Table("seance_exercices")

    // --- Définition des Colonnes ---
    let loginCol = Expression<String>("login")
    let motDePasse = Expression<String>("motDePasse")
    let nom = Expression<String>("nom")
    let prenom = Expression<String>("prenom")
    let poids = Expression<Double>("poids")
    let taille = Expression<Double>("taille")
    let scoreTotal = Expression<Int>("scoreTotal")

    let idExo = Expression<Int>("id")
    let nomExo = Expression<String>("nom")
    let muscle = Expression<String>("musclePrincipal")
    let scoreExo = Expression<Int>("scoreCalories")
    let imageURL = Expression<String>("imageURL")

    let idSeance = Expression<Int>("id")
    let userLogin = Expression<String>("userLogin")
    let dateSeance = Expression<Date>("date_seance")
    let estValidee = Expression<Bool>("estValidee")

    let relSeanceId = Expression<Int>("seance_id")
    let relExoId = Expression<Int>("exercice_id")

    // --- Initialisation ---
    init() throws {
        self.connection = try Connection("db.sqlite")
        try createSchema()
        try seedDatabase()  // On remplit les exos au démarrage si vide
    }

    private func createSchema() throws {
        try connection.run(
            utilisateurs.create(ifNotExists: true) { t in
                t.column(loginCol, primaryKey: true)
                t.column(motDePasse)
                t.column(nom)
                t.column(prenom)
                t.column(poids)
                t.column(taille)
                t.column(scoreTotal)
            })

        try connection.run(
            exercices.create(ifNotExists: true) { t in
                t.column(idExo, primaryKey: .autoincrement)
                t.column(nomExo)
                t.column(muscle)
                t.column(scoreExo)
                t.column(imageURL)
            })

        try connection.run(
            seances.create(ifNotExists: true) { t in
                t.column(idSeance, primaryKey: .autoincrement)
                t.column(userLogin)
                t.column(dateSeance)
                t.column(estValidee)
                t.foreignKey(userLogin, references: utilisateurs, loginCol)
            })

        try connection.run(
            seanceExercices.create(ifNotExists: true) { t in
                t.column(relSeanceId)
                t.column(relExoId)
                t.foreignKey(relSeanceId, references: seances, idSeance, delete: .cascade)
                t.foreignKey(relExoId, references: exercices, idExo, delete: .cascade)
                t.primaryKey(relSeanceId, relExoId)
            })
    }

    // --- Opérations CRUD ---

    func addUtilisateur(_ user: Utilisateur) throws {
        let insert = utilisateurs.insert(
            loginCol <- user.login,
            motDePasse <- user.motDePasse,
            nom <- user.nom,
            prenom <- user.prenom,
            poids <- user.poids,
            taille <- user.taille,
            scoreTotal <- 0
        )
        try connection.run(insert)
    }

    func getUtilisateur(id: String) throws -> Utilisateur? {
        let query = utilisateurs.filter(loginCol == id)
        if let row = try connection.pluck(query) {
            return Utilisateur(
                login: row[loginCol],
                motDePasse: row[motDePasse],
                nom: row[nom],
                prenom: row[prenom],
                dateNaissance: Date(),
                poids: row[poids],
                taille: row[taille],
                objectif: "Musculation",
                scoreTotal: row[scoreTotal]
            )
        }
        return nil
    }

    // AJOUT : Ajouter une séance (Manquait pour main.swift)
    func addSeance(_ seance: Seance) throws {
        let insert = seances.insert(
            userLogin <- seance.utilisateurLogin,
            dateSeance <- seance.dateSeance,
            estValidee <- seance.estValidee
        )
        try connection.run(insert)
    }

    func addSeanceAndReturnId(utilisateurLogin: String, titre: String, dateSeance_: Date) throws
        -> Int
    {
        let insert = seances.insert(
            self.userLogin <- utilisateurLogin,
            self.dateSeance <- dateSeance_,
            self.estValidee <- false
        )
        let rowId = try connection.run(insert)
        return Int(rowId)
    }
    func getSeances(for user: String) throws -> [Seance] {
        let query = seances.filter(userLogin == user).order(dateSeance.desc)
        var results = [Seance]()
        for row in try connection.prepare(query) {
            results.append(
                Seance(
                    id: row[idSeance],
                    utilisateurLogin: row[userLogin],
                    titre: "Entraînement",
                    dateSeance: row[dateSeance],
                    estValidee: row[estValidee],
                    scoreSeance: 0
                ))
        }
        return results
    }

    func deleteSeance(id: Int) throws {
        let target = seances.filter(idSeance == id)
        try connection.run(target.delete())
    }

    // AJOUT : Ajouter un exercice (Manquait pour main.swift)
    func addExercice(_ exo: Exercice) throws {
        let insert = exercices.insert(
            nomExo <- exo.nom,
            muscle <- exo.musclePrincipal,
            scoreExo <- exo.scoreCalories,
            imageURL <- exo.imageURL
        )
        try connection.run(insert)
    }
    func lierExerciceASeance(seanceId: Int, exerciceId: Int) throws {
        let insert = seanceExercices.insert(
            relSeanceId <- seanceId,
            relExoId <- exerciceId
        )
        try connection.run(insert)
    }

    func completerSeance(id: Int, login: String) throws {
        // 1. Calculer le score total des exercices liés à cette séance
        // On joint seanceExercices avec exercices pour sommer les scoreExo
        let query =
            seanceExercices
            .join(exercices, on: relExoId == idExo)
            .filter(relSeanceId == id)

        var scoreTotalSeance = 0
        for row in try connection.prepare(query) {
            scoreTotalSeance += row[scoreExo]
        }

        // 2. Marquer la séance comme validée (pour qu'elle n'affiche plus le bouton)
        let s = seances.filter(idSeance == id)
        try connection.run(s.update(estValidee <- true))

        // 3. Ajouter les points au score de l'utilisateur
        let user = utilisateurs.filter(loginCol == login)
        try connection.run(user.update(scoreTotal += scoreTotalSeance))
    }

    func searchExercices(parMuscle: String) throws -> [Exercice] {
        let pattern = "%\(parMuscle)%"
        let query = parMuscle.isEmpty ? exercices : exercices.filter(muscle.like(pattern))
        var results = [Exercice]()
        for row in try connection.prepare(query) {
            results.append(
                Exercice(
                    id: row[idExo],
                    nom: row[nomExo],
                    dureeEstimee: 10,
                    musclePrincipal: row[muscle],
                    objectifCible: "Renforcement",
                    scoreCalories: row[scoreExo],
                    imageURL: row[imageURL]
                ))
        }
        return results
    }

    // --- Données par défaut ---
    func seedDatabase() throws {
        let count = try connection.scalar(exercices.count)
        if count == 0 {
            let data = [
                ("Développé Couché", "Pectoraux", 3, "img/pecs_couche.jpg"),
                ("Pompes", "Pectoraux", 2, "img/pecs_pompes.jpg"),
                ("Squat", "Jambes", 3, "img/jambe_squat.jpg"),
                ("Biceps Curl", "Biceps", 1, "img/biceps_curl.jpg"),
            ]
            for (n, m, s, i) in data {
                try connection.run(
                    exercices.insert(nomExo <- n, muscle <- m, scoreExo <- s, imageURL <- i))
            }
        }
    }
}
