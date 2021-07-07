# IPTV-Utils

## News
Une grosse Update est en cours:
- Refonte de account checker, fonctionne avec une url de playlist et une liste d'url également.
- Account checker sera capable également de détecter si l'url est un compte Xtream ou non.
- refonte de M3U Grabber, permet de télécharger plusieurs playlists, les parser, les concaténer et les trier.
- Nouveau script qui permetra de construire un fichier (surement json) pour conservé les liens valides et tenir à jour la playlist.
- Ajout d'un systeme de contournement pour les serveurs qui refuse les demande de curl (user-agent).
- Script de construction de playlist en fonction du logiciel utilisé et du réseau (vlc, kodi, mpv, etc...)
- intégration d'un script de vérification des liens
- Ajout de fonction diverses tel la détection de probleme serveur (erreur 404, 403 ou autre) et le contournement.

Le bruteforceur Orange ne fonctionne plus, les serveurs ont changé et le m3u8 n'est plus utilisé, c'est mpd et windevine maintenant (je crois).


## collection de script bash (linux) pour fichiers M3U.
Comme j'en avais marre de jongler avec les URL pour obtenir les playlists et les mettre à jours, j'ai décidé de créer un script bash.

#### Logiciels requis:
requière wget, recode, gawk, curl, ffmpeg, ffprobe et jq

## Get-Playlist
Script pour obtenir la playlist à partir d'une url type http://host.domain:port/user/password/channel ou http://host.domain:port/live|movie/user/password/channel

### usage:
- get-playlist.sh http://host.domain/user/password/channel
- Fichier de sortie: playlist_host.domain-MM-DD-YYYY.m3u

#### ToDo-List
- ajouter des options pour:
- juste afficher l'url
- Consulter les info du compte en local
- ...

## M3U-Optimizer

A venir

## M3U-Grabber

- Permet de télécharger la liste des chaines disponible depuis iptvcat depuis https://github.com/eliashussary/iptvcat-scraper et de générer une playlist en éléminant les chaine déclarées Offline.

#### ToDo-List
- Renommer les chaine correctement
- Leur donner in ID
- Leur donner une icone
- Leur donner l'url de l'EPG

## Account Checker
- Permet de vérifier et d'obtenir les information d'un compte à partir d'une url http://host.domain:port/user/password(/channel) ou http://host.domain:port/live/user/password(channel)
- Il affiche :
- la date de création.
- la date d'expiration.
- le statut du compte (activé ou désactivé).
- le type de compte (enregistré ou trial) si supporté par le seveur.
- le nombre de connection en cours.
- le nombre maximum de connexion autorisé.

     

## URL_Parser

- Analyse, néttoie et décompose une url.
- Détecte les urls des chaines, des requetes Xtream et les adresse des chaîne Xtream.
### Utilisation:

url_parser.sh "http://mon/url"

! ATTENTION ! Veuillez mettre votre url en guillemets (double quote)
