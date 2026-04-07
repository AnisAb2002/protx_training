import Foundation
import Hummingbird
import Logging

// MARK: - Extension Request
extension Request {
    func decodeURLEncoded<T: Decodable>(as type: T.Type, context: some RequestContext) async throws
        -> T
    {
        let buffer = try await self.body.collect(upTo: 1_000_000)
        let string = String(buffer: buffer)
        return try URLEncodedFormDecoder().decode(T.self, from: string)
    }
}

let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd"
    return df
}()

// MARK: - Configuration
let router = Router()
let logger = Logger(label: "ProtxTraining")

// CORRECTION : Suppression de 'searchDirectory:'
let fileMiddleware = FileMiddleware<BasicRequestContext, LocalFileSystem>("public")
router.add(middleware: fileMiddleware)

let db = try Database()

// --- ROUTES DE CONNEXION ---

router.get("/login") { request, context in
    let hasError = request.uri.queryParameters.get("error") == "1"
    let html = Views.login(error: hasError)
    return Response(
        status: .ok, headers: [.contentType: "text/html"],
        body: .init(byteBuffer: ByteBuffer(string: html)))
}

router.post("/login") { request, context in
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)
    let login = formData["login"] ?? ""
    let pass = formData["password"] ?? ""

    if let user = try db.getUtilisateur(id: login), user.motDePasse == pass {
        return Response.redirect(to: "/?user=\(login)")
    } else {
        return Response.redirect(to: "/login?error=1")
    }
}

router.get("/register") { request, context in
    let html = Views.register()
    return Response(
        status: .ok, headers: [.contentType: "text/html"],
        body: .init(byteBuffer: ByteBuffer(string: html)))
}

router.post("/register") { request, context in
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)
    let login = formData["login"] ?? ""

    // On récupère l'objectif choisi par l'utilisateur
    let objectifChoisi = formData["objectif"] ?? "Remise en forme"

    let newUser = Utilisateur(
        login: login,
        motDePasse: formData["password"] ?? "",
        nom: formData["nom"] ?? "",
        prenom: formData["prenom"] ?? "",
        dateNaissance: Date(),
        poids: Double(formData["poids"] ?? "0") ?? 0.0,
        taille: Double(formData["taille"] ?? "0") ?? 0.0,
        objectif: objectifChoisi,  // Utilisation de la variable ici
        scoreTotal: 0
    )

    try db.addUtilisateur(newUser)

    // Redirection directe vers le dashboard avec la session (login)
    return Response.redirect(to: "/?user=\(login)")
}

// --- ROUTES PROTEGEES ---

// Dans main.swift
router.get("/") { request, context in
    guard let currentUser = request.uri.queryParameters.get("user"),
        let user = try db.getUtilisateur(id: currentUser)
    else {
        return Response.redirect(to: "/login")
    }

    // On récupère les séances
    var seances = try db.getSeances(for: currentUser)

    // NOUVEAU : Pour chaque séance, on va chercher ses exercices et calculer son score
    for i in 0..<seances.count {
        if let id = seances[i].id {
            let exos = try db.getExercices(forSeanceId: id)
            seances[i].exercices = exos
            // Le score de la séance est la somme des points de ses exos
            seances[i].scoreSeance = exos.reduce(0) { $0 + $1.scoreCalories }
        }
    }

    let exercicesDispo = try db.searchExercices(parMuscle: "")
    let html = Views.index(
        utilisateurs: [user], seances: seances, exercicesDisponibles: exercicesDispo)
    return Response(
        status: .ok, headers: [.contentType: "text/html"],
        body: .init(byteBuffer: ByteBuffer(string: html)))
}

router.get("/profil") { request, context in
    guard let currentUser = request.uri.queryParameters.get("user"),
        let user = try db.getUtilisateur(id: currentUser)
    else {
        return Response.redirect(to: "/login")
    }
    let html = Views.profil(user: user)
    return Response(
        status: .ok, headers: [.contentType: "text/html"],
        body: .init(byteBuffer: ByteBuffer(string: html)))
}

