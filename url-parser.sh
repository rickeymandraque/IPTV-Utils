#!/bin/bash

# Following regex is based on https://tools.ietf.org/html/rfc3986#appendix-B with
# additional sub-expressions to split authority into userinfo, host and port
#
readonly URI_REGEX='^(([^:/?#]+):)?(//((([^:/?#]+)@)?([^:/?#]+)(:([0-9]+))?))?(/([^?#]*))(\?([^#]*))?(#(.*))?'
#                    ↑↑            ↑  ↑↑↑            ↑         ↑ ↑            ↑ ↑        ↑  ↑        ↑ ↑
#                    |2 scheme     |  ||6 userinfo   7 host    | 9 port       | 11 rpath |  13 query | 15 fragment
#                    1 scheme:     |  |5 userinfo@             8 :…           10 path    12 ?…       14 #…
#                                  |  4 authority
#                                  3 //…

RED='\033[38;5;160m' #ex echo -e "${RED} ALERT"
NC='\033[0m'    #ex echo -e "${NC} Normal"
GREEN='\033[38;1;32m'   #ex echo -e "${GREEN} OK"
YELLOW='\033[38;5;226m' #ex echo -e "${YELLOW} Warning"

function show_usage() {
	printf "Usage: $0 \"url\" (\"http://host.domain:port/user/password\")\n"
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
	# virer les trucs innutile du genre ?checkedby:iptvcat.com
	if [[ $1 == *"?checkedby:iptvcat.com" ]]; then
		filtre="$(echo $1 | grep "$\?checkedby:iptvcat.com" | cut -d? -f1)"
		echo -e "${YELLOW}l'url à été filtrée${NC}"
	else
		echo -e "${GREEN}l'url n'a pas été filtrée${NC}"
		filtre="$1"
	fi
	# extraire le protocol avec :
	full_proto="$([[ $filtre =~ $URI_REGEX ]] && echo "${BASH_REMATCH[1]}")"
	# extraire le protocol
	proto="$([[ $filtre =~ $URI_REGEX ]] && echo "${BASH_REMATCH[2]}")"
	# extraire le host et le port avec antislash
	full_hostport="$([[ $filtre =~ $URI_REGEX ]] && echo "${BASH_REMATCH[3]}")"
	# extraire le host et le port
	hostport="$([[ $filtre =~ $URI_REGEX ]] && echo "${BASH_REMATCH[4]}")"
	# extraire le host
	host="$([[ $filtre =~ $URI_REGEX ]] && echo "${BASH_REMATCH[7]}")"
	# on extrait le port
	port="$([[ $filtre =~ $URI_REGEX ]] && echo "${BASH_REMATCH[9]}")"
	# path avec antislash
	full_path="$([[ $filtre =~ $URI_REGEX ]] && echo "${BASH_REMATCH[10]}")"
	# path seul
	path="$([[ $filtre =~ $URI_REGEX ]] && echo "${BASH_REMATCH[11]}")"
	# requete avec ?
	full_query="$([[ $filtre =~ $URI_REGEX ]] && echo "${BASH_REMATCH[12]}")"
	# requete seule
	query="$([[ $filtre =~ $URI_REGEX ]] && echo "${BASH_REMATCH[13]}")"

	# url sans le protocol
	url="$hostport$full_path"

	# Determiner le type de l'url
	# pour france24
	if [[ $host == "static.france24.com" ]]; then
		urltype="france24"
		f24_dir="$(echo "$url" | grep / | cut -d/ -f2)"
		Stream_Container="$(echo "$url" | grep / | cut -d/ -f3)"
		urlchanless="$(echo "$full_proto$full_hostport/$f24_dir/$Stream_Container")"
		# pour rt-france
	elif [[ $host == "rt-france.secure.footprint.net" ]]; then
		urltype="rt_france"
		urlchanless="$(echo "$full_proto$full_hostport/")"
	# pour TV7 et TV3
	elif [[ $host == *"hdr-tv.com" ]]; then
		urltype="tv7-3"
	# pour le groupe tf1
	elif [[ $host == "tf1-hls-live-ssl.tf1.fr" ]]; then
		urltype="tf1"
	elif [[ $host == "tfx-hls-live-ssl.tf1.fr" ]]; then
		urltype="tfx"
	elif [[ $host == "tmc-hls-live-ssl.tf1.fr" ]]; then
		urltype="tmc"
	# pour détecter une requete de playlist
	elif [[ $path == "get.php"* ]]; then
		urltype="playlist_query"
	elif [[ $path == "player_api.php"* ]]; then
		urltype="player_query"
	elif [[ $path == "panel_api.php"* ]]; then
		urltype="panel_query"
	else
		urltype="$(echo "$url" | grep / | cut -d/ -f2)"
	fi

	# Determiner si il y a une catégorie
	if [[ $urltype == "tf1" ]] || [[ $urltype == "tfx" ]] || [[ $urltype == "tmc" ]]; then
		streamtype="groupe_tf1"
		tf1_dir="$(echo "$url" | grep / | cut -d/ -f3)"
		Stream_Container="$(echo "$url" | grep / | cut -d/ -f4)"
		urlchanless="$(echo "$full_proto$full_hostport/$urltype/$tf1_dir/$Stream_Container")"
	elif [[ $urltype == "france24" ]]; then
		streamtype="france24"
	elif [[ $urltype == "rt-france" ]]; then
		streamtype="rt-france"
	elif [[ $urltype == "tv7-3" ]]; then
		streamtype="tv7-3"
	elif [[ $urltype == "live" ]]; then
		# alors $streamtype est live
		streamtype="live"
		# si $urltype est egal à movie
	elif [[ $urltype == "movie" ]]; then
		# alors $streamtype est movie
		streamtype="movie"
	elif [[ $urltype == "playlist_query" ]] || [[ $urltype == "player_query" ]] || [[ $urltype == "panel_query" ]]; then
		streamtype="no_stream"
	else
		# Sinon la variable est vide
		streamtype=""
	fi

	# extraire le user et le password
	# si la variable $streamtype est vide
	if [ -z "$streamtype" ]; then
		#statements
		# Alors $user se trouvera en deuxieme position
		user="$(echo "$url" | grep / | cut -d/ -f2)"
		# Alors $password se trouvera en troisieme position
		password="$(echo "$url" | grep / | cut -d/ -f3)"
		# Extraire la chaine du lien
		channel="$(echo "$url" | grep / | cut -d/ -f4-)"
		# URL sans la chaine
		urlchanless="$(echo "$full_proto$full_hostport/$user/$password")"
		urlplaylist="$proto//$hostport/get.php?username=$user&password=$password&type=m3u"

	elif [[ $streamtype == "groupe_tf1" ]]; then
		user=""
		password=""
		urlplaylist=""

	elif [[ $streamtype == "france24" ]]; then
		user=""
		password=""
		channel="$(echo "$url" | grep / | cut -d/ -f4-)"
		urlplaylist=""

	elif [[ $streamtype == "rt_france" ]]; then
		user=""
		password=""
		channel="$path"
		urlplaylist=""

	else
		# Sinon user en troisieme position
		user="$(echo "$url" | grep / | cut -d/ -f3)"
		# Sinon password en quatrieme position
		password="$(echo "$url" | grep / | cut -d/ -f4)"
		channel="$(echo "$url" | grep / | cut -d/ -f5-)"
		urlchanless="$(echo "$full_proto$full_hostport/$streamtype/$user/$password")"
		urlplaylist="$proto//$hostport/get.php?username=$user&password=$password&type=m3u"
	fi

	if [[ $channel == *.* ]]; then
		extention="$(echo "${channel#*.}")"
	else
		extention=""
	fi
	if [ -n "$extention" ]; then
		Channel_noext="$(echo "$channel" | grep "\." | cut -d. -f1)"
	fi

	### Fin du Code du parseur d'url ###

	echo "  url entrée : $1"
	echo "  url filtrée : $filtre"
	echo "  proto: $proto://"
	echo "  url: $url"
	echo "  url type : $urltype"
	echo "  streamtype : $streamtype"
	echo "  user: $user"
	echo "  password : $password"
	echo "  Dossier TF1 : $tf1_dir"
	echo "  Dossier France24 : $f24_dir"
	echo "  Conteneur : $Stream_Container"
	echo "  hostport: $hostport"
	echo "  host: $host"
	echo "  port: $port"
	echo "  path: $path"
	echo "  channel: $channel"
	echo "  extention : $extention"
	echo "  channel sans ext: $Channel_noext"
	echo "  url sans chaine: $urlchanless"
	echo "  url playlist : $urlplaylist"
fi
