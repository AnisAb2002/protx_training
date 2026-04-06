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
    let newUser = Utilisateur(
        login: login,
        motDePasse: formData["password"] ?? "",
        nom: formData["nom"] ?? "",
        prenom: formData["prenom"] ?? "",
        dateNaissance: Date(),
        poids: Double(formData["poids"] ?? "0") ?? 0.0,
        taille: Double(formData["taille"] ?? "0") ?? 0.0,
        objectif: formData["objectif"] ?? "Remise en forme",
        scoreTotal: 0
    )
    try db.addUtilisateur(newUser)
    return Response.redirect(to: "/?user=\(login)")
}

// --- ROUTES PROTEGEES ---

router.get("/") { request, context in
    guard let currentUser = request.uri.queryParameters.get("user"),
        let user = try db.getUtilisateur(id: currentUser)
    else {
        return Response.redirect(to: "/login")
    }
    let seances = try db.getSeances(for: currentUser)
    let html = Views.index(utilisateurs: [user], seances: seances)
    return Response(
        status: .ok, headers: [.contentType: "text/html"],
        body: .init(byteBuffer: ByteBuffer(string: html)))
}

router.get("/exercices") { request, context in
    guard let currentUser = request.uri.queryParameters.get("user") else {
        return Response.redirect(to: "/login")
    }
    let searchTerm = request.uri.queryParameters.get("search") ?? ""
    let exercices = try db.searchExercices(parMuscle: searchTerm)
    let html = Views.exercices(liste: exercices, query: searchTerm, currentUser: currentUser)
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

// --- ACTIONS CRUD ---

router.post("/seance/add") { request, context in
    let formData = try await request.decodeURLEncoded(as: [String: String].self, context: context)
    let login = formData["user"] ?? ""
    let titre = formData["titre"] ?? "Séance"

    let nouvelleSeance = Seance(
        id: nil,
        utilisateurLogin: login,
        titre: titre,
        dateSeance: Date(),
        estValidee: false,
        scoreSeance: 0
    )

    // CORRECTION : Vérifie si ta fonction dans Database.swift s'appelle addSeance ou createSeance
    try db.addSeance(nouvelleSeance)

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
