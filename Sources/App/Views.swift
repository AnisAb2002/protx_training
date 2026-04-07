import Foundation

struct Views {

    // MARK: - Header & Footer
    private static func header(title: String, currentUser: String? = nil) -> String {
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
                    .card-workout { border-left: 4px solid var(--primary); padding: 1.5rem; margin-bottom: 1.5rem; background: #1a1a1a; border-radius: 8px; }
                    .exo-tag { background: #333; padding: 2px 8px; border-radius: 4px; font-size: 0.8rem; margin-right: 5px; border: 1px solid #444; }
                    .grid-selection { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 1rem; max-height: 300px; overflow-y: auto; padding: 10px; border: 1px solid #333; border-radius: 8px; }
                    .check-item { display: flex; align-items: center; gap: 10px; background: #222; padding: 10px; border-radius: 6px; cursor: pointer; }
                </style>
            </head>
            <body>
                <nav class="container">
                    <ul><li><strong>Protx Training</strong></li></ul>
                    <ul>
                        <li><a href="/\(userSuffix)">Tableau de Bord</a></li>
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

    // MARK: - Connexion & Inscription (Inchangés mais gardés pour structure)
    static func login(error: Bool = false) -> String {
        let errorMsg =
            error ? "<p style='color: #ff5252;'>Identifiant ou mot de passe incorrect.</p>" : ""
        return """
            <!DOCTYPE html>
            <html lang="fr" data-theme="dark"><head><meta charset="UTF-8"><link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"><title>Connexion</title></head>
            <body class="container" style="display: flex; height: 100vh; align-items: center; justify-content: center;">
                <article style="width: 400px;"><header><strong>CONNEXION</strong></header>\(errorMsg)
                <form method="POST" action="/login"><input type="text" name="login" placeholder="Identifiant" required><input type="password" name="password" placeholder="Mot de passe" required><button type="submit">Se connecter</button></form>
                <footer style="text-align: center;">Pas de compte ? <a href="/register">S'inscrire</a></footer></article>
            </body></html>
            """
    }

    static func register() -> String {
        return """
            <!DOCTYPE html>
            <html lang="fr" data-theme="dark"><head><meta charset="UTF-8"><link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"><title>Inscription</title></head>
            <body class="container" style="display: flex; min-height: 100vh; align-items: center; justify-content: center;"><article style="width: 600px;"><header><strong>CRÉER MON PROFIL</strong></header>
                <form method="POST" action="/register"><div class="grid"><input type="text" name="prenom" placeholder="Prénom" required><input type="text" name="nom" placeholder="Nom" required></div><input type="text" name="login" placeholder="Identifiant" required><input type="password" name="password" placeholder="Mot de passe" required><hr>
                <div class="grid"><input type="number" name="poids" placeholder="Poids (kg)" required><input type="number" name="taille" placeholder="Taille (cm)" required></div><button type="submit">Démarrer</button></form>
            </article></body></html>
            """
    }

    // MARK: - Page Nouvelle Séance
static func nouvelleSeance(exercices: [Exercice], user: String) -> String {
    var html = header(title: "Planifier une séance", currentUser: user)

    html += """
        <article>
            <hgroup>
                <h1>Planifier ma séance</h1>
                <p>Sélectionnez le titre, la date et les exercices à inclure.</p>
            </hgroup>
            
            <form action="/seance/add" method="POST">
                <input type="hidden" name="user" value="\(user)">
                
                <label for="titre">Nom de la séance</label>
                <input name="titre" id="titre" placeholder="Ex: Full Body, Séance Pecs..." required>
                
                <label for="date">Date prévue</label>
                <input type="date" name="date" id="date" required>
                
                <label>Choisir les exercices :</label>
                <div class="grid-selection" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 1rem; max-height: 400px; overflow-y: auto; padding: 15px; border: 1px solid #333; border-radius: 8px; background: #111;">
                    \(exercices.map { exo in
                    """
                    <label style="display: flex; align-items: center; gap: 10px; background: #222; padding: 10px; border-radius: 6px; cursor: pointer; border: 1px solid #333;">
                        <input type="checkbox" name="exo_\(exo.id ?? 0)" value="\(exo.id ?? 0)" style="margin-bottom: 0;">
                        <span>
                            <strong>\(exo.nom)</strong><br>
                            <small style="color:#d81b60">\(exo.musclePrincipal)</small>
                        </span>
                    </label>
                    """
                    }.joined())
                </div>
                
                <br>
                <button type="submit" class="primary">Enregistrer la séance</button>
                <a href="/?user=\(user)" class="secondary outline" style="display: block; text-align: center; text-decoration: none;">Annuler</a>
            </form>
        </article>
    """
    
    html += footer()
    return html
}

    // MARK: - Tableau de Bord (Nouveau design avec Bouton Valider)
    static func index(
        utilisateurs: [Utilisateur], seances: [Seance], exercicesDisponibles: [Exercice]
    ) -> String {
        let user = utilisateurs.first
        let currentLogin = user?.login ?? ""
        var html = header(title: "Tableau de Bord", currentUser: currentLogin)

        html += """
            <section>
                <hgroup>
                    <h1>Salut, \(user?.prenom ?? "Champion") !</h1>
                    <p>Score : <strong>\(user?.scoreTotal ?? 0) XP</strong> | Grade : \(user?.niveau.rawValue ?? "")</p>
                </hgroup>
                
                <article>
                    <header>🏋️ Mes Séances</header>
                    \(seances.isEmpty ? "<p>Aucune séance programmée.</p>" : "")
                    \(seances.map { seance in
                    """
                    <div class="card-workout">
                        <div class="grid">
                            <div>
                                <strong>\(seance.titre)</strong><br>
                                <small>\(seance.dateSeance.formatted(date: .abbreviated, time: .omitted))</small>
                            </div>
                            <div style="text-align: right;">
                                \(seance.estValidee ? "✅ <ins>Complétée</ins>" : 
                                """
                                <div style="display: flex; gap: 10px; justify-content: flex-end;">
                                    <form method='POST' action='/seance/valider/\(seance.id ?? 0)'>
                                        <input type='hidden' name='user' value='\(currentLogin)'>
                                        <button class='primary' style='padding:4px 12px;'>Valider la séance</button>
                                    </form>
                                    <form method='POST' action='/seance/delete/\(seance.id ?? 0)'>
                                        <input type='hidden' name='user' value='\(currentLogin)'>
                                        <button class='outline contrast' style='padding:4px 12px;'>Supprimer</button>
                                    </form>
                                </div>
                                """)
                            </div>
                        </div>
                    </div>
                    """
                    }.joined())
                </article>

                <article>
                    <header>📅 Planifier une nouvelle séance</header>
                    <form action="/seance/add" method="POST">
                        <input type="hidden" name="user" value="\(currentLogin)">
                        <div class="grid">
                            <input name="titre" placeholder="Ex: Séance Pectoraux" required>
                            <input type="date" name="date" required>
                        </div>
                        
                        <label>Sélectionnez vos exercices :</label>
                        <div class="grid-selection">
                            \(exercicesDisponibles.map { exo in
                            """
                            <label class="check-item">
                                <input type="checkbox" name="exo_\(exo.id ?? 0)" value="\(exo.id ?? 0)">
                                <span>\(exo.nom) <br><small style="color:var(--primary)">\(exo.musclePrincipal)</small></span>
                            </label>
                            """
                            }.joined())
                        </div>
                        <br>
                        <button type="submit" class="contrast">Créer ma séance personnalisée</button>
                    </form>
                </article>
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
                <h2>Profil de \(user.prenom)</h2>
                <div class="grid">
                    <div><label>Poids</label><strong>\(user.poids) kg</strong></div>
                    <div><label>Taille</label><strong>\(user.taille) cm</strong></div>
                    <div><label>IMC</label><strong>\(user.imc)</strong></div>
                </div>
                <hr>
                <p>Objectif actuel : <strong>\(user.objectif)</strong></p>
            </article>
            """
        html += footer()
        return html
    }
}
