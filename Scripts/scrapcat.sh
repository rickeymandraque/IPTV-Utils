#!/bin/bash

# Créer un répertoire temporaire dans "tmpfs"
tmpdir=$(mktemp -d -p /dev/shm)

# Tableau contenant les URL des pays
countries=("france" "undefined")

# Fonction pour extraire le contenu entre les balises <span>
extract_span_content() {
    awk -F'</span>' '{print $1}' | awk 'NF'
}

# Fonction pour extraire les informations d'un bloc de données
extract_info() {
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
    checked=$(cat "$block_file" | awk -F'<span class='\''titile_span checked_title'\''>Checked: </span><span class='\''minor_content'\''>' '{print $2}' | extract_span_content)
    liveliness=$(cat "$block_file" | sed -n "s/.*background-color: rgba([^)]*)'>\([0-9]\+\)<.*/\1/p")
    days=$(cat "$block_file" | awk -F'<span class='\''titile_span checked_title ml-15'\'' style='\''width: 40px'\''>Days: </span><span>' '{print $2}' | extract_span_content)
    status=$(cat "$block_file" | awk -F'<div class='\''state span ' '{print $2}' | awk -F"'" '{print $1}' | awk 'NF')
    # sed remplace les virgules par des retour à la ligne, à modifier si exportation vers json.
    formats=$(cat "$block_file" | awk -F'<span class='\''titile_span formats'\''>Formats: </span><span class='\''minor_content'\''>' '{print $2}' | extract_span_content | sed 's/, /\n/g')
    country=$(cat "$block_file" | awk -F'<span class='\''titile_span_small'\''>Country: </span><span class='\''minor_content_server'\''>' '{print $2}' | extract_span_content)
    region=$(cat "$block_file" | awk -F'<span class='\''titile_span_small'\''>Region: </span><span class='\''minor_content_server'\''>' '{print $2}' | extract_span_content)
    city=$(cat "$block_file" | awk -F'<span class='\''titile_span_small'\''>City: </span><span class='\''minor_content_server'\''>' '{print $2}' | extract_span_content)
    channel_title=$(cat "$block_file" | awk -F'title="' '/title="[^"]+">([^<]+)<\/span>/ {match($0, /title="[^"]+">([^<]+)<\/span>/, title); if (title[1] && !/Last checked/) print title[1]}' | sed -E 's/[0-9]{3,},\s\.{3}//')
    stream_link=$(cat "$block_file" | grep -oP '<a href="\K[^"]+' | awk 'NR==1')
    real_link=$(curl -sL $stream_link | grep -E '^https?'| sed 's/[?&]checkedby:iptvcat\.com$//')

    # Afficher les informations supplémentaires extraites
    echo "======================================================================================="
    echo "Titre de la chaîne : $channel_title"
    echo "Date de dernière vérification : $checked"
    echo "Pourcentage de liveliness : $liveliness"
    echo "Durée de vie (en jours) : $days"
    echo "Statut : $status"
    echo "Formats :"
    echo "$formats"
    echo "Pays de diffusion : $country"
    echo "Région de diffusion : $region"
    echo "Ville de diffusion : $city"
    echo "Lien du flux : $stream_link"
    echo "Lien réél : $real_link"
    echo "======================================================================================="
}

# Fonction pour parcourir une page et extraire les informations des blocs
scrape_page() {
    local page_url="$1"
    local html=$(curl -sL "$page_url")
    local filtered_html

    # Filtre pour supprimer le contenu avant et après les blocs souhaités
    filtered_html=$(echo "$html" | awk '/<tbody class="streams_table">/,/<!-- IptvCat_notice_up -->/')

    # Extraire les blocs de données souhaités à partir du HTML filtré
    local blocks=$(echo "$filtered_html" | awk '/<div class='\''popover_channel_holder'\''>/{block=$0; while(getline > 0){block=block"\n"$0; if($0 ~ /data-content="/) break} print block; print "===================================="}')

    # Parcourir les blocs et extraire les informations supplémentaires
    while IFS= read -r line; do
        echo "$line" >> "$tmpdir/block.tmp"
        if [[ $line == *'data-content="'* ]]; then
            extract_info "$tmpdir/block.tmp"
            rm "$tmpdir/block.tmp"
        fi
    done <<< "$blocks"
}

# Parcourir les URL des pays
for country in "${countries[@]}"; do
    page_number=1
    page_url="https://iptvcat.com/$country"

    # Récupérer les informations pour toutes les pages disponibles
    while true; do
        echo "Scraping $page_url (Page $page_number)"
        scrape_page "$page_url"

        # Vérifier si "Nothing found!" est présent dans la page
        if curl -sL "$page_url" | grep -q "Nothing found!"; then
            break
        fi

        echo "CHANGEMENT DE PAGE !"
        sleep 2

        page_number=$((page_number + 1))
        page_url="https://iptvcat.com/$country/$page_number"
    done

    echo "Aucune page supplémentaire à analyser pour le pays $country."
done

# Supprimer le répertoire temporaire
rm -r "$tmpdir"
