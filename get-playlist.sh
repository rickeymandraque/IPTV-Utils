#!/bin/bash

function show_usage() {
	printf "Usage: $0 url\n"
	printf "\n"
	printf "Options:\n"
	printf " -h|--help, Print help\n"

	return 0
}

if [[ $1 == "--help"   ]] || [[ $1 == "-h"   ]]; then
	show_usage
elif  [ -z "$1" ]; then
	echo "url manquante"
	show_usage
else

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

	# générer l'url pour avoir la playlist
	urlplaylist="$proto$hostport/get.php?username=$user&password=$password&type=m3u"
fi

if [ -z "$1"  ] || [[ $1 == "--help"   ]] || [[ $1 == "-h"   ]]; then
	echo
else
	wget $urlplaylist -O playlist_$host-$(date +"%m-%d-%Y").m3u
fi
