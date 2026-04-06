import Foundation

struct Views {

    // MARK: - Header & Footer (Navigation Dynamique)
    private static func header(title: String, currentUser: String? = nil) -> String {
        // Propagation du login dans les URLs pour maintenir la session
        let userSuffix = currentUser != nil ? "?user=\(currentUser!)" : ""

        return """
            <!DOCTYPE html>
            <html lang="fr" data-theme="dark">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                <title>\(title) - ProtX Training</title>
                <style>
                    :root { --primary: #d81b60; }
                    body { font-family: 'Inter', sans-serif; }
                    h1, h2, h3 { font-weight: 900; text-transform: uppercase; letter-spacing: -1px; }
                    .card-workout { border-left: 4px solid var(--primary); padding: 1rem; margin-bottom: 1rem; background: #1a1a1a; border-radius: 8px; }
                    .grid-exercices { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1rem; }
                    img.exo-img { width: 100%; height: 200px; object-fit: cover; border-radius: 8px 8px 0 0; }
                </style>
            </head>
            <body>
                <nav class="container">
                    <ul><li><strong>Protx Training</strong></li></ul>
                    <ul>
                        <li><a href="/\(userSuffix)">Tableau de Bord</a></li>
                        <li><a href="/exercices\(userSuffix)">Exercices</a></li>
                        <li><a href="/profil\(userSuffix)" class="secondary">Mon Profil</a></li>
                        <li><a href="/login" style="color: #ff5252;">Déconnexion</a></li>
                    </ul>
                </nav>
                <main class="container">
            """
    }

    private static func footer() -> String {
        return "</main></body></html>"
    }

    // MARK: - Connexion
    static func login(error: Bool = false) -> String {
        let errorMsg =
            error
            ? "<p style='color: #ff5252; font-size: 0.8rem;'>Identifiant ou mot de passe incorrect.</p>"
            : ""
        return """
            <!DOCTYPE html>
            <html lang="fr" data-theme="dark">
            <head>
                <meta charset="UTF-8">
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                <title>Connexion - God Mode</title>
            </head>
            <body class="container" style="display: flex; height: 100vh; align-items: center; justify-content: center;">
                <article style="width: 400px;">
                    <header><strong>⚡️ GOD MODE : CONNEXION</strong></header>
                    \(errorMsg)
                    <form method="POST" action="/login">
                        <input type="text" name="login" placeholder="Identifiant" required>
                        <input type="password" name="password" placeholder="Mot de passe" required>
                        <button type="submit">Se connecter</button>
                    </form>
                    <footer style="text-align: center;">
                        Pas de compte ? <a href="/register">S'inscrire ici</a>
                    </footer>
                </article>
            </body>
            </html>
            """
    }

    // MARK: - Inscription
    static func register() -> String {
        return """
            <!DOCTYPE html>
            <html lang="fr" data-theme="dark">
            <head>
                <meta charset="UTF-8">
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                <title>Inscription - God Mode</title>
            </head>
            <body class="container" style="display: flex; min-height: 100vh; align-items: center; justify-content: center; padding: 2rem 0;">
                <article style="width: 600px;">
                    <header><strong>🚀 CRÉER MON PROFIL</strong></header>
                    <form method="POST" action="/register">
                        <div class="grid">
                            <input type="text" name="prenom" placeholder="Prénom" required>
                            <input type="text" name="nom" placeholder="Nom" required>
                        </div>
                        <input type="text" name="login" placeholder="Identifiant" required>
                        <input type="password" name="password" placeholder="Mot de passe" required>
                        <hr>
                        <label>Données Physiques</label>
                        <div class="grid">
                            <input type="number" name="poids" placeholder="Poids (kg)" step="0.1" required>
                            <input type="number" name="taille" placeholder="Taille (cm)" required>
                        </div>
                        <select name="objectif">
                            <option value="Remise en forme">Remise en forme</option>
                            <option value="Prise de masse">Prise de masse</option>
                            <option value="Perte de poids">Perte de poids</option>
                        </select>
                        <button type="submit">Démarrer l'aventure</button>
                    </form>
                </article>
            </body>
            </html>
            """
    }

