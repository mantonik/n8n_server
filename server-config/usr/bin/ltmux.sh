#!/bin/bash

# ltmux - List and select tmux sessions
# Usage: ltmux

# Function to display sessions and handle selection
select_tmux_session() {
    # Get list of tmux sessions and sort alphabetically
    sessions=$(tmux ls 2>/dev/null | cut -d: -f1 | sort)
    
    # Check if tmux is running and has sessions
    if [ $? -ne 0 ] || [ -z "$sessions" ]; then
        echo "No tmux sessions found or tmux server not running."
        echo "0 - Create new session"
        read -p "Enter your choice: " choice
        if [ "$choice" = "0" ]; then
            read -p "Enter new session name: " session_name
            if [ -n "$session_name" ]; then
                tmux new-session -s "$session_name"
            else
                echo "Session name cannot be empty."
            fi
        fi
        return
    fi
    
    # Display available sessions
    echo "Available tmux sessions:"
    echo "======================="
    
    # Convert sessions to array and display with numbers
    session_array=()
    counter=1
    
    while IFS= read -r session; do
        echo "$counter - $session"
        session_array+=("$session")
        ((counter++))
    done <<< "$sessions"
    
    echo "0 - Create new session"
    echo "======================="
    
    # Get user selection
    read -p "Enter your choice (0-$((counter-1))): " choice
    
    # Validate input
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a number."
        return 1
    fi
    
    # Handle selection
    if [ "$choice" = "0" ]; then
        # Create new session
        read -p "Enter new session name: " session_name
        if [ -n "$session_name" ]; then
            tmux new-session -s "$session_name"
        else
            echo "Session name cannot be empty."
        fi
    elif [ "$choice" -ge 1 ] && [ "$choice" -le "${#session_array[@]}" ]; then
        # Attach to selected session
        selected_session="${session_array[$((choice-1))]}"
        echo "Attaching to session: $selected_session"
        tmux attach -t "$selected_session"
    else
        echo "Invalid choice. Please select a number between 0 and $((counter-1))."
        return 1
    fi
}

# Run the function
select_tmux_session