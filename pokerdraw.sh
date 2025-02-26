###############
#  _____      _              ____                    
# |  __ \    | |            |  _ \                   
# | |__) |__ | | _____ _ __| | | |_ __ __ _ _      __
# |  ___/ _ \| |/ / _ \ '__| | | | '__/ _` \ \ /\ / /
# | |  | (_) |   <  __/ |  | |__| | | | (_| |\ V  V / 
# |_|   \___/|_|\_\___|_|  |_____/|_|  \__,_| \_/\_/  
#                                                    
# A Bash Poker Hand Evaluator
# ---------------------------------------------
# Description:
# This script generates a shuffled deck of cards and deals a 5-card poker hand.
# It evaluates the hand and displays the cards with colored suits (♠♥♣♦),
# determining the best possible poker hand from Royal Flush to High Card.
# Uses secure random number generation for shuffling.
#
# Contributors: GPT-4-turbo (ChatGPT, February 2025) & Claude 3.5 Sonnet
# Author: Xiamen
# Version: 1.0a
# Date: Feb/15/2025
#
# Changelog: 1.0a Feb 26
# Fixed, padding issue for 10, all output is same length.
#
###############

#!/bin/bash

# Use tput for colors
RED=$(tput setaf 1)       # Red text (for hearts and diamonds)
BLACK=$(tput setaf 0)      # Black text (for normal cards)
WHITE_BG=$(tput setab 15)  # White background
RESET=$(tput sgr0)         # Reset all attributes

# Card values and suits
declare -a VALUES=("2" "3" "4" "5" "6" "7" "8" "9" "10" "J" "Q" "K" "A")
declare -a SUITS=("♠" "♥" "♣" "♦")
declare -A CARD_VALUES=(["2"]=2 ["3"]=3 ["4"]=4 ["5"]=5 ["6"]=6 ["7"]=7 ["8"]=8 ["9"]=9 ["10"]=10 ["J"]=11 ["Q"]=12 ["K"]=13 ["A"]=14)

# Generate a deck of 52 cards
generate_deck() {
    local deck=()
    for value in "${VALUES[@]}"; do
        for suit in "${SUITS[@]}"; do
#            deck+=("$value$suit")
			 if [[ "$value" == "10" ]]; then
    			deck+=("10$suit")  # Remove space for 10
			else
    			deck+=("$value$suit")
			fi
        done
    done
    echo "${deck[@]}"
}

# Shuffle deck using /dev/urandom
shuffle_deck() {
    local deck=("$@")
    shuffled_deck=($(echo "${deck[@]}" | tr ' ' '\n' | shuf -n ${#deck[@]}))
    echo "${shuffled_deck[@]}"
}

# Extract values and suits from drawn cards
parse_hand() {
    local hand=("$@")
    values=()
    suits=()
    for card in "${hand[@]}"; do
        value="${card:0:-1}"  # Extract value
        suit="${card: -1}"    # Extract last character (suit)
        values+=("$value")
        suits+=("$suit")
    done
}

# Determine the best poker hand
evaluate_hand() {
    local -A value_count suit_count
    local sorted_values=()

    # Count occurrences of each value and suit
    for value in "${values[@]}"; do
        ((value_count[$value]++))
    done
    for suit in "${suits[@]}"; do
        ((suit_count[$suit]++))
    done

    # Convert values to numerical representation and sort them
    for value in "${values[@]}"; do
        sorted_values+=("${CARD_VALUES[$value]}")
    done
    IFS=$'\n' sorted_values=($(sort -n <<<"${sorted_values[*]}"))  # Sort numerically

    # Check for flush (all same suit)
    local is_flush=0
    if [[ ${#suit_count[@]} -eq 1 ]]; then
        is_flush=1
    fi

    # Check for straight (consecutive values)
    local is_straight=0
    if [[ ${#value_count[@]} -eq 5 ]]; then
        if (( sorted_values[4] - sorted_values[0] == 4 )); then
            is_straight=1
        elif [[ "${sorted_values[*]}" == "2 3 4 5 14" ]]; then
            is_straight=1  # Special case for A-2-3-4-5
        fi
    fi

    # Determine hand ranking
    if (( is_flush && is_straight && sorted_values[4] == 14 )); then
        hand_rank="Royal Flush"
    elif (( is_flush && is_straight )); then
        hand_rank="Straight Flush"
    elif [[ $(printf "%s\n" "${value_count[@]}" | grep -c 4) -eq 1 ]]; then
        hand_rank="Four of a Kind"
    elif [[ $(printf "%s\n" "${value_count[@]}" | grep -c 3) -eq 1 && $(printf "%s\n" "${value_count[@]}" | grep -c 2) -eq 1 ]]; then
        hand_rank="Full House"
    elif (( is_flush )); then
        hand_rank="Flush"
    elif (( is_straight )); then
        hand_rank="Straight"
    elif [[ $(printf "%s\n" "${value_count[@]}" | grep -c 3) -eq 1 ]]; then
        hand_rank="Three of a Kind"
    elif [[ $(printf "%s\n" "${value_count[@]}" | grep -c 2) -eq 2 ]]; then
        hand_rank="Two Pair"
    elif [[ $(printf "%s\n" "${value_count[@]}" | grep -c 2) -eq 1 ]]; then
        hand_rank="One Pair"
    else
        # Get the highest card based on numerical values
        highest_numeric_value=${sorted_values[-1]}
        for key in "${!CARD_VALUES[@]}"; do
            if [[ ${CARD_VALUES[$key]} -eq $highest_numeric_value ]]; then
                highest_card=$key
                break
            fi
        done
        hand_rank="High Card: $highest_card"
    fi
}


# Generate and shuffle deck
deck=($(generate_deck))
shuffled_deck=($(shuffle_deck "${deck[@]}"))

# Draw 5 cards from the shuffled deck
hand=("${shuffled_deck[@]:0:5}")

# Parse hand into values and suits
parse_hand "${hand[@]}"

# Evaluate the best hand
evaluate_hand

# Print hand with colors
for card in "${hand[@]}"; do
    value="${card:0:-1}"
    suit="${card: -1}"
    
    # Pad value to 2 characters for consistent width
    padded_value=$(printf "%-2s" "$value")

    # Color the suits
    case "$suit" in
        "♥"|"♦") color="${RED}" ;;
        *) color="${BLACK}" ;;
    esac

    # Print card with padding and colors
    echo -ne "${WHITE_BG}${BLACK}[${padded_value}${color}${suit}${RESET}${WHITE_BG}${BLACK}]${RESET} "
done

# Print hand with colors
#echo -n "Hand: "
#for card in "${hand[@]}"; do
#    value="${card:0:-1}"
#    suit="${card: -1}"
    
    # Color the suits
#    case "$suit" in
#        "♥"|"♦") color="${RED}" ;;
#        *) color="${BLACK}" ;;
#    esac

#    echo -ne "${WHITE_BG}${BLACK}[${value} ${color}${suit}${RESET}${WHITE_BG}${BLACK}]${RESET} "
#done

# Print the best hand on the same line
#echo -e "→ ${hand_rank}"
