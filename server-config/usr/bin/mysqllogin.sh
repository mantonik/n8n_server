#!/bin/bash

# MySQL Login Path Selector Script
# This script displays available MySQL login paths and connects using mysqlsh or mysql

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get login path details
get_login_path_info() {
    local path_name="$1"
    local user=$(mysql_config_editor print --login-path="$path_name" 2>/dev/null | grep "user" | cut -d'=' -f2 | tr -d ' ')
    local host=$(mysql_config_editor print --login-path="$path_name" 2>/dev/null | grep "host" | cut -d'=' -f2 | tr -d ' ')
    
    # Set defaults if empty
    user=${user:-"root"}
    host=${host:-"localhost"}
    
    echo "${user}@${host}"
}

# Check if mysql_config_editor is available
if ! command_exists mysql_config_editor; then
    echo "Error: mysql_config_editor not found. Please ensure MySQL is properly installed."
    exit 1
fi

# Get list of login paths
echo "Getting available MySQL login paths..."
login_paths=$(mysql_config_editor print --all 2>/dev/null | grep "^\[" | sed 's/\[\(.*\)\]/\1/')

if [ -z "$login_paths" ]; then
    echo "No login paths found. Please create login paths using mysql_config_editor."
    echo "Example: mysql_config_editor set --login-path=mydb --host=localhost --user=myuser --password"
    exit 1
fi

# Display menu
echo
echo "Available MySQL Login Paths:"
echo "============================"

# Convert login paths to array and display with numbers
IFS=$'\n' read -d '' -r -a paths_array <<< "$login_paths"
counter=1

for path in "${paths_array[@]}"; do
    if [ -n "$path" ]; then
        info=$(get_login_path_info "$path")
        printf "%d - %-15s %s\n" "$counter" "$path" "$info"
        ((counter++))
    fi
done

echo "0 - exit"
echo

# Get user selection
while true; do
    read -p "Select login path (0-$((counter-1))): " selection
    
    # Validate input
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        if [ "$selection" -eq 0 ]; then
            echo "Goodbye!"
            exit 0
        elif [ "$selection" -ge 1 ] && [ "$selection" -lt "$counter" ]; then
            # Valid selection
            selected_path="${paths_array[$((selection-1))]}"
            break
        else
            echo "Invalid selection. Please choose a number between 0 and $((counter-1))."
        fi
    else
        echo "Please enter a valid number."
    fi
done

# Connect using selected login path
echo
echo "Connecting to: $selected_path ($(get_login_path_info "$selected_path"))"

# Check if mysqlsh is available, otherwise use mysql
if command_exists mysqlsh; then
    echo "Using MySQL Shell (mysqlsh)..."
    mysqlsh --login-path="$selected_path"
elif command_exists mysql; then
    echo "Using MySQL client (mysql)..."
    mysql --login-path="$selected_path"
else
    echo "Error: Neither mysqlsh nor mysql command found."
    echo "Please install MySQL client or MySQL Shell."
    exit 1
fi