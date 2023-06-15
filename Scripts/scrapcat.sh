#!/bin/bash

#######################################
#       Scrapcat - IPTV Scraping      #
#######################################
# Script pour extraire des informations
# à partir du site IPTVCat (https://iptvcat.com)
# sur les flux IPTV disponibles.
#
# Développeur : Rickey Mandraque
# GitHub : https://github.com/rickeymandraque/IPTV-Utils
# Description: Ce script permet de fouiller le site IPTVCat.com, de récupérer les informations des chaînes IPTV disponibles et de les afficher dans le terminal.
#######################################

# Créer un répertoire temporaire dans "tmpfs"
tmpdir=$(mktemp -d -p /dev/shm)

# Fonction pour nettoyer et sortir en cas d'interruption du script
function cleanup() {
    local message="Script interrompu par l'utilisateur"
    local exit_code=1

    if [[ "$1" == "--end-script" ]]; then
        message="Le site a été complètement scrapé"
        exit_code=0
    fi

    echo ""
    echo "$message"
    sleep 1
    echo "Nettoyage en cours"
    rm -r "$tmpdir"
    sleep 1
    echo "Nettoyage terminé"
    sleep 1
    exit "$exit_code"
}

# Gérer l'interruption du script en cas de pression de la touche CTRL+C
trap cleanup SIGINT

# Variables de configuration
countries=("france" "undefined")
curl_cmd="curl -sL"
grep_cmd="grep -E"

function get_country_list() {
    local html
    html=$($curl_cmd "https://iptvcat.com")

    mapfile -t countries < <(echo "$html" | awk -F'"|</option>' '/<option value="/ && !/all/ {gsub(/ /, "_", $2); print $2}')

    echo "${countries[@]}"
}

# Fonction pour afficher la liste des pays
function print_country_list() {
    local countries=("$@")
    echo "Les pays suivants vont être analysés :"
    for country in "${countries[@]}"; do
        country=$(echo "$country" | sed 's/_/ /g')
        echo -e "$country"
    done
}

# Fonction pour extraire le contenu entre les balises <span>
function extract_span_content() {
    awk -F'</span>' '{print $1}' | awk 'NF'
}
function cat_block() {
    cat "$block_file"
}

# Fonction pour extraire les informations d'un bloc de données
function extract_info() {
    local block_file="$1"
    local checked
    local liveliness
    local days
    local status
    local formats
    local country
    local region
    local city
    local channel_title
    local stream_link

    # Extraire les informations supplémentaires du bloc
    checked=$(cat_block | awk -F'<span class='\''titile_span checked_title'\''>Checked: </span><span class='\''minor_content'\''>' '{print $2}' | extract_span_content)
    liveliness=$(cat_block | sed -n "s/.*background-color: rgba([^)]*)'>\([0-9]\+\)<.*/\1/p")
    days=$(cat_block | awk -F'<span class='\''titile_span checked_title ml-15'\'' style='\''width: 40px'\''>Days: </span><span>' '{print $2}' | extract_span_content)
    status=$(cat_block | awk -F'<div class='\''state span ' '{print $2}' | awk -F"'" '{print $1}' | awk 'NF')
    formats=$(cat_block | awk -F'<span class='\''titile_span formats'\''>Formats: </span><span class='\''minor_content'\''>' '{print $2}' | extract_span_content | sed 's/, /\n/g')
    country=$(cat_block | awk -F'<span class='\''titile_span_small'\''>Country: </span><span class='\''minor_content_server'\''>' '{print $2}' | extract_span_content)
    region=$(cat_block | awk -F'<span class='\''titile_span_small'\''>Region: </span><span class='\''minor_content_server'\''>' '{print $2}' | extract_span_content)
    city=$(cat_block | awk -F'<span class='\''titile_span_small'\''>City: </span><span class='\''minor_content_server'\''>' '{print $2}' | extract_span_content)
    channel_title=$(cat_block | awk -F'title="' '/title="[^"]+">([^<]+)<\/span>/ {match($0, /title="[^"]+">([^<]+)<\/span>/, title); if (title[1] && !/Last checked/) print title[1]}' | sed -E 's/[0-9]{3,},\s\.{3}//')
    stream_link=$(cat_block | grep -oP '<a href="\K[^"]+' | awk 'NR==1')
    real_link=$($curl_cmd "$stream_link" | $grep_cmd '^https?' | sed 's/[?&]checkedby:iptvcat\.com$//')

    display_info "$channel_title" "$status" "$checked" "$liveliness" "$days" "$formats" "$country" "$region" "$city" "$stream_link" "$real_link"
}

# Fonction pour afficher les informations supplémentaires extraites
function display_info() {
    echo "======================================================================================="

    # Parcourir tous les paramètres
    for param in "$@"; do
        case $param in
        "$channel_title")
            echo "Titre de la chaîne : $channel_title"
            ;;
        "$checked")
            echo "Date de dernière vérification : $checked"
            ;;
        "$liveliness")
            echo "Pourcentage de liveliness : $liveliness"
            ;;
        "$days")
            echo "Durée de vie (en jours) : $days"
            ;;
        "$status")
            echo "Statut : $status"
            ;;
        "$formats")
            echo "Formats :"
            echo "$formats"
            ;;
        "$country")
            echo "Pays de diffusion : $country"
            ;;
        "$region")
            echo "Région de diffusion : $region"
            ;;
        "$city")
            echo "Ville de diffusion : $city"
            ;;
        "$stream_link")
            echo "Lien du flux : $stream_link"
            ;;
        "$real_link")
            echo "Lien réél : $real_link"
            ;;
        *) ;;
        esac
    done

    echo "======================================================================================="
}

