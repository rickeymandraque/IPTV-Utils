#!/bin/bash


# Couleurs par constantes

bold="$(tput bold)"
black="$(tput setaf 0)"      #  0   Black
red="$(tput setaf 1)"        # 	1	Red
green="$(tput setaf 2)"      # 	2	Green
yellow="$(tput setaf 3)"     # 	3	Yellow
blue="$(tput setaf 4)"       # 	4	Blue
magenta="$(tput setaf 5)"    # 	5	Magenta
cyan="$(tput setaf 6)"       # 	6	Cyan
white="$(tput setaf 7)"      # 	7	White
reset="$(tput sgr0)"



# Variables et URLs
json_url="https://api.pluto.tv/v2/channels.json"
StreamURL="http://stitcher-ipv4.pluto.tv/v1/stitch/embed/hls/channel"
URL_Options="?deviceType=samsung-tvplus&deviceMake=samsung&deviceModel=samsung&deviceVersion=unknown&appVersion=unknown&deviceLat=0&deviceLon=0&deviceDNT=%7BTARGETOPT%7D&deviceId=%7BPSID%7D&advertisingId=%7BPSID%7D&us_privacy=1YNY&samsung_app_domain=%7BAPP_DOMAIN%7D&samsung_app_name=%7BAPP_NAME%7D&profileLimit=&profileFloor=&embedPartner=samsung-tvplus"

# Fichiers et dossiers
Config_Dir="./Config"
Playlists_Dir="./Playlists"
blacklist_file="$Config_Dir/Pluto.bl"
whitelist_file="$Config_Dir/Pluto.wl"

output_file="$Playlists_Dir/PlutoTV-$(date +%d%m%Y).m3u"
use_whitelist="false"
use_blacklist="false"

# Fonction pour l'affichage de l'aide
usage() {
    echo "Usage: $0 [-o output_file] [-wl] [-bl] [-h]"
    echo ""
    echo "Options:"
    echo "-o output_file: Nom de fichier de sortie de la playlist."
    echo "-wl: Inclure seulement les chaînes présentes dans le fichier Pluto.wl."
    echo "-bl: Ignorer les chaînes présentes dans le fichier Pluto.bl."
    echo "-h, --help, -?: Afficher l'aide."
    exit 0
}

while [ $# -gt 0 ]; do
    case $1 in
    -o | --output)
        output_file=$Playlists_Dir/$2
        shift 2
        ;;
    -wl)
        use_whitelist="true"
        shift
        ;;
    -bl)
        use_blacklist="true"
        shift
        ;;
    -h | --help | -\?)
        usage
        ;;
    *)
        echo "Usage: $0 [-wl] [-bl]"
        echo "Option non reconnue : $1"
        exit 1
        ;;
    esac
done

# Vérification de l'utilisation exclusive de la liste blanche ou noire
if [ "$use_whitelist" = true ] && [ "$use_blacklist" = true ]; then
    echo "${red}${bold}Erreur :$reset les options -wl et -bl ne peuvent pas être utilisées simultanément"
    exit 1
fi

# Si aucune option de sortie n'est choisie
if [ "$output_file" == "$Playlists_Dir/PlutoTV-$(date +%d%m%Y).m3u" ]; then
    echo "${yellow}Avertissement :${reset} Vous n'avez pas spécifié de fichier de sortie. La playlist sera enregistrée sous le nom $output_file"
fi

function add_channel() {
    echo "${green}Chaîne $name Ajouté (id: $id)${reset}"
    echo "#EXTINF:-1 channel-id=\"Pluto-$id\" tvg-id=\"$id\" tvg-name=\"$name\" tvg-logo=\"https://images.pluto.tv/channels/$id/colorLogoSVG.svg\" group-title=\"Pluto TV France\",$name" >>"$output_file"
    echo "${StreamURL}/$id/master.m3u8${URL_Options}" >>"$output_file"
}

## Corps du script ##

# Initialiser la playlist
echo "#EXTM3U" >"$output_file"

# Parcourir toutes les entrées de l'objet JSON
curl -s $json_url | sed 's/\\"//g' | jq -c '.[]' | while read -r channel; do

    # Récupérer les informations de la chaîne
    name=$(echo "$channel" | jq -r '.name' | sed 's/,//g')
    id=$(echo "$channel" | jq -r '._id')

    # Vérifier si l'identifiant de chaîne (_id) n'est pas vide
    if [ -z "$id" ]; then
        echo "${yellow}L'identifiant de la chaîne est vide pour l'entrée suivante : $channel${reset}"
        continue
    fi

    if [[ "$use_blacklist" == true && $(grep -c "^$name\$\\|^$id\$" "$blacklist_file") -gt 0 ]]; then
        echo "${yellow}Chaîne $name ignorée (id: $id)${reset}"
    elif [[ "$use_whitelist" == true ]]; then
        # Si Whitelist = true
        # Vérifier si le nom ou l'identifiant est dans la liste blanche
        if grep -q "^$name\$\\|^$id\$" $whitelist_file; then
            # Si oui, Ajouter l'entrée à la playlist
            add_channel
        else
            # Sinon, afficher un message d'erreur
            echo "${yellow}Chaîne $name ignorée (id: $id)${reset}"
        fi
    else
        # Ajouter l'entrée à la playlist
        add_channel

    fi

done

# Récupérer le nombre total de chaînes dans le JSON
total=$(curl -s $json_url | jq '. | length')

# Récupérer le nombre de lignes dans la playlist
lines=$(wc -l <"$output_file")

# Compter le nombre total de chaînes dans la playlist
playlist_total=$(((lines - 1) / 2))

# Vérifier que la playlist n'est pas vide
if [[ "$playlist_total" -eq 0 ]]; then
    echo "Erreur : La playlist est vide. Aucune chaîne trouvée."
    exit 1
fi

# Afficher le nombre total de chaînes dans le JSON et le nombre total de chaînes dans la playlist
echo "Nombre total de chaînes dans le JSON : $total"
echo "Nombre total de chaînes dans la playlist : $playlist_total"
exit 0
