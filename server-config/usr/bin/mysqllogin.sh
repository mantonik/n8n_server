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
    local user=$(mysql_config_editor print --login-path="$path_name" 2>/dev/null | grep "user" | cut -d'=' -f2 | tr -d ' "')
    local host=$(mysql_config_editor print --login-path="$path_name" 2>/dev/null | grep "host" | cut -d'=' -f2 | tr -d ' "')
    
    # Set defaults if empty
    user=${user:-"root"}
    host=${host:-"localhost"}
    
    echo "${user}@${host}"
}

# Function to create new login path
create_login_path() {
    echo
    echo "Create New MySQL Login Path"
    echo "==========================="
    
    # Get login path name
    while true; do
        read -p "Enter login path name (or 'e' to exit): " login_path
        if [[ "$login_path" == "e" ]] || [[ "$login_path" == "E" ]] || [[ -z "$login_path" ]]; then
            echo "Exiting..."
            return 1
        fi
        if [[ "$login_path" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            break
        else
            echo "Invalid login path name. Use only letters, numbers, underscore, and dash."
        fi
    done
    
    # Get user
    while true; do
        read -p "Enter username (or 'e' to exit): " user
        if [[ "$user" == "e" ]] || [[ "$user" == "E" ]] || [[ -z "$user" ]]; then
            echo "Exiting..."
            return 1
        fi
        if [[ -n "$user" ]]; then
            break
        fi
    done
    
    # Get host
    while true; do
        read -p "Enter host/IP (or 'e' to exit): " host
        if [[ "$host" == "e" ]] || [[ "$host" == "E" ]] || [[ -z "$host" ]]; then
            echo "Exiting..."
            return 1
        fi
        if [[ -n "$host" ]]; then
            break
        fi
    done
    
    # Get port (optional)
    read -p "Enter port (press Enter for default 3306, or 'e' to exit): " port
    if [[ "$port" == "e" ]] || [[ "$port" == "E" ]]; then
        echo "Exiting..."
        return 1
    fi
    
    # Build the command
    cmd="mysql_config_editor set --login-path=$login_path --host=$host --user=$user"
    if [[ -n "$port" ]] && [[ "$port" != "3306" ]]; then
        cmd="$cmd --port=$port"
    fi
    cmd="$cmd --password"
    
    echo
    echo "Executing: $cmd"
    echo
    
    # Execute the command
    if eval "$cmd"; then
        echo
        echo "Login path '$login_path' created successfully!"
        echo "You can now use it to connect to MySQL."
        read -p "Press Enter to continue..."
        return 0
    else
        echo
        echo "Error: Failed to create login path."
        read -p "Press Enter to continue..."
        return 1
    fi
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
    echo "No login paths found. You can create one using option 'c'."
    echo "Example: mysql_config_editor set --login-path=mydb --host=localhost --user=myuser --password"
    # Don't exit, allow user to create login paths
    login_paths=""
fi

# Main menu loop
while true; do
    # Display menu
    echo
    echo "Available MySQL Login Paths:"
    echo "============================"

    # Convert login paths to array and display with numbers
    if [ -n "$login_paths" ]; then
        IFS=$'\n' read -d '' -r -a paths_array <<< "$login_paths"
        counter=1

        for path in "${paths_array[@]}"; do
            if [ -n "$path" ]; then
                info=$(get_login_path_info "$path")
                printf "%d - %-15s %s\n" "$counter" "$path" "$info"
                ((counter++))
            fi
        done
    else
        echo "No login paths found."
        counter=1
    fi

    echo "c - create login path"
    echo "0 - exit"
    echo

    # Get user selection
    read -p "Select option (0-$((counter-1)), c): " selection
    
    # Handle selection
    if [[ "$selection" == "0" ]]; then
        echo "Goodbye!"
        exit 0
    elif [[ "$selection" == "c" ]] || [[ "$selection" == "C" ]]; then
        if create_login_path; then
            # Refresh login paths list after successful creation
            login_paths=$(mysql_config_editor print --all 2>/dev/null | grep "^\[" | sed 's/\[\(.*\)\]/\1/')
        fi
        continue
    elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -lt "$counter" ]; then
        # Valid numeric selection
        selected_path="${paths_array[$((selection-1))]}"
        break
    else
        echo "Invalid selection. Please choose a valid option."
        continue
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