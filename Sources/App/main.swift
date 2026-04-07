import Foundation
import Hummingbird
import Logging

// MARK: Récupère un bloc de texte brute dans le buffer puis le décode en string
extension Request {
    func decodeURLEncoded<T: Decodable>(as type: T.Type, context: some RequestContext) async throws
        -> T
    {
        let buffer = try await self.body.collect(upTo: 1_000_000)
        let string = String(buffer: buffer)
        return try URLEncodedFormDecoder().decode(T.self, from: string)
    }
}

// MARK: Donner le bon format à la date
let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd"
    return df
}()

// MARK: Configuration
let router = Router()
let logger = Logger(label: "ProtxTraining")

// met un chemin vers le dossier public pour accéder aux images
let fileMiddleware = FileMiddleware<BasicRequestContext, LocalFileSystem>("public")
router.add(middleware: fileMiddleware)

let db = try Database()

// MARK: routes connexion
//recevoir les données de connexion
router.get("/login") { request, context in
    let hasError = request.uri.queryParameters.get("error") == "1"
    let html = Views.login(error: hasError)
    return Response(
        status: .ok, headers: [.contentType: "text/html"],
        body: .init(byteBuffer: ByteBuffer(string: html)))
}

// envoyer les données de connexion
router.post("/login") { request, context in
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)
    let login = formData["login"] ?? ""
    let pass = formData["password"] ?? ""

    if let user = try db.getUtilisateur(id: login), user.motDePasse == pass {
        return Response.redirect(to: "/?user=\(login)")  // si login et mdp correct on se connecte
    } else {
        return Response.redirect(to: "/login?error=1")  //sinon en retourne vers /login encore
    }
}

// MARK: routes inscription
//récuperer les données dans inscirption
router.get("/register") { request, context in
    let html = Views.register()
    return Response(
        status: .ok, headers: [.contentType: "text/html"],
        body: .init(byteBuffer: ByteBuffer(string: html)))
}

//envoyer les données du formulaire de inscription
router.post("/register") { request, context in
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)
    let login = formData["login"] ?? ""

    // On récupère l'objectif choisi par l'utilisateur
    let objectifChoisi = formData["objectif"] ?? "Remise en forme"

    let newUser = Utilisateur(  //on crée un nouveau objet utilisateur
        login: login,
        motDePasse: formData["password"] ?? "",
        nom: formData["nom"] ?? "",
        prenom: formData["prenom"] ?? "",
        poids: Double(formData["poids"] ?? "0") ?? 0.0,
        taille: Double(formData["taille"] ?? "0") ?? 0.0,
        objectif: objectifChoisi,
        scoreTotal: 0
    )

    try db.addUtilisateur(newUser)  // appel de la fonction dans la Database.swift

    // Redirection directe vers l'accueil avec la session (login)
    return Response.redirect(to: "/?user=\(login)")
}

// MARK: routes root
router.get("/") { request, context in
    guard let currentUser = request.uri.queryParameters.get("user"),
        let user = try db.getUtilisateur(id: currentUser)  // on est connecté
    else {
        return Response.redirect(to: "/login")  //sinon on va à la page connexion
    }

    // On récupère les séances
    var seances = try db.getSeances(for: currentUser)

    // on va chercher ses exercices et calculer son score
    for i in 0..<seances.count {
        if let id = seances[i].id {
            let exos = try db.getExercices(forSeanceId: id)
            seances[i].exercices = exos
            // Le score de la séance = somme des points de ses exos
            seances[i].scoreSeance = exos.reduce(0) { $0 + $1.scoreCalories }
        }
    }

    let exercicesDispo = try db.searchExercices(parMuscle: "")  // on affiche les exos recherhcés (ou tout)
    let html = Views.index(
        utilisateurs: [user], seances: seances, exercicesDisponibles: exercicesDispo)
    return Response(
        status: .ok, headers: [.contentType: "text/html"],
        body: .init(byteBuffer: ByteBuffer(string: html)))
}

// MARK: routes profil
router.get("/profil") { request, context in
    guard let currentUser = request.uri.queryParameters.get("user"),
        let user = try db.getUtilisateur(id: currentUser)  // si on est connecté on récupère l'id
    else {
        return Response.redirect(to: "/login")  // sinon on repars vers connexion
    }
    let html = Views.profil(user: user)  // afficher les informations du utilisateur
    return Response(
        status: .ok, headers: [.contentType: "text/html"],
        body: .init(byteBuffer: ByteBuffer(string: html)))
}

// mise à jour infos utilisateurs
router.post("/profil/update") { request, context in
    //récupérer les infos des champs remplies et les décoder
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)

    let login = formData["login"] ?? ""

    // On récupère l'utilisateur actuel pour ne pas perdre les données non éditées
    guard var user = try db.getUtilisateur(id: login) else {
        return Response.redirect(to: "/login")
    }

    // mise à jour des propriétés
    user.nom = formData["nom"] ?? user.nom
    user.prenom = formData["prenom"] ?? user.prenom
    user.poids = Double(formData["poids"] ?? "0") ?? user.poids
    user.taille = Double(formData["taille"] ?? "0") ?? user.taille

    // Sauvegarde en base
    try db.updateUtilisateur(user)

    // on reviens vers le profil
    return Response.redirect(to: "/profil?user=\(login)")
}

//MARK: Ajouter seance
router.post("/seance/add") { request, context in
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)
    let login = formData["user"] ?? ""
    let titre = formData["titre"] ?? "Séance"

    // récupérer la date du formulaire et la formater
    let dateString = formData["date"] ?? ""
    let dateChoisie = dateFormatter.date(from: dateString) ?? Date()  // met aujourd'hui par défaut si erreur

    // Créer la séance et retourne l'id de la seance
    let seanceId = try db.addSeanceAndReturnId(
        utilisateurLogin: login,
        titre: titre,
        dateSeance_: dateChoisie
    )

    // puis on récupére les IDs des exercices cochés
    let exercicesSelectionnes = formData.filter { $0.key.prefix(4) == "exo_" }.map { $0.value }

    for exoIdString in exercicesSelectionnes {
        if let exoId = Int(exoIdString) {
            // ajouter les id des exos avec l'id de la seance pour faire une relation dans la table :
            try db.lierExerciceASeance(seanceId: seanceId, exerciceId: exoId)
        }
    }

    return Response.redirect(to: "/?user=\(login)")
}

// MARK: Valider la séance
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

// MARK: Supprimer une séance
router.post("/seance/delete/:id") { request, context in
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)
    let login = formData["user"] ?? ""
    if let idString = context.parameters.get("id"), let id = Int(idString) {
        try db.deleteSeance(id: id)
    }
    return Response.redirect(to: "/?user=\(login)")
}

// MARK: lancement
let app = Application(
    router: router,
    configuration: .init(address: .hostname("0.0.0.0", port: 8080))
)
logger.info("🚀 Serveur démarré sur http://localhost:8080")
try await app.run()
