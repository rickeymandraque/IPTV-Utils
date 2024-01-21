#!/bin/bash

# Couleurs par constantes

bold="$(tput bold)"
black="$(tput setaf 0)"   #     0	Black
red="$(tput setaf 1)"     # 	1	Red
green="$(tput setaf 2)"   # 	2	Green
yellow="$(tput setaf 3)"  # 	3	Yellow
blue="$(tput setaf 4)"    # 	4	Blue
magenta="$(tput setaf 5)" # 	5	Magenta
cyan="$(tput setaf 6)"    # 	6	Cyan
white="$(tput setaf 7)"   # 	7	White
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

use_whitelist="false"
use_blacklist="false"

# Variables pour les adresses IP par pays
DEFAULT_COUNTRY="FR"

AU="1.142.55.44"
BR="104.41.56.84"
CA="104.142.78.157"
CL="146.155.103.248"
DE="104.151.3.61"
DK="109.58.33.44"
ES="107.183.172.254"
FI="109.204.129.7"
FR="37.169.20.16"
UK="89.167.207.12"
IT="101.58.39.100"
MX="131.178.201.203"
NO="109.189.5.4"
SE="128.87.84.18"
US="45.50.96.71"

# Fonction pour l'affichage de l'aide
function usage() {
    echo "Usage: $0 [-o output_file] [-wl] [-bl] [-c country_code] [-h]"
    echo ""
    echo "Options:"
    echo "-o output_file : Nom de fichier de sortie de la playlist."
    echo "-wl : Inclure seulement les chaînes présentes dans le fichier Pluto.wl."
    echo "-bl : Ignorer les chaînes présentes dans le fichier Pluto.bl."
    echo "-c, --country country_code : Spécifier le pays pour obtenir la playlist. Utilisez 'ALL' pour tous les pays."
    echo "--countries countries_codes : Spécifier les pays pour obtenir les playlist."
    echo "-h, --help, -?: Afficher l'aide."
    exit 0
}
shopt -s nocasematch # Activer l'option nocasematch pour l'ignorance de la casse
while [ $# -gt 0 ]; do
    case $(echo "$1" | tr '[:upper:]' '[:lower:]') in
    -o | --output)
        output_file=$Playlists_Dir/$2
        output_choosen="true"
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
    -c | --country)
        country=$2
        shift 2
        ;;
    --countries=*)
        countries_option="${1#--countries=}"
        countries_selected="true"
        IFS=',' read -ra countries_array <<<"$countries_option"
        shift
        ;;
    *)
        echo "Usage: $0 [-wl] [-bl] [-c] [countries=country1,country2,...] [-h]"
        echo "Option non reconnue : $*"
        exit 1
        ;;
    esac
done
shopt -s nocasematch # Activer l'option nocasematch pour l'ignorance de la casse
function select_country() {
    # On bascule $country en capitales
    country="$(echo "$country" | tr '[:lower:]' '[:upper:]')"
    # Si l'option -c ou --country est spécifiée, utiliser X-Forwarded-For avec l'adresse IP correspondante
    if [ -n "$country" ]; then
        echo "country : $country"
        case "$country" in
        ALL)
            all_countries="true"
            ;;
        AU)
            x_forwarded_for="$AU"
            ;;
        BR)
            x_forwarded_for="$BR"
            ;;
        CA)
            x_forwarded_for="$CA"
            ;;
        CL)
            x_forwarded_for="$CL"
            ;;
        DE)
            x_forwarded_for="$DE"
            ;;
        DK)
            x_forwarded_for="$DK"
            ;;
        ES)
            x_forwarded_for="$ES"
            ;;
        FI)
            x_forwarded_for="$FI"
            ;;
        FR)
            x_forwarded_for="$FR"
            ;;
        UK)
            x_forwarded_for="$UK"
            ;;
        IT)
            x_forwarded_for="$IT"
            ;;
        MX)
            x_forwarded_for="$MX"
            ;;
        NO)
            x_forwarded_for="$NO"
            ;;
        SE)
            x_forwarded_for="$SE"
            ;;
        US)
            x_forwarded_for="$US"
            ;;
        *_REAL)
            x_forwarded_for="$myip"
            ;;
        *)
            echo "Erreur : Pays non reconnu ($country). Utilisez 'ALL' pour tous les pays."
            exit 1
            ;;
        esac
    # Si le pays n'est pas spécifié, obtenir le pays à partir de l'adresse IP
    elif [ -z "$country" ] && [ -z "$DEFAULT_COUNTRY" ]; then
        mycountry=$(curl -sL "https://ipinfo.io/country")
        country="${mycountry}_REAL"
        myip=$(curl -sL "https://ipinfo.io/ip")
    else
        country="$DEFAULT_COUNTRY"
    fi
    if [[ "$country" == *_REAL ]]; then
         
            function curl_command() {
                curl -sL "$json_url"
            }
    else
    function curl_command() {
        curl -sL -H "X-Forwarded-For: $x_forwarded_for" "$json_url"
    }
    fi

}

select_country

function set_output() {

    if [ "$output_choosen" == "true" ]; then
        # Si une option de sortie est choisie
        echo "${green}Info :${reset} La playlist sera enregistrée sous le nom $output_file"
    else
        # Si aucune option de sortie n'est choisie
        country=$1
        output_file="$Playlists_Dir/PlutoTV_${country}-$(date +%d%m%Y).m3u"
        echo "${yellow}Avertissement :${reset} Vous n'avez pas spécifié de fichier de sortie. La playlist sera enregistrée sous le nom $output_file"
    fi

}

# Vérification de l'utilisation exclusive de la liste blanche ou noire
if [ "$use_whitelist" = true ] && [ "$use_blacklist" = true ]; then
    echo "${red}${bold}Erreur :$reset les options -wl et -bl ne peuvent pas être utilisées simultanément"
    exit 1
fi

# Fonction pour ajouter une chaîne à la playlist
function add_channel() {
    echo "${green}Chaîne $name (${country}) Ajouté (id: $id)${reset}"
    echo "#EXTINF:-1 channel-id=\"Pluto-$id\" tvg-id=\"$id\" tvg-name=\"$name\" tvg-country=\"${country}\" tvg-chno=\"$number\" tvg-logo=\"https://images.pluto.tv/channels/$id/colorLogoSVG.svg\" group-title=\"$categorie\",$name" >>"$output_file"
    echo "${StreamURL}/$id/master.m3u8${URL_Options}" >>"$output_file"
}

## Corps du script ##

function grab_channels() {
    select_country
    set_output "$country"
    echo "Obtention de la playlist pour le pays $country avec l'adresse IP $x_forwarded_for."
    # Initialiser la playlist
    echo "#EXTM3U" >"$output_file"

    # Parcourir toutes les entrées de l'objet JSON
    curl_command | jq -c '.[]' | while read -r channel; do

        # Récupérer les informations de la chaîne
        name=$(echo "$channel" | jq -r '.name' | sed 's/,//g')
        id=$(echo "$channel" | jq -r '._id')
        number=$(echo "$channel" | jq -r '.number')
        categorie=$(echo "$channel" | jq -r '.category')

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
    total=$(curl_command | jq '. | length')

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
}

# Parcourir tous les pays si l'option -c ou --country est spécifiée à ALL
if [ "$all_countries" = true ]; then
    for country_code in AU BR CA CL DE DK ES FI FR UK IT MX NO SE US; do
        country="$country_code"
        grab_channels
    done
elif [ "$countries_selected" = true ]; then
    for country_code in "${countries_array[@]}"; do
        country="$country_code"
        grab_channels
    done
else
    grab_channels
fi

echo "Terminé"
exit 0
