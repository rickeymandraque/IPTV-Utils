#!/bin/bash

# Constantes pour les URLs de l'API
API_URL="https://iptv-org.github.io/api"
CHANNELS_API_URL="$API_URL/channels.json"
COUNTRIES_API_URL="$API_URL/countries.json"
help_called=false
# Fonction pour afficher l'aide
function show_help {
    echo "Usage: ./script.sh [--name|--exact-name|--exact-nocase <channel_name>] [--id|--exact-id|--exact-nocase-id <channel_id>] [--country <country_code>] [--nsfw|--sfw] [--language <language_code>]"
    echo "Search for a TV channel on the iptv-org API by various criteria."
    echo "Options:"
    echo "  --name <channel_name>: Search by channel name (default: relative)"
    echo "  --exact-name <channel_name>: Search for an exact match for channel name"
    echo "  --exact-nocase <channel_name>: Search for an exact match for channel name without considering case"
    echo "  --id <channel_id>: Search by channel ID (default: relative)"
    echo "  --exact-id <channel_id>: Search for an exact match for channel ID"
    echo "  --exact-nocase-id <channel_id>: Search for an exact match for channel ID without considering case"
    echo "  --country <country_code>: Search by country code (2-letter ISO code or country name)"
    echo "  --nsfw: Include NSFW channels"
    echo "  --sfw: Exclude NSFW channels"
    echo "  --language <language_code>: Search by language code"
    if [ "$help_called" = true ]; then
        exit 0
        else
    exit 1
    fi
}

# Fonction pour valider l'entrée utilisateur en tenant compte des caractères spéciaux
function validate_input {
    local input="$1"
    # Échapper les caractères spéciaux pour les utiliser dans les expressions régulières
    input=$(echo "$input" | sed 's/[\\"\/]/\\&/g')
    echo "$input"
}

# Fonction pour vérifier la validité du pays
function validate_country {
    local country="$1"
    if [[ ${#country} -eq 2 ]]; then
        country=$(echo "$country" | tr '[:lower:]' '[:upper:]')
        valid_country=$(curl -s "$COUNTRIES_API_URL" --compressed | jq -r ".[] | select(.code == \"$country\") | .code")
        if [ -z "$valid_country" ]; then
            echo "Invalid country code."
            exit 1
        fi
    else
        country_code=$(curl -s "$COUNTRIES_API_URL" --compressed | jq -r ".[] | select(.name | test(\"^$country$\"; \"i\")) | .code")
        if [ -z "$country_code" ]; then
            echo "Country not found. Please enter a valid 2-letter ISO code or country name."
            exit 1
        else
            country="$country_code"
        fi
    fi
    echo "$country"
}

# Fonction pour exécuter la requête à l'API
function execute_query {
    local query="$1"
    curl -s "$CHANNELS_API_URL" --compressed | jq -c "$query"
}

# Fonction pour afficher les résultats
function display_results {
    local result="$1"
    if [ -z "$result" ]; then
        echo "No TV channels found for the specified criteria."
    else
        echo "Search Result:"
        # Afficher les résultats en les formatant correctement
        first=true
        echo "["
        while IFS= read -r line; do
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            echo "$line"
        done <<< "$result"
        echo "]"
    fi
}

# Vérifier le nombre d'arguments
if [ $# -lt 2 ]; then
    show_help
fi

# Déclarer les variables
name=""
id=""
country=""
nsfw=""
language=""
exact_name=false
exact_nocase=false
exact_id=false
exact_nocase_id=false

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name|--exact-name|--exact-nocase)
            if [ "$1" == "--exact-name" ]; then
                exact_name=true
            elif [ "$1" == "--exact-nocase" ]; then
                exact_nocase=true
            fi
            name=$(validate_input "$2")
            shift
            ;;
        --id|--exact-id|--exact-nocase-id)
            if [ "$1" == "--exact-id" ]; then
                exact_id=true
            elif [ "$1" == "--exact-nocase-id" ]; then
                exact_nocase_id=true
            fi
            id=$(validate_input "$2")
            shift
            ;;
        --country)
            country="$2"
            country=$(validate_country "$country")
            shift
            ;;
        --nsfw|--sfw)
            if [[ "$1" == "nsfw" ]]; then
                nsfw="true"
                elif [[ "$1" == "sfw" ]]; then
                nsfw="false"
            fi
            shift
            ;;
        --language)
            language="$2"
            shift
            ;;
        -h|--help)
            help_called=true
            show_help
            ;;
        *)
            show_help
            ;;
    esac
    shift
done

# Construire la requête à l'API avec les filtres appropriés
query=".[] | "
if [ -n "$name" ]; then
    if [ "$exact_name" == "true" ]; then
        query+="select(.name == \"$name\") | "
    elif [ "$exact_nocase" == "true" ]; then
        query+="select(.name | ascii_downcase == \"$name\") | "
    else
        query+="select(.name | test(\"$name\"; \"i\")) | "
    fi
fi
if [ -n "$id" ]; then
    if [ "$exact_id" == "true" ]; then
        query+="select(.id == \"$id\") | "
    elif [ "$exact_nocase_id" == "true" ]; then
        query+="select(.id | ascii_downcase == \"$id\") | "
    else
        query+="select(.id | test(\"$id\"; \"i\")) | "
    fi
fi
if [ -n "$country" ]; then
    query+="select(.country == \"$country\") | "
fi
if [ -n "$nsfw" ]; then
    if [ "$nsfw" == "false" ]; then
        query+="select(.is_nsfw == false) | "
    else
        query+="select(.is_nsfw == true) | "
    fi
fi
if [ -n "$language" ]; then
    query+="select(.languages[] | test(\"^$language$\"; \"i\")) | "
fi
query+="."

# Exécuter la requête à l'API et afficher les résultats
result=$(execute_query "$query")
display_results "$result"
