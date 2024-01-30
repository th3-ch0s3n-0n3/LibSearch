#!/bin/bash

output_file="library_output.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No color

echo " 
 _     ___________  _____ _____  ___  ______  _____  _
| |   |_   _| ___ \/  ___|  ___|/ _ \ | ___ \/  __ \| | | |
| |     | | | |_/ /\ `--.| |__ / /_\ \| |_/ /| /  \/| |_| |
| |     | | | ___ \ `--. \  __||  _  ||    / | |    |  _  |
| |_____| |_| |_/ //\__/ / |___| | | || |\ \ | \__/\| | | |
\_____/\___/\____/ \____/\____/\_| |_/\_| \_| \____/\_| |_/

---------Creator: Vinayak Agrawal (ArmorCode-------------
"


echo -e "${GREEN}Following are the used libraries in different processes${NC}" | tee "$output_file"


# Run 'top' command and extract process IDs and command names
top_output=$(top -b -n 1)
process_info=$(echo "$top_output" | awk 'NR>7 {print $1, $NF}')


# Iterate over each process ID and command name
while read -r process_info; do
    process_id=$(echo "$process_info" | awk '{print $1}')
    command_name=$(echo "$process_info" | awk '{$1=""; print $0}')

    # Run 'lsof' command using the current process ID and filter '.so' files
    lsof_output=$(lsof -p "$process_id" | grep '\.so')

    # Extract the paths to the executable '.so' files
    so_file_paths=$(echo "$lsof_output" | awk '{print $9}')

    # Iterate over each '.so' file path
    for so_file_path in $so_file_paths; do
        # Run 'ldd' command using the current '.so' file path
        ldd_output=$(ldd "$so_file_path")

        # Check if there are dynamic dependencies and not statically linked before displaying the output
        if [ -n "$ldd_output" ] && ! grep -qE "(not a dynamic executable|statically linked)" <<< "$ldd_output"; then
            # Display the results 
            {
                echo -e "${GREEN}Process ID:${NC} $process_id"
                echo -e "${GREEN}Command Name:${NC} $command_name"
                echo -e "${RED}Path to '.so' file:${NC} $so_file_path"
                echo -e "${RED}\nDependencies:${NC}\n$ldd_output"
                echo "-------------------------"
            } | tee "$output_file"
        fi
    done
done <<< "$process_info"

echo "Output saved to $output_file"
