#!/bin/bash

# Aficher l'output en couleur
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
function show_usage() {
	printf "Usage: $0 url (http://host.domain:port/user/password)\n"
	printf "\n"
	printf "Options:\n"
	printf " -h|--help, Print help\n"

	return 0
}

if [[ $1 == "--help"   ]] || [[ $1 == "-h"   ]]; then
	show_usage
elif  [ -z "$1" ]; then
	printf ""${RED}"Erreur"${NC}" url manquante\n"
	show_usage
else
	### Code du parseur d'url ###
	# extraire le protocol
	proto="$(echo $1 | grep :// | sed -e's,^\(.*://\).*,\1,g')"
	# enlever le protocol
	url="$(echo ${1/$proto/})"
	# Determiner si il y a une catégorie
	urltype="$(echo $url | grep / | cut -d/ -f2)"

	# si $urltype est egal à live
	if [ $urltype = live ]; then
		# alors $streamtype est live
		streamtype="live"
		# si $urltype est egal à movie
	elif [ $urltype = movie ]; then
		# alors $streamtype est movie
		streamtype="movie"
	else
		# Sinon la variable est vide
		streamtype=""
	fi
	# extraire le user
	# si la variable $streamtype est vide
	if [ -z "$streamtype" ]; then
		# Alors $user se trouvera en deuxieme position
		user="$(echo $url | grep / | cut -d/ -f2)"
	else
		# Sinon en troisieme position
		user="$(echo $url | grep / | cut -d/ -f3)"
	fi

	# Extraire le password
	# si la variable $streamtype est vide
	if [ -z "$streamtype" ]; then
		# Alors $password se trouvera en troisieme position
		password="$(echo $url | grep / | cut -d/ -f3)"
	else
		# Sinon en quatrieme position
		password="$(echo $url | grep / | cut -d/ -f4)"
	fi

	# extraire le host et le port
	hostport="$(echo ${url/$user/} | cut -d/ -f1)"
	# extraire le host
	host="$(echo $hostport | sed -e 's,:.*,,g')"
	# by request - try to extract the port
	port="$(echo $hostport | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
	# extract the path (if any)
	# extraire uniquement la chaine

	# Extraire la chaine du lien
	# si la variable $streamtype est vide
	if [ -z "$streamtype" ]; then
		channel="$(echo $url | grep / | cut -d/ -f4-)"
	else
		channel="$(echo $url | grep / | cut -d/ -f5-)"
	fi

	# URL sans la chaine
	if [ -z "$streamtype" ]; then
		urlchanless="$(echo $proto$hostport/$user/$password)"
	else
		urlchanless="$(echo $proto$hostport/$streamtype/$user/$password)"
	fi

	if [ -z "$streamtype" ]; then
		path="$(echo $user/$password)"
	else
		path="$(echo $streamtype/$user/$password)"
	fi

	### Fin du Code du parseur d'url ###

	# générer l'url pour avoir la playlist
	urlplaylist="$proto$hostport/get.php?username=$user&password=$password&type=m3u"
	# url pour avoir le panel_api
	PanelAPI="$proto$hostport/panel_api.php?username=$user&password=$password"

	# obtenir les info du compte
	# la date d'expiration
	exp_date="$(curl -s "$PanelAPI" | date -d @$(jq ".user_info.exp_date" | tr -d \"))"
	# savoir si le compte est actif ou clotûré
	user_status="$(curl -s "$PanelAPI" | jq ".user_info.status" | tr -d \")"
	# la date de création
	Account_creation="$(curl -s "$PanelAPI" | date -d @$(jq ".user_info.created_at" | tr -d \"))"
	# Connaitre si le compte est trial
	ISTRIAL_Check="$(curl -s "$PanelAPI" | jq ".user_info.is_trial" | tr -d \")"
	# le nomde de connection actuel
	Current_Con="$(curl -s "$PanelAPI" | jq ".user_info.active_cons" | tr -d \")"
	# Le nombre maximum de connexions
	Max_Con="$(curl -s "$PanelAPI" | jq ".user_info.max_connections" | tr -d \")"

	if [[ $Current_Con -gt $Max_Con ]]; then
		Color="${RED}"
	else
		Color="${GREEN}"
	fi

	if [[ $user_status == "Active" ]]; then
		Color2="${GREEN}"
	else
		Color2="${RED}"
	fi

	if [[ $ISTRIAL_Check == 0 ]]; then
		Account_type="Enregistré"
	elif [[ $Account_type == 1 ]]; then
		Account_type="Démonstration"
	else
		Account_type="Inconnu"
	fi

	# affichage des infos

	printf "\n\t=========================================================================\n"
	printf "\t||\t\t\t      Détails du compte: \t\t\t||\n"
	printf "\t||\tDate de création du compte: $Account_creation\t||\n"
	printf "\t||\tDate d'expiration du compte: $exp_date\t||\n"
	printf "\t||\t\t\t  Status du compte: "$Color2"$user_status"${NC}". \t\t\t||\n"
	printf "\t||\t     Nombre de connexions: "$Color"$Current_Con"${NC}" sur "$Color"$Max_Con"${NC}" autorisées. \t\t||\n"
	printf "\t||\t\t\t  Type de compte: $Account_type. \t\t\t||\n"
	printf "\t=========================================================================\n"
	printf "\n"
fi
