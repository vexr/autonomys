#!/bin/bash

# Define log file(s)
logs=(
    "/opt/autonomys/logs/plotter01.log"
)

# Function to check for GPU tools and display GPU info
display_gpu_info() {
    local nvidia_installed=false
    local rocm_installed=false

    # Check if nvidia-smi is installed and runs successfully
    if command -v nvidia-smi &> /dev/null && nvidia-smi --query-gpu=index,name --format=csv,noheader &> /dev/null; then
        nvidia_installed=true
    fi

    # Check if rocm-smi is installed and runs successfully
    if command -v rocm-smi &> /dev/null && rocm-smi --showproductname &> /dev/null; then
        rocm_installed=true
    fi

    # Display GPU information based on available tools
    if [ "$nvidia_installed" = true ]; then
        printf "NVIDIA GPUs:\n"
        nvidia-smi --query-gpu=index,name --format=csv,noheader |
            awk -F', ' '{printf "GPU %s: %s | ", $1, $2}' |
            sed 's/ | $/\n/'
    fi

    if [ "$rocm_installed" = true ]; then
        printf "AMD GPUs (ROCm):\n"
        rocm-smi --showproductname |
            awk '
            /GPU\[[0-9]+\]/ { 
                gpu_index = $2; 
                gpu_index = substr(gpu_index, 1, length(gpu_index)-1);
            } 
            /Card model/ { 
                # Capture the model after ": Card model:"
                model = substr($0, index($0, ": Card model:") + length(": Card model: ") + 1);
                print "GPU " gpu_index ": " model 
            }' |
            sed 's/ | $/\n/'
    fi

    # If neither tool is installed, do nothing (no error messages or output)
}

# Function to calculate and print benchmark results
calculate_and_print_results() {
    local minutes=$1
    local cnt=$2
    local avg_time=$(echo "scale=2; $minutes * 60 / $cnt" | bc)
    local avg_per_min=$(echo "scale=2; $cnt / $minutes" | bc)
    local tib_per_day=$(echo "scale=2; 86400 / $avg_time * 0.9843112 / 1024" | bc)

    printf "\nSector Evaluation Benchmark (Performance over %d minutes)\n" "$minutes"
    
    # Display GPU information (if available)
    display_gpu_info
    
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