router.post("/profil/update") { request, context in
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)

    let login = formData["login"] ?? ""

    // On récupère l'utilisateur actuel pour ne pas perdre les données non éditées (score, pass, etc.)
    guard var user = try db.getUtilisateur(id: login) else {
        return Response.redirect(to: "/login")
    }

    // Mise à jour des propriétés
    user.nom = formData["nom"] ?? user.nom
    user.prenom = formData["prenom"] ?? user.prenom
    user.poids = Double(formData["poids"] ?? "0") ?? user.poids
    user.taille = Double(formData["taille"] ?? "0") ?? user.taille

    // Sauvegarde en base
    try db.updateUtilisateur(user)

    // Redirection vers le profil avec un petit paramètre optionnel pour confirmer le succès si tu veux
    return Response.redirect(to: "/profil?user=\(login)")
}

// --- ACTIONS CRUD ---

router.post("/seance/add") { request, context in
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)
    let login = formData["user"] ?? ""
    let titre = formData["titre"] ?? "Séance"

    // RECUPÉRATION DE LA DATE DU FORMULAIRE
    let dateString = formData["date"] ?? ""
    let dateChoisie = dateFormatter.date(from: dateString) ?? Date()  // Aujourd'hui par défaut si erreur

    // 1. Créer la séance (retourne l'ID généré si tu as mis à jour Database.swift)
    // Logique pour enregistrer la séance et ses exercices...
    let seanceId = try db.addSeanceAndReturnId(
        utilisateurLogin: login,
        titre: titre,
        dateSeance_: dateChoisie  // Assure-toi que ta fonction DB accepte la date
    )

    // 2. Récupérer les IDs des exercices cochés
    // Note: Dans le HTML, les checkboxes doivent avoir le nom "exercices"
    // On décode ici manuellement les IDs si nécessaire ou via un format spécifique
    let exercicesSelectionnes = formData.filter { $0.key.prefix(4) == "exo_" }.map { $0.value }

    for exoIdString in exercicesSelectionnes {
        if let exoId = Int(exoIdString) {
            try db.lierExerciceASeance(seanceId: seanceId, exerciceId: exoId)
        }
    }

    return Response.redirect(to: "/?user=\(login)")
}
// Page pour créer une séance avec sélection d'exercices
router.get("/seance/new") { request, context in
    guard let currentUser = request.uri.queryParameters.get("user") else {
        return Response.redirect(to: "/login")
    }
    // Au lieu d'une page séparée, on renvoie à l'index (où se trouve le formulaire)
    return Response.redirect(to: "/?user=\(currentUser)")
}

router.post("/seance/valider/:id") { request, context in
    // On récupère le login pour savoir quel utilisateur créditer
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)
    let login = formData["user"] ?? ""

    // On récupère l'ID de la séance depuis l'URL
    if let idString = context.parameters.get("id"), let id = Int(idString) {
        try db.completerSeance(id: id, login: login)
    }

    // On redirige vers l'index pour voir le score mis à jour !
    return Response.redirect(to: "/?user=\(login)")
}

router.post("/seance/delete/:id") { request, context in
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)
    let login = formData["user"] ?? ""
    if let idString = context.parameters.get("id"), let id = Int(idString) {
        try db.deleteSeance(id: id)
    }
    return Response.redirect(to: "/?user=\(login)")
}

router.post("/exercices/add") { request, context in
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)
    let login = formData["user"] ?? ""

    let nouvelExo = Exercice(
        id: nil,
        nom: formData["nom"] ?? "",
        dureeEstimee: 10,
        musclePrincipal: formData["muscle"] ?? "",
        objectifCible: "Renforcement",
        scoreCalories: Int(formData["xp"] ?? "10") ?? 10,
        imageURL: formData["image"] ?? ""
    )

    // CORRECTION : Vérifie si ta fonction dans Database.swift s'appelle addExercice ou createExercice
    try db.addExercice(nouvelExo)

    return Response.redirect(to: "/exercices?user=\(login)")
}

// --- LANCEMENT ---
let app = Application(
    router: router,
    configuration: .init(address: .hostname("0.0.0.0", port: 8080))
)
logger.info("🚀 Serveur démarré sur http://localhost:8080")
try await app.run()
