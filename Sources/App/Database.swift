import Foundation
import Hummingbird
import SQLite

struct Database: @unchecked Sendable {
    let connection: Connection

    // MARK: LEs tables qu'on va utiliser
    let utilisateurs = Table("utilisateurs")
    let exercices = Table("exercices")
    let seances = Table("seances")
    let seanceExercices = Table("seance_exercices")  // Liaison entre seances et exercices

    // MARK: Colonnes de la table utilisateurs
    let loginCol = Expression<String>("login")
    let motDePasse = Expression<String>("motDePasse")
    let nom = Expression<String>("nom")
    let prenom = Expression<String>("prenom")
    let poids = Expression<Double>("poids")
    let taille = Expression<Double>("taille")
    let scoreTotal = Expression<Int>("scoreTotal")

    // MARK: Colonnes de la table exercices
    let idExo = Expression<Int>("id")
    let nomExo = Expression<String>("nom")
    let muscle = Expression<String>("musclePrincipal")
    let scoreExo = Expression<Int>("scoreCalories")
    let imageURL = Expression<String>("imageURL")

    // MARK: Colonnes de la table seance
    let idSeance = Expression<Int>("id")
    let userLogin = Expression<String>("userLogin")
    let titreSeance = Expression<String>("titre")
    let dateSeance = Expression<Date>("date_seance")
    let estValidee = Expression<Bool>("estValidee")

    // MARK: Colonnes de la relation
    let relSeanceId = Expression<Int>("seance_id")
    let relExoId = Expression<Int>("exercice_id")

    // // MARK: initialiser
    init() throws {
        self.connection = try Connection("db.sqlite")
        try createSchema()
        try seedDatabase()  // On remplit les exos au démarrage si vide
    }

    // MARK: le schema à suivre pour les tables
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
                t.column(titreSeance)
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

    // MARK : créer un utilisateur et l'ajouter dans la table utilisateurs

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

    // MARK: récupérer les utiilisateurs depuis la table utilisateurs
    func getUtilisateur(id: String) throws -> Utilisateur? {
        let query = utilisateurs.filter(loginCol == id)
        if let row = try connection.pluck(query) {
            return Utilisateur(
                login: row[loginCol],
                motDePasse: row[motDePasse],
                nom: row[nom],
                prenom: row[prenom],
                poids: row[poids],
                taille: row[taille],
                objectif: "Musculation",
                scoreTotal: row[scoreTotal]
            )
        }
        return nil
    }

    // MARK: mettre à jour les infos d'un utilsateur
    func updateUtilisateur(_ user: Utilisateur) throws {
        let target = utilisateurs.filter(loginCol == user.login)
        try connection.run(
            target.update(
                nom <- user.nom,
                prenom <- user.prenom,
                poids <- user.poids,
                taille <- user.taille
                    // On ne change pas le login (clé primaire) ni le score ici
            ))
    }

    // MARK: créer une séance et l'ajouter à la tables seances
    func addSeanceAndReturnId(utilisateurLogin: String, titre: String, dateSeance_: Date) throws
        -> Int
    {
        let insert = seances.insert(
            self.userLogin <- utilisateurLogin,
            self.titreSeance <- titre,
            self.dateSeance <- dateSeance_,
            self.estValidee <- false
        )
        let rowId = try connection.run(insert)
        return Int(rowId)
    }

    // MARK: récupérer les séances depuis la table seances
    func getSeances(for user: String) throws -> [Seance] {
        let query = seances.filter(userLogin == user).order(dateSeance.desc)
        var results = [Seance]()
        for row in try connection.prepare(query) {
            results.append(
                Seance(
                    id: row[idSeance],
                    utilisateurLogin: row[userLogin],
                    titre: row[titreSeance],
                    dateSeance: row[dateSeance],
                    estValidee: row[estValidee],
                    scoreSeance: 0
                ))
        }
        return results
    }

    // MARK: récupérer les exercices depuis la table seanceExercices
    func getExercices(forSeanceId id: Int) throws -> [Exercice] {
        let query =
            seanceExercices
            .join(exercices, on: exercices[idExo] == seanceExercices[relExoId])
            .filter(seanceExercices[relSeanceId] == id)

        var results = [Exercice]()
        for row in try connection.prepare(query) {
            results.append(
                Exercice(
                    id: row[exercices[idExo]],
                    nom: row[nomExo],
                    dureeEstimee: 0,
                    musclePrincipal: row[muscle],
                    objectifCible: "",
                    scoreCalories: row[scoreExo],
                    imageURL: row[imageURL]
                ))
        }
        return results
    }

    // MARK: supprimer une séance de la bd
    func deleteSeance(id: Int) throws {
        let target = seances.filter(idSeance == id)
        try connection.run(target.delete())
    }

    // MARK: Relation entre une séance et un exercice
    func lierExerciceASeance(seanceId: Int, exerciceId: Int) throws {
        let insert = seanceExercices.insert(
            relSeanceId <- seanceId,
            relExoId <- exerciceId
        )
        try connection.run(insert)
    }

    // MARK: Valider une séance
    func completerSeance(id: Int, login: String) throws {

        // calculer le score total des exercices de cette séance
        // On joint seanceExercices avec exercices pour sommer les scoreExo
        let query =
            seanceExercices
            .join(exercices, on: exercices[idExo] == seanceExercices[relExoId])
            .filter(seanceExercices[relSeanceId] == id)

        var scoreTotalSeance = 0  //on initialise
        for row in try connection.prepare(query) {
            scoreTotalSeance += row[scoreExo]
        }

        // marquer la séance comme validée
        let s = seances.filter(idSeance == id)
        try connection.run(s.update(estValidee <- true))

        // ajouter les points au score de l'utilisateur
        let user = utilisateurs.filter(loginCol == login)
        try connection.run(user.update(scoreTotal += scoreTotalSeance))
    }

    // MARK: chercer un exercice par muscle
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

    // MARK: Données dans la base de données

    func seedDatabase() throws {
        let count = try connection.scalar(exercices.count)
        if count == 0 {
            let data = [
                ("Développé Couché", "Pectoraux", 3, "img/pecs_couche.gif"),
                ("Écarté Couché", "Pectoraux", 1, "img/pecs_ecarte.gif"),
                ("Pompes", "Pectoraux", 2, "img/pecs_pompes.gif"),
                ("Dips", "Pectoraux", 2, "img/pecs_dips.gif"),
                ("Rowing", "Dos", 3, "img/dos_rowing.gif"),
                ("Traction", "Dos", 3, "img/dos_traction.gif"),
                ("Squat", "Jambes", 3, "img/jambe_squat.gif"),
                ("Fentes", "Jambes", 3, "img/jambe_fentes.gif"),
                ("Biceps Curl", "Biceps", 1, "img/biceps_curl.gif"),
                ("Extension Curl", "Triceps", 1, "img/extension_triceps.gif"),
                ("Planche", "Abdos", 2, "img/abdos_planche.gif"),
                ("Élévation Frontale", "Épaules", 2, "img/epaules_elevation_front.gif"),
                ("Élévation Latérale", "Épaules", 2, "img/epaules_elevation_lat.gif"),
            ]
            for (n, m, s, i) in data {
                try connection.run(
                    exercices.insert(nomExo <- n, muscle <- m, scoreExo <- s, imageURL <- i))
            }
        }
    }
}
