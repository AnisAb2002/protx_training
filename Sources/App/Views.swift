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
                    :root { --primary: #d81b60; --primary-hover: #ad1457; }
                    body { font-family: 'Inter', sans-serif; background-color: #0b0b0b; }
                    h1, h2, h3 { font-weight: 900; text-transform: uppercase; letter-spacing: -1px; }
                    .card-workout { border-left: 4px solid var(--primary); padding: 1.5rem; margin-bottom: 2rem; background: #161616; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.3); }
                    .exo-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 1rem; margin-top: 1rem; }
                    .exo-card-mini { background: #222; border-radius: 8px; overflow: hidden; border: 1px solid #333; transition: transform 0.2s; }
                    .exo-card-mini:hover { transform: translateY(-3px); border-color: var(--primary); }
                    .exo-img { width: 100%; height: 80px; object-fit: cover; filter: grayscale(30%); }
                    .exo-info { padding: 8px; text-align: center; }
                    .exo-name { font-size: 0.8rem; font-weight: bold; display: block; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
                    .exo-points { font-size: 0.7rem; color: var(--primary); font-weight: bold; }
                    .grid-selection { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 1rem; max-height: 400px; overflow-y: auto; padding: 15px; border: 1px solid #333; border-radius: 8px; background: #111; }
                    .check-item { display: flex; align-items: center; gap: 10px; background: #222; padding: 10px; border-radius: 6px; cursor: pointer; border: 1px solid #333; }
                    nav.container { border-bottom: 1px solid #222; margin-bottom: 2rem; }
                </style>
            </head>
            <body>
                <nav class="container">
                    <ul><li><strong style="color:var(--primary); font-size:1.5rem;">PROTX</strong></li></ul>
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
        return
            "</main><footer class='container' style='text-align:center; padding: 2rem; color:#666;'><small>&copy; 2026 ProtX Training - Forgez votre corps</small></footer></body></html>"
    }

    // MARK: - Connexion
    static func login(error: Bool = false) -> String {
        let errorMsg =
            error
            ? "<p style='color: #ff5252; background: rgba(255,82,82,0.1); padding: 10px; border-radius: 5px;'>Identifiant ou mot de passe incorrect.</p>"
            : ""
        return """
            <!DOCTYPE html>
            <html lang="fr" data-theme="dark"><head><meta charset="UTF-8"><link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"><title>Connexion</title></head>
            <body class="container" style="display: flex; height: 100vh; align-items: center; justify-content: center;">
                <article style="width: 400px; background: #161616;"><header style="text-align:center;"><strong>CONNEXION</strong></header>\(errorMsg)
                <form method="POST" action="/login"><input type="text" name="login" placeholder="Identifiant" required><input type="password" name="password" placeholder="Mot de passe" required><button type="submit" style="background: #d81b60; border:none;">Se connecter</button></form>
                <footer style="text-align: center;">Pas de compte ? <a href="/register" style="color:#d81b60;">S'inscrire</a></footer></article>
            </body></html>
            """
    }

    // MARK: - Inscription
    static func register() -> String {
        return """
            <!DOCTYPE html>
            <html lang="fr" data-theme="dark"><head><meta charset="UTF-8"><link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"><title>Inscription</title></head>
            <body class="container" style="display: flex; min-height: 100vh; align-items: center; justify-content: center; padding: 2rem 0;"><article style="width: 600px; background: #161616;"><header style="text-align:center;"><strong>CRÉER MON PROFIL</strong></header>
                <form method="POST" action="/register">
                    <div class="grid"><input type="text" name="prenom" placeholder="Prénom" required><input type="text" name="nom" placeholder="Nom" required></div>
                    <input type="text" name="login" placeholder="Identifiant" required><input type="password" name="password" placeholder="Mot de passe" required><hr>
                    <div class="grid"><input type="number" name="poids" placeholder="Poids (kg)" step="0.1" required><input type="number" name="taille" placeholder="Taille (cm)" required></div>
                    <select name="objectif" required>
                        <option value="" disabled selected>Choisir mon objectif...</option>
                        <option value="Remise en forme">Remise en forme</option>
                        <option value="Prise de masse">Prise de masse</option>
                        <option value="Perte de poids">Perte de poids</option>
                        <option value="Performance">Performance / Force</option>
                    </select>
                    <button type="submit" style="background: #d81b60; border:none;">Démarrer l'aventure</button>
                </form>
                <footer style="text-align: center;">Déjà un compte ? <a href="/login" style="color:#d81b60;">Se connecter</a></footer>
            </article></body></html>
            """
    }

    // MARK: - Tableau de Bord
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
                    <p>Score : <strong style="color:var(--primary)">\(user?.scoreTotal ?? 0) XP</strong> | Grade : \(user?.niveau.rawValue ?? "")</p>
                </hgroup>
                
                <article style="background: transparent; border:none; padding:0;">
                    <h2 style="font-size: 1.2rem; margin-bottom: 1.5rem;">🏋️ Mes Séances</h2>
                    \(seances.isEmpty ? "<p style='color:#666;'>Aucune séance programmée. Commencez par en créer une ci-dessous !</p>" : "")
                    
                    \(String(seances.map { seance in
                        let statusColor = seance.estValidee ? "#4CAF50" : "#d81b60"
                        return """
                        <div class="card-workout" style="border-left-color: \(statusColor);">
                            <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1rem;">
                                <div>
                                    <h3 style="margin:0; font-size: 1.3rem;">\(seance.titre)</h3>
                                    <small style="color:#888;">\(seance.dateSeance.formatted(date: .abbreviated, time: .omitted)) — <strong>\(seance.scoreSeance) XP</strong></small>
                                </div>
                                <div style="display: flex; gap: 8px;">
                                    \(seance.estValidee ? "<span style='color:#4CAF50; font-weight:bold;'>✅ COMPLÉTÉE</span>" : 
                                    """
                                    <form method='POST' action='/seance/valider/\(seance.id ?? 0)' style='margin:0;'>
                                        <input type='hidden' name='user' value='\(currentLogin)'>
                                        <button class='primary' style='padding:5px 15px; font-size: 0.8rem; background:#4CAF50; border:none;'>Valider</button>
                                    </form>
                                    <form method='POST' action='/seance/delete/\(seance.id ?? 0)' style='margin:0;'>
                                        <input type='hidden' name='user' value='\(currentLogin)'>
                                        <button class='outline contrast' style='padding:5px 15px; font-size: 0.8rem;'>Supprimer</button>
                                    </form>
                                    """)
                                </div>
                            </div>

                            <div class="exo-grid">
                                \(String(seance.exercices.map { exo in
                                """
                                <div class="exo-card-mini">
                                    <img src="/\(exo.imageURL)" alt="\(exo.nom)" class="exo-img" onerror="this.src='https://placehold.co/200x100?text=Exercice'">
                                    <div class="exo-info">
                                        <span class="exo-name">\(exo.nom)</span>
                                        <span class="exo-points">+\(exo.scoreCalories) XP</span>
                                    </div>
                                </div>
                                """
                                }.joined()))
                            </div>
                        </div>
                        """
                    }.joined()))
                </article>

                <article style="margin-top: 3rem;">
                    <header>📅 Planifier une nouvelle séance</header>
                    <form action="/seance/add" method="POST">
                        <input type="hidden" name="user" value="\(currentLogin)">
                        <div class="grid">
                            <label>Titre de la séance
                                <input name="titre" placeholder="Ex: Séance Pectoraux" required>
                            </label>
                            <label>Date prévue
                                <input type="date" name="date" required>
                            </label>
                        </div>
                        
                        <label>Sélectionnez vos exercices :</label>
                        <div class="grid-selection">
                            \(String(exercicesDisponibles.map { exo in
                            """
                            <label class="check-item">
                                <input type="checkbox" name="exo_\(exo.id ?? 0)" value="\(exo.id ?? 0)" style="margin:0;">
                                <span><strong>\(exo.nom)</strong><br><small style="color:var(--primary)">\(exo.musclePrincipal) • \(exo.scoreCalories) XP</small></span>
                            </label>
                            """
                            }.joined()))
                        </div>
                        <br>
                        <button type="submit" class="contrast" style="width:100%;">Créer ma séance personnalisée</button>
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
            <article style="background: #161616; border-radius: 12px;">
                <hgroup>
                    <h2>Profil de \(user.prenom)</h2>
                    <p>Membre de la communauté ProtX Training</p>
                </hgroup>
                <div class="grid" style="text-align:center; margin-top:2rem;">
                    <div style="background:#222; padding:20px; border-radius:10px;"><label style="color:#888;">Poids</label><br><strong style="font-size:1.5rem;">\(user.poids) kg</strong></div>
                    <div style="background:#222; padding:20px; border-radius:10px;"><label style="color:#888;">Taille</label><br><strong style="font-size:1.5rem;">\(user.taille) cm</strong></div>
                    <div style="background:#222; padding:20px; border-radius:10px;"><label style="color:#888;">IMC</label><br><strong style="font-size:1.5rem;">\(user.imc)</strong></div>
                </div>
                <hr style="margin: 2rem 0;">
                <p>Objectif actuel : <strong style="color:var(--primary)">\(user.objectif)</strong></p>
                <p>Score total accumulé : <strong>\(user.scoreTotal) XP</strong></p>
            </article>
            """
        html += footer()
        return html
    }
}
