#!/bin/bash

# Color variables
bold=$(tput bold)
normal=$(tput sgr0)
cyan=$(tput setaf 6)
yellow=$(tput setaf 3)
white=$(tput setaf 7)

printf "${cyan}${bold}Subspace Plot Size Calculator v0.2${normal}\n"
printf "${yellow}This calculation should only be used if the intention is to utilize the entire drive for the plot.${normal}\n\n"

# Function to calculate plot_size
calculate_plot_size() {
    printf "%s" "$1"
}

# Main script
if [[ -z $1 ]]; then
    printf "Enter the path of the disk (e.g., /dev/sdb): " >&2 # Print prompt on stderr to keep it on the same line
    read disk_path
else
    disk_path=$1
fi

if [[ ! -e $disk_path ]]; then
    printf "\n${white}Error: Invalid disk path. Please enter a valid path.${normal}\n"
    exit 1
fi

# Determine file system type
filesystem=$(lsblk -no FSTYPE $disk_path)

if [[ $filesystem == "ext4" ]]; then
    printf "\nThe drive is formatted with the ${bold}${white}ext4${normal} file system.\n"
    total_size_blocks=$(sudo tune2fs -l $disk_path | grep "Block count" | awk '{print $3}')
    block_size=$(sudo tune2fs -l $disk_path | grep "Block size" | awk '{print $3}')
    total_size_gib=$(( (total_size_blocks * block_size) / (1024 * 1024 * 1024) ))
    total_size_gib=$((total_size_gib))
elif [[ $filesystem == "xfs" ]]; then
    printf "\nThe drive is formatted with the ${bold}${white}XFS${normal} file system.\n"
    blocks=$(sudo xfs_info $disk_path | awk '/data/ {gsub("[^0-9]", "", $4); print $4; exit}')
    agcount=$(sudo xfs_info /dev/sdb | awk '/agcount/ {gsub("[^0-9]", "", $3); print $3}')
    bsize=$(sudo xfs_info $disk_path  | awk '$1 == "data" {gsub("[^0-9]", "", $3); print $3}')
    total_size_bytes=$((blocks * bsize  * agcount))
    total_size_gib=$((total_size_bytes / (1024 * 1024 * 1024)))
    total_size_gib=$(echo "scale=0; $total_size_gib * 0.9935 / 1" | bc)
else
    printf "${white}Error: This calculation cannot be performed on the drive because it is not formatted with ext4 or XFS file system.${normal}\n"
    exit 1
fi

plot_size=$(calculate_plot_size $total_size_gib)
printf "The ideal plot size for the drive should be ${bold}${white}%sGiB${normal}\n\n" "$plot_size"
printf "${cyan}${bold}For comments or to report an issue, contact vexr on Discord.${normal}\n"
