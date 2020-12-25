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

### Code du parseur d'url ###
# virer les truc innutile du genre ?checkedby:iptvcat.com
if [[ $1 == *"?checkedby:iptvcat.com"     ]]; then
	filtre="$(echo $1 | grep "\?checkedby:iptvcat.com" | cut -d? -f1)"
else
	filtre="$1"
fi

# extraire le host et le port
hostport="$( [[ $@ =~ $URI_REGEX ]] && echo "${BASH_REMATCH[4]}")"
# extraire le host
host="$( [[ $@ =~ $URI_REGEX ]] && echo "${BASH_REMATCH[7]}")"

# by request - try to extract the port
port="$( [[ $@ =~ $URI_REGEX ]] && echo "${BASH_REMATCH[9]}")"

# extraire le protocol
proto="$([[ $@ =~ $URI_REGEX ]] && echo "${BASH_REMATCH[2]}")"
# enlever le protocol
url="$( echo "${filtre/$proto/}")"

# Determiner si il y a une catégorie
if [[ $host == "static.france24.com"   ]]; then
	urltype="france24"
elif [[ $host == "rt-france.secure."* ]]; then
	urltype="rt-france"
elif [[ $host == *"hdr-tv.com" ]]; then
	urltype="tv7-3"
else
	urltype="$(echo "$url" | grep / | cut -d/ -f2)"
fi

if [[ $urltype == "tf1" ]] || [[ $urltype == "tfx" ]] || [[ $urltype == "tmc" ]]; then
	streamtype="tf1"
elif [[ $urltype == "france24"   ]]; then
	streamtype="france24"
elif [[ $urltype == "rt-france" ]]; then
	streamtype="rt-france"
elif [[ $urltype == "tv7-3" ]]; then
	streamtype="tv7-3"
# si $urltype est egal à live
elif  [[ $urltype == "live"  ]]; then
	# alors $streamtype est live
	streamtype="live"
	# si $urltype est egal à movie
elif  [[ $urltype == "movie"  ]]; then
	# alors $streamtype est movie
	streamtype="movie"
else
	# Sinon la variable est vide
	streamtype=""
fi
# extraire le user
# si la variable $streamtype est vide
if  [ -z "$streamtype" ]; then
	#statements
	# Alors $user se trouvera en deuxieme position
	user="$(echo "$url" | grep / | cut -d/ -f2)"
elif   [[ $streamtype == "tf1"   ]] || [[ $streamtype == "france24"   ]]; then
	tf1_dir="$(echo "$url" | grep / | cut -d/ -f3)"
	user=""
else
	# Sinon en troisieme position
	user="$(echo "$url" | grep / | cut -d/ -f3)"
fi

# Extraire le password
# si la variable $streamtype est vide
if  [ -z "$streamtype" ]; then
	# Alors $password se trouvera en troisieme position
	password="$(echo "$url" | grep / | cut -d/ -f3)"
elif   [[ $streamtype == "tf1" ]] || [[ $streamtype == "france24" ]]; then
	Stream_Container="$(echo "$url" | grep / | cut -d/ -f4)"
	password=""
else
	# Sinon en quatrieme position
	password="$(echo "$url" | grep / | cut -d/ -f4)"
fi

# Extraire la chaine du lien
# si la variable $streamtype est vide
if  [ -z "$streamtype" ]; then
	channel="$(echo "$url" | grep / | cut -d/ -f4-)"
else
	channel="$(echo "$url" | grep / | cut -d/ -f5-)"
fi

if  [[ $channel == *.* ]]; then
	extention="$(echo "${channel#*.}")"
else
	extention=""
fi
if  [ -n "$extention" ]; then
	Channel_noext="$(echo "$channel" | grep "\." | cut -d. -f1)"
fi

# URL sans la chaine
if  [ -z "$streamtype" ]; then
	urlchanless="$(echo "$proto$hostport/$user/$password")"
elif [[ $streamtype == "tf1" ]]; then
	urlchanless="$(echo "$proto$host/$urltype/$tf1_dir/$Stream_Container")"
else
	urlchanless="$(echo "$proto$hostport/$streamtype/$user/$password")"
fi

if  [ -z "$streamtype" ]; then
	path="$(echo "$user/$password")"
else
	path="$(echo "$streamtype/$user/$password")"
fi

# générer l'url pour avoir la playlist
if  [ ! "$streamtype" = "tf1" ]; then
	urlplaylist="$proto//$hostport/get.php?username=$user&password=$password&type=m3u"
else
	urlplaylist=""
fi

### Fin du Code du parseur d'url ###

echo  "  url entrée : $1"
echo  "  url filtrée : $filtre"
echo  "  proto: $proto://"
echo  "  url: $url"
echo  "  url type : $urltype"
echo  "  streamtype : $streamtype"
if [ ! "$streamtype" = "tf1" ]; then
	echo "  user: $user"
	echo "  password : $password"
else
	echo "  Dossier TF1 : $tf1_dir"
	echo "  Conteneur : $Stream_Container"
fi
echo  "  hostport: $hostport"
echo  "  host: $host"
echo  "  port: $port"
echo  "  path: $path"
echo  "  channel: $channel"
echo  "  extention : $extention"
echo  "  channel sans ext: $Channel_noext"
echo  "  url sans chaine: $urlchanless"
echo  "  url playlist : $urlplaylist"
