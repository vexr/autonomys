#!/bin/bash

# Define log file(s)
logs=(
    "/opt/autonomys/logs/plotter01.log"
)

# Function to calculate and print benchmark results
calculate_and_print_results() {
    local minutes=$1
    local cnt=$2
    local avg_time=$(echo "scale=2; $minutes * 60 / $cnt" | bc)
    local avg_per_min=$(echo "scale=2; $cnt / $minutes" | bc)
    local tib_per_day=$(echo "scale=2; 86400 / $avg_time * 0.9843112 / 1024" | bc)

    printf "\nSector Evaluation Benchmark (Performance over %d minutes)\n" "$minutes"
    nvidia-smi --query-gpu=index,name --format=csv,noheader |
        awk -F', ' '{printf "GPU %s: %s | ", $1, $2}' |
        sed 's/ | $/\n/'
    printf "\nSectors: %d | Avg/min: %.2f | Avg time: %.2f sec | TiB/day: %.2f\n\n" \
        "$cnt" "$avg_per_min" "$avg_time" "$tib_per_day"
}

# Set default time or use provided parameter
minutes=${1:-5}

# Calculate time threshold
time_threshold=$(date -u -d "$minutes minutes ago" '+%Y-%m-%dT%H:%M:%S')

# Count completed sectors
cnt=0
for log in "${logs[@]}"; do
    if [ -f "$log" ]; then
        cnt=$((cnt + $(
            awk -v time="$time_threshold" \
                '$0 >= time && (/(.* complete)/ || /Finished plotting sector successfully/)' \
                "$log" |
            wc -l
        )))
    fi
done

# Clear screen and display results
clear
if [ "$cnt" -gt 0 ]; then
    calculate_and_print_results "$minutes" "$cnt"
else
    printf "\nNo completed sectors or less than %d minutes of logs available. Please wait for a few minutes.\n" "$minutes"
fi
