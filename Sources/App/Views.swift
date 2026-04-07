import Foundation

struct Views {

    // MARK: - Composants Internes (Privés)

    private static func header(title: String, currentUser: String? = nil, showNav: Bool = true)
        -> String
    {
        let userSuffix = currentUser != nil ? "?user=\(currentUser!)" : ""

        let navigation =
            showNav
            ? """
                <nav class="container">
                    <ul><li><strong style="font-size:1.5rem;">Protx Training</strong></li></ul>
                    <ul>
                        <li><a href="/\(userSuffix)" style="color: #0076ff;">Tableau de Bord</a></li>
                        <li><a href="/profil\(userSuffix)" style="color: #0076ff;">Mon Profil</a></li>
                        <li><a href="/login" style="color: #ff5252;">Déconnexion</a></li>
                    </ul>
                </nav>
            """ : ""

        return """
            <!DOCTYPE html>
            <html lang="fr" data-theme="dark">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                <title>\(title) - ProtX Training</title>
                <style>
                    body { font-family: 'Inter', sans-serif; background-color: #0b0b0b; }
                    a { color: #0076ff; }
                    .card-workout { border-left: 4px solid #444; padding: 1.5rem; margin-bottom: 2rem; background: #161616; border-radius: 12px; }
                    
                    /* GRILLE UNIFIÉE : On augmente la taille minimum à 220px pour que ce soit grand */
                    .exo-grid, .grid-selection { 
                        display: grid; 
                        grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); 
                        gap: 1.5rem !important; 
                        margin-top: 1rem; 
                    }
                    
                    /* BOXES IDENTIQUES : On verrouille la largeur et la hauteur pour le haut ET le bas */
                    .exo-card-mini, .check-item { 
                        background: #222; 
                        border-radius: 10px; 
                        border: 1px solid #333; 
                        display: flex; 
                        flex-direction: column; 
                        height: 240px !important; /* Hauteur totale augmentée */
                        width: 100% !important;
                        overflow: hidden;
                        position: relative;
                        margin: 0 !important;
                        padding: 0 !important;
                        cursor: pointer;
                        box-sizing: border-box;
                    }

                    /* PHOTOS : Taille verrouillée et identique partout */
                    .exo-img { 
                        width: 100%; 
                        height: 150px !important; /* Photo plus grande */
                        object-fit: cover; 
                        border-bottom: 1px solid #333;
                        display: block;
                    }

                    /* CONTENU TEXTE : Aligné au centre */
                    .exo-info, .check-content { 
                        padding: 10px; 
                        text-align: center; 
                        display: flex; 
                        flex-direction: column; 
                        justify-content: center; 
                        align-items: center;
                        flex-grow: 1;
                        width: 100%;
                    }

                    .exo-name { 
                        font-size: 1rem; 
                        font-weight: bold; 
                        color: #fff;
                        width: 95%;
                        white-space: nowrap;
                        overflow: hidden;
                        text-overflow: ellipsis; 
                        margin-bottom: 4px;
                    }

                    .exo-points { font-size: 0.85rem; color: #888; }

                    /* ZONE DE SÉLECTION (BAS) */
                    .grid-selection { 
                        max-height: 600px; 
                        overflow-y: auto; 
                        padding: 20px; 
                        background: #111; 
                        border-radius: 8px; 
                        border: 1px solid #222; 
                    }
                    
                    /* CHECKBOX : Positionnée par-dessus la photo */
                    .check-item input[type="checkbox"] {
                        position: absolute;
                        top: 12px;
                        left: 12px;
                        z-index: 10;
                        margin: 0;
                        width: 22px;
                        height: 22px;
                    }

                    .check-item:has(input:checked) {
                        border-color: #0076ff;
                        background: #1a2635;
                    }
                    
                    nav.container { border-bottom: 1px solid #222; margin-bottom: 2rem; }
                    button { background-color: #2b2b2b; border: 1px solid #444; color: white; }
                    button:hover { background-color: #3b3b3b; }
                </style>
            </head>
            <body>
                \(navigation)
                <main class="container">
            """
    }

    private static func footer() -> String {
        return
            "</main><footer class='container' style='text-align:center; padding: 2rem; color:#666;'><small>&copy; 2026 ProtX Training</small></footer></body></html>"
    }

    // MARK: - Pages Publiques

    static func login(error: Bool = false) -> String {
        let errorMsg =
            error ? "<p style='color: #ff5252;'>Identifiant ou mot de passe incorrect.</p>" : ""
        return """
            \(header(title: "Connexion", showNav: false))
            <article style="max-width: 400px; margin: 4rem auto; background: #161616;">
                <header style="text-align:center;"><strong>Connexion</strong></header>
                \(errorMsg)
                <form method="POST" action="/login">
                    <input type="text" name="login" placeholder="Identifiant" required>
                    <input type="password" name="password" placeholder="Mot de passe" required>
                    <button type="submit">Se connecter</button>
                </form>
                <footer style="text-align: center;">Pas de compte ? <a href="/register">S'inscrire</a></footer>
            </article>
            \(footer())
            """
    }

    static func register() -> String {
        return """
            \(header(title: "Inscription", showNav: false))
            <article style="max-width: 600px; margin: 2rem auto; background: #161616;">
                <header style="text-align:center;"><strong>Créer mon profil</strong></header>
                <form method="POST" action="/register">
                    <div class="grid"><input type="text" name="prenom" placeholder="Prénom" required><input type="text" name="nom" placeholder="Nom" required></div>
                    <input type="text" name="login" placeholder="Identifiant" required>
                    <input type="password" name="password" placeholder="Mot de passe" required>
                    <div class="grid"><input type="number" name="poids" placeholder="Poids (kg)" step="0.1"><input type="number" name="taille" placeholder="Taille (cm)"></div>
                    <select name="objectif">
                        <option>Remise en forme</option><option>Prise de masse</option><option>Perte de poids</option><option>Performance</option>
                    </select>
                    <button type="submit">Démarrer l'aventure</button>
                </form>
            </article>
            \(footer())
            """
    }

