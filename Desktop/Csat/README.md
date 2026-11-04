# Guide mobile des prestations CNPS

Application Flask mobile-first installable (PWA) pour consulter les prestations,
contacter la CNPS, déposer une réclamation et partager le guide par lien.
Le portail ne demande aucun compte ni mot de passe.

> **À valider avant publication :** le texte marqué « À VALIDER » a été rédigé
> pour cette maquette. Les informations de prestations sont celles de la maquette
> HTML fournie et doivent être validées avant tout usage officiel. Les brochures
> PDF téléchargeables sont les documents fournis pour la retraite, la maternité,
> les accidents du travail et l’affiliation des entreprises. Les brochures des
> allocations familiales, du RSTI et la brochure générale restent à fournir.
> Le numéro WhatsApp de démonstration (`2250000000000`) doit être remplacé avant
> la mise en ligne.

## Prérequis

- Python 3.11 ou supérieur
- pip

## Installation et lancement local (Windows PowerShell)

Depuis le dossier du projet :

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
$env:SECRET_KEY = python -c "import secrets; print(secrets.token_hex(32))"
python app.py
```

Ouvrir ensuite <http://127.0.0.1:5000>. La base SQLite est créée au premier
lancement dans `instance/reclamations.sqlite3`. Pour définir un autre
emplacement, renseignez `DATABASE_PATH`. Les réclamations contiennent des
données personnelles : protégez l’accès à cette base et définissez une clé
`SECRET_KEY` stable, longue et privée en production.

Le contenu éditorial et l’association entre chaque prestation et sa brochure
sont définis dans `data/contenu.json`. Une prestation n’affiche un bouton de
téléchargement que lorsqu’un PDF correspondant est disponible dans
`static/brochures/`. Les brochures des allocations familiales, du RSTI et la
brochure générale ne sont pas incluses : il faut fournir leurs PDF avant de
proposer leur téléchargement.

## Utilisation sans connexion Internet

La première ouverture et l’installation du portail nécessitent une connexion
Internet. Après cette première visite, choisissez **Installer** si le navigateur
le propose : les rubriques, la recherche, les contacts, les brochures et les
pages principales sont alors conservés sur l’appareil et restent consultables
hors connexion. Une réclamation rédigée hors connexion est conservée sur
l’appareil, avec son numéro de suivi, puis envoyée automatiquement quand la
connexion revient. Elle reste en attente si le portail ne peut pas être joint.
Évitez de déposer une réclamation depuis un appareil partagé.

Le fonctionnement hors connexion complet nécessite un hébergement HTTPS
(`localhost` est accepté pour les essais). Un QR code imprimé ne peut pas
charger le portail sur un téléphone qui n’a jamais ouvert ou installé le site et
qui n’a pas accès à Internet.

## Générer le QR code

Le QR code est un support autonome, distinct des pages du portail. Son scan ouvre
directement l’adresse publique de votre portail. Configurez cette URL HTTPS
avant de générer les fichiers. Le script produit une image PNG haute résolution,
un SVG et une page HTML autonome à imprimer, avec correction d’erreur H. Il
ajoute le logo fourni au centre du PNG si `static/cnps_logo.jpeg` est présent.

```powershell
$env:URL_PUBLIQUE = "https://votre-portail-cnps.onrender.com"
python generer_qr.py
```

Les fichiers produits sont `static/qr_cnps.png`, `static/qr_cnps.svg` et
`qr_cnps.html` à la racine du projet. Ouvrez `qr_cnps.html` dans un navigateur
pour imprimer ou enregistrer le support ; il ne fait pas partie de l’interface
du portail. Le scan ouvre directement l’adresse `URL_PUBLIQUE`, sans afficher
une page intermédiaire. Remplacez l’exemple par l’adresse publique réelle de
votre portail après son déploiement. Un QR contenant `127.0.0.1` ou `localhost`
ne fonctionnera que sur l’appareil qui héberge le serveur ; le générateur refuse
ces adresses et exige une URL HTTPS publique. Après tout changement de
destination, régénérez les fichiers.

## Déploiement sur Render

Le fichier `render.yaml` prépare le service web et un disque persistant pour
que les réclamations ne disparaissent pas lors d’un redéploiement. Dans Render,
créez un **Blueprint** depuis le dépôt GitHub et sélectionnez
`Desktop/Csat/render.yaml`. Vérifiez le tarif du service et du disque affiché
par Render avant de confirmer : le stockage persistant nécessite une offre
payante.

Après le déploiement, Render attribue une adresse HTTPS au portail. Pour créer
le QR code qui ouvre ce portail, exécutez localement, en remplaçant l’exemple
par cette adresse :

```powershell
$env:URL_PUBLIQUE = "https://votre-portail.onrender.com"
python generer_qr.py
```

Le QR code ouvre le portail déployé, et non le site officiel CNPS ni une adresse
locale. Les plaintes sont conservées dans `/var/data/reclamations.sqlite3`.
Gardez la base et les sauvegardes privées.

## Vérifications locales

```powershell
python -m compileall -q app.py generer_qr.py
python -m pip install -r requirements.txt
```

Contrôlez ensuite l’accueil, les trois rubriques, la page des contacts,
`/reclamation`, l’envoi d’une réclamation et chaque bouton de
téléchargement PDF disponible.