    // MARK: - Tableau de Bord
    static func index(utilisateurs: [Utilisateur], seances: [Seance]) -> String {
        let user = utilisateurs.first
        let currentLogin = user?.login ?? ""
        var html = header(title: "Tableau de Bord", currentUser: currentLogin)

        html += """
            <section>
                <hgroup>
                    <h1>Salut, \(user?.prenom ?? "Champion") !</h1>
                    <p>Niveau : <strong>\(user?.niveau.rawValue ?? "Débutant")</strong> | Score : \(user?.scoreTotal ?? 0) XP</p>
                </hgroup>
                
                <article>
                    <header>🗓 Mes Prochaines Séances</header>
                    \(seances.isEmpty ? "<p>Aucune séance. Prêt à transpirer ?</p>" : "")
                    \(seances.map { seance in
                    """
                    <div class="card-workout">
                        <div class="grid">
                            <div>
                                <strong>\(seance.titre)</strong><br>
                                <small>\(seance.dateSeance.formatted(date: .abbreviated, time: .omitted))</small>
                            </div>
                            <div style="text-align: right;">
                                \(seance.estValidee ? "✅ Fait" : 
                                "<form method='POST' action='/seance/delete/\(seance.id ?? 0)' style='display:inline;'><input type='hidden' name='user' value='\(currentLogin)'><button class='outline contrast' style='padding:4px 8px; font-size:12px;'>Supprimer</button></form>")
                            </div>
                        </div>
                    </div>
                    """
                }.joined())
                </article>
                
                <footer>
                    <form action="/seance/add" method="POST">
                        <input type="hidden" name="user" value="\(currentLogin)">
                        <fieldset role="group">
                            <input name="titre" placeholder="Nom de la séance" required>
                            <input type="date" name="date" required>
                            <button type="submit">Programmer +</button>
                        </fieldset>
                    </form>
                </footer>
            </section>
            """
        html += footer()
        return html
    }

    // MARK: - Catalogue Exercices
    static func exercices(liste: [Exercice], query: String?, currentUser: String) -> String {
        var html = header(title: "Exercices", currentUser: currentUser)

        html += """
            <section>
                <details>
                    <summary role="button" class="outline">＋ Ajouter un exercice personnalisé</summary>
                    <form method="POST" action="/exercices/add">
                        <input type="hidden" name="user" value="\(currentUser)">
                        <div class="grid">
                            <input type="text" name="nom" placeholder="Nom de l'exo" required>
                            <input type="text" name="muscle" placeholder="Muscle" required>
                        </div>
                        <div class="grid">
                            <input type="number" name="xp" placeholder="XP" required>
                            <input type="text" name="image" placeholder="URL Image ou /img/nom.jpg" required>
                        </div>
                        <button type="submit">Enregistrer l'exercice</button>
                    </form>
                </details>
                <hr>
                <form method="GET" action="/exercices">
                    <input type="hidden" name="user" value="\(currentUser)">
                    <input type="search" name="search" placeholder="Filtrer par muscle..." value="\(query ?? "")">
                </form>
                
                <div class="grid-exercices">
                \(liste.map { exo in
                """
                <article style="padding: 0; overflow: hidden;">
                    <img src="/\(exo.imageURL)" class="exo-img" alt="\(exo.nom)">
                    <div style="padding: 1rem;">
                        <hgroup>
                            <h4>\(exo.nom)</h4>
                            <p>\(exo.musclePrincipal)</p>
                        </hgroup>
                        <p><mark>\(exo.scoreCalories) XP</mark></p>
                        <button class='outline' style="width:100%">Ajouter</button>
                    </div>
                </article>
                """
            }.joined())
                </div>
            </section>
            """
        html += footer()
        return html
    }

    // MARK: - Profil
    static func profil(user: Utilisateur) -> String {
        var html = header(title: "Mon Profil", currentUser: user.login)

        html += """
            <article>
                <hgroup>
                    <h2>\(user.prenom) \(user.nom)</h2>
                    <h3>Grade actuel : \(user.niveau.rawValue)</h3>
                </hgroup>
                <div class="grid">
                    <div><label>Poids</label><input type="text" value="\(user.poids) kg" readonly></div>
                    <div><label>Taille</label><input type="text" value="\(user.taille) cm" readonly></div>
                    <div><label>IMC</label><input type="text" value="\(user.imc)" readonly></div>
                </div>
                <blockquote><strong>Objectif :</strong> \(user.objectif)</blockquote>
            </article>
            """
        html += footer()
        return html
    }
}