    // MARK: - Dashboard Principal (Index)

    static func index(
        utilisateurs: [Utilisateur], seances: [Seance], exercicesDisponibles: [Exercice]
    ) -> String {
        let user = utilisateurs.first
        let currentLogin = user?.login ?? ""

        var seancesHTML = ""
        for seance in seances {
            let statusColor = seance.estValidee ? "#4CAF50" : "#444"
            var exosInSeanceHTML = ""
            for exo in seance.exercices {
                exosInSeanceHTML += """
                    <div class="exo-card-mini">
                        <img src="/\(exo.imageURL)" alt="\(exo.nom)" class="exo-img" onerror="this.src='https://placehold.co/400x250?text=Exercice'">
                        <div class="exo-info">
                            <span class="exo-name">\(exo.nom)</span>
                            <span class="exo-points">+\(exo.scoreCalories) XP</span>
                        </div>
                    </div>
                    """
            }

            let buttons =
                seance.estValidee
                ? "<span style='color:#4CAF50; font-weight:bold;'>✅ validée</span>"
                : """
                <div style="display: flex; gap: 8px;">
                    <form method='POST' action='/seance/valider/\(seance.id ?? 0)' style='margin:0;'>
                        <input type='hidden' name='user' value='\(currentLogin)'>
                        <button style='padding:5px 15px; font-size: 0.8rem; background:#4CAF50; border:none;'>Valider</button>
                    </form>
                    <form method='POST' action='/seance/delete/\(seance.id ?? 0)' style='margin:0;'>
                        <input type='hidden' name='user' value='\(currentLogin)'>
                        <button class='outline contrast' style='padding:5px 15px; font-size: 0.8rem;'>Supprimer</button>
                    </form>
                </div>
                """

            seancesHTML += """
                <div class="card-workout" style="border-left-color: \(statusColor);">
                    <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1rem;">
                        <div><h3 style="margin:0;">\(seance.titre)</h3><small>\(seance.scoreSeance) XP</small></div>
                        \(buttons)
                    </div>
                    <div class="exo-grid">\(exosInSeanceHTML)</div>
                </div>
                """
        }

        var selectionExosHTML = ""
        for exo in exercicesDisponibles {
            selectionExosHTML += """
                <label class="check-item">
                    <input type="checkbox" name="exo_\(exo.id ?? 0)" value="\(exo.id ?? 0)">
                    <img src="/\(exo.imageURL)" class="exo-img" onerror="this.src='https://placehold.co/400x250?text=Exercice'">
                    <div class="check-content">
                        <span class="exo-name">\(exo.nom)</span>
                        <span class="exo-points">\(exo.scoreCalories) XP</span>
                    </div>
                </label>
                """
        }

        var finalHTML = header(title: "Dashboard", currentUser: currentLogin)
        finalHTML += """
            <hgroup><h1>Salut, \(user?.prenom ?? "Champion") !</h1><p>Niveau : \(user?.niveau.rawValue ?? "Débutant") | <strong>\(user?.scoreTotal ?? 0) XP</strong></p></hgroup>

            <section>
                <h2>Mes Séances</h2>
                \(seancesHTML.isEmpty ? "<p style='color:#666;'>Aucune séance à afficher.</p>" : seancesHTML)
            </section>

            <section style="margin-top: 3rem;">
                <h2>Planifier une séance</h2>
                <form action="/seance/add" method="POST">
                    <input type="hidden" name="user" value="\(currentLogin)">
                    <div class="grid">
                        <label>Titre <input name="titre" placeholder="Ex: Leg Day" required></label>
                        <label>Date <input type="date" name="date" required></label>
                    </div>
                    <label>Choisir les exercices :</label>
                    <div class="grid-selection">\(selectionExosHTML)</div>
                    <button type="submit" style="margin-top:1.5rem;">Créer ma séance</button>
                </form>
            </section>
            """
        finalHTML += footer()
        return finalHTML
    }

    static func profil(user: Utilisateur) -> String {
        return """
            \(header(title: "Mon Profil", currentUser: user.login))
            <article style="background: #161616; max-width: 800px; margin: 0 auto;">
                <header><h2>Modifier mon profil</h2></header>
                
                <form method="POST" action="/profil/update">
                    <input type="hidden" name="login" value="\(user.login)">
                    
                    <div class="grid">
                        <label>Prénom
                            <input type="text" name="prenom" value="\(user.prenom)" required>
                        </label>
                        <label>Nom
                            <input type="text" name="nom" value="\(user.nom)" required>
                        </label>
                    </div>

                    <div class="grid">
                        <label>Poids (kg)
                            <input type="number" name="poids" step="0.1" value="\(user.poids)" required>
                        </label>
                        <label>Taille (cm)
                            <input type="number" name="taille" value="\(user.taille)" required>
                        </label>
                    </div>

                    <div style="margin-top: 1rem; padding: 1rem; background: #222; border-radius: 8px; text-align: center;">
                        <strong>Indice de Masse Corporelle (IMC) : \(user.imc)</strong>
                    </div>

                    <button type="submit" style="margin-top: 2rem;">Enregistrer les modifications</button>
                </form>
            </article>
            \(footer())
            """
    }
}