# Fonction pour parcourir une page et extraire les informations des blocs
function scrape_page() {
    local page_url="$1"
    local html
    html=$($curl_cmd "$page_url")
    local filtered_html

    # Filtre pour supprimer le contenu avant et après les blocs souhaités
    filtered_html=$(echo "$html" | awk '/<tbody class="streams_table">/,/<!-- IptvCat_notice_up -->/')

    # Extraire les blocs de données souhaités à partir du HTML filtré
    local blocks
    blocks=$(echo "$filtered_html" | awk '/<div class='\''popover_channel_holder'\''>/{block=$0; while(getline > 0){block=block"\n"$0; if($0 ~ /data-content="/) break} print block; print "===================================="}')

    # Parcourir les blocs et extraire les informations supplémentaires
    while IFS= read -r line; do
        echo "$line" >>"$tmpdir/block.tmp"
        if [[ $line == *'data-content="'* ]]; then
            extract_info "$tmpdir/block.tmp"
            rm "$tmpdir/block.tmp"
        fi
    done <<<"$blocks"
}

# Fonction pour remplacer les espaces par des underscore dans les URL des pays
function replace_spaces_with_underscore() {
    local country_url="$1"
    local replaced_url="${country_url// /_}"
    echo "$replaced_url"
}

# Parcourir les URL des pays
if [[ "$1" == "--all-countries" || "$1" == "-ac" ]]; then
    countries=($(get_country_list))
    echo "ATTENTION : Tous les pays vont être parcourus !"
    print_country_list "${countries[@]}"
    echo "Appuyer sur CTRL+C pour annuler"
    sleep 10
    shift
else
    countries=("france" "undefined")
fi

# Fonction pour vérifier si un pays est sur la liste noire (blacklist)
function is_blacklisted() {
    local blacklist=("africa") # Liste noire (blacklist)
    local country="$1"
    for blacklisted_country in "${blacklist[@]}"; do
        if [[ "$country" == "$blacklisted_country" ]]; then
            return 0 # Le pays est sur la liste noire
        fi
    done
    return 1 # Le pays n'est pas sur la liste noire
}

index=0
while [[ $index -lt ${#countries[@]} ]]; do
    country="${countries[index]}"
    if is_blacklisted "$country"; then
        echo "Le pays '$country' est sur la liste noire. Passage au pays suivant..."
        index=$((index + 1))
        continue
    fi
    page_number=1
    country_url=$(replace_spaces_with_underscore "https://iptvcat.com/$country")
    page_url="$country_url"

    # Récupérer les informations pour toutes les pages disponibles
    while true; do
        echo "Scraping $page_url (Page $page_number)"
        echo "Pays en cours : $country"
        scrape_page "$page_url"

        # Vérifier si "Nothing found!" est présent dans la page
        if $curl_cmd "$page_url" | grep -q "Nothing found!"; then
            break
        fi

        echo "CHANGEMENT DE PAGE !"
        sleep 2
        page_number=$((page_number + 1))
        page_url="$country_url/$page_number"
    done

    index=$((index + 1))
    echo "CHANGEMENT DE PAYS !"
    sleep 3

    # Réinitialiser les variables pour le nouveau pays
    page_number=1
    country_url=$(replace_spaces_with_underscore "https://iptvcat.com/${countries[index]}")
    page_url="$country_url"
done

# Nettoyer et supprimer le répertoire temporaire
cleanup --end-script
