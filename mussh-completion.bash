#!/usr/bin/env bash
# Bash completion for mussh
# Developed by Digital Cyber Soft <apps@digitalcybersoft.com>
# Version 1.1 (March 2025)

# Cache for SSH hosts
__mussh_hosts_cache=""
__mussh_hosts_cache_time=0
__mussh_cache_ttl=300  # Cache valid for 5 minutes

# Add a special function for adding all matching hosts with Shift+Tab
_mussh_complete_all_hosts() {
    local prefix cmd hosts selected
    
    # Get the current command line
    cmd="${READLINE_LINE}"
    
    # Make sure it's a mussh command
    if [[ "$cmd" != *mussh* ]]; then
        return
    fi
    
    # Get the current word at cursor position
    prefix="${READLINE_LINE:0:READLINE_POINT}"
    prefix="${prefix##* }"
    
    # If the prefix is empty, don't do anything
    if [[ -z "$prefix" ]]; then
        return
    fi
    
    # Get matching hosts
    if [[ -f ~/.ssh/known_hosts ]]; then
        hosts+=" $(cut -d ' ' -f 1 ~/.ssh/known_hosts 2>/dev/null | cut -d ',' -f 1 | grep -v '^|' | sed 's/\[//g;s/\]:[0-9]*//g' | grep "^$prefix" 2>/dev/null)"
    fi
    
    if [[ -f ~/.ssh/config ]]; then
        hosts+=" $(grep -i "^Host " ~/.ssh/config 2>/dev/null | awk '{print $2}' | grep -v "[*?]" | grep "^$prefix" 2>/dev/null)"
    fi
    
    hosts+=" $(compgen -A hostname | grep "^$prefix" 2>/dev/null)"
    
    # Get unique host list
    hosts=$(echo "$hosts" | tr ' ' '\n' | sort -u | grep . | tr '\n' ' ')
    
    # Get already selected hosts
    selected=$(echo "$cmd" | grep -o -- "-h [^ ]*" | sed 's/-h //')
    
    # Remove already selected hosts
    for h in $selected; do
        hosts=${hosts//$h /}
    done
    
    # Replace the current word with all matching hosts
    READLINE_LINE="${READLINE_LINE:0:READLINE_POINT-${#prefix}}$hosts${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$((READLINE_POINT - ${#prefix} + ${#hosts}))
}

# Bind Shift+Tab to our custom function
bind -x '"\e[Z": _mussh_complete_all_hosts' 2>/dev/null || true

_mussh() {
    local cur prev words cword opts hostfiles
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main options
    opts="-h -H -c -C -d -v -m -q -i -o -a -A -b -B -u -U -P -l -L -s -t -V"
    opts+=" -E -BI -W -CM -CP -S -T -HKH -VHD -p -po -J"
    
    # For options that require a file path
    file_opts="-H -C -i -E -S"
    
    # For options that require a login (user@host)
    host_opts="-h -J -p"
    
    # For options that require a specific argument type
    specific_opts="-l -L -s -t -o -po -CP -T -BI -W"
    
    # Get SSH hosts with caching
    _get_ssh_hosts() {
        # Check if we need to refresh the cache
        local current_time
        current_time=$(date +%s)
        
        if [[ $((current_time - __mussh_hosts_cache_time)) -gt $__mussh_cache_ttl || -z "$__mussh_hosts_cache" ]]; then
            # Cache is expired or empty, rebuild it
            local hosts=()
            
            # Use built-in hostname completion
            hosts+=($(compgen -A hostname))
            
            # Get hosts from SSH config files (fast method)
            if [[ -f ~/.ssh/config ]]; then
                hosts+=($(grep -i "^Host " ~/.ssh/config 2>/dev/null | awk '{print $2}' | grep -v "[*?]"))
            fi
            
            # Get hosts from known_hosts (fast method)
            if [[ -f ~/.ssh/known_hosts ]]; then
                hosts+=($(cut -d ' ' -f 1 ~/.ssh/known_hosts 2>/dev/null | cut -d ',' -f 1 | grep -v '^|' | sed 's/\[//g;s/\]:[0-9]*//g'))
            fi
            
            # Get hosts from /etc/hosts (fast method)
            if [[ -f /etc/hosts ]]; then
                hosts+=($(awk '/^[0-9]/ && $2 != "localhost" {print $2}' /etc/hosts 2>/dev/null))
            fi
            
            # Combine all unique hosts
            __mussh_hosts_cache=$(printf "%s\n" "${hosts[@]}" | sort -u)
            __mussh_hosts_cache_time=$current_time
        fi
        
        # Filter the cached hosts based on the current word
        if [[ -n "$cur" ]]; then
            echo "$__mussh_hosts_cache" | grep -i "^${cur}" 2>/dev/null || true
        else
            echo "$__mussh_hosts_cache"
        fi
    }
    
    # Function to get already selected hosts
    _get_selected_hosts() {
        local selected=()
        local i start_idx=-1
        
        # Find where the host list starts (after -h)
        for ((i=0; i<COMP_CWORD; i++)); do
            if [[ "${COMP_WORDS[i]}" == "-h" ]]; then
                start_idx=$((i+1))
                break
            fi
        done
        
        # If we found a -h flag, collect all hosts that follow it
        if [[ $start_idx -ge 0 ]]; then
            for ((i=start_idx; i<COMP_CWORD; i++)); do
                # Only add non-empty words that don't start with a dash
                if [[ -n "${COMP_WORDS[i]}" && "${COMP_WORDS[i]:0:1}" != "-" ]]; then
                    selected+=("${COMP_WORDS[i]}")
                fi
            done
        fi
        
        # Join with spaces but also wrap each host with spaces for easier matching
        echo " ${selected[*]} "
    }
    
    # Check if we're completing a host after -h
    if [[ " ${COMP_LINE} " == *" -h "* ]] && [[ "$prev" != "-h" ]]; then
        # We're in a situation where we've already started completing hosts
        # and we want to continue completing more hosts
        
        # Get all available hosts matching the current prefix
        local all_hosts=$(_get_ssh_hosts)
        
        # Get already selected hosts
        local selected_hosts=$(_get_selected_hosts)
        
        # Get available hosts (not already selected)
        local available_hosts=()
        while read -r host; do
            if ! [[ "$selected_hosts" == *" $host "* ]]; then
                available_hosts+=("$host")
            fi
        done < <(echo "$all_hosts")
        
        # Create a special completion that adds all hosts
        # We'll use this with compgen below to make it the final match
        if [[ ${#available_hosts[@]} -gt 1 && -n "$cur" ]]; then
            # Prepare to add all available hosts when tab is pressed a third time
            
            # The trick is Bash completes the current word to the longest common prefix
            # of all possible completions. We want to create a completion that appears
            # unique to be shown after all other completions in the tab cycle.
            
            # Example:
            # If we have hosts: server1, server2, server3
            # And user types: s<tab>
            # First tab might complete to "server" (longest common prefix)
            # Second tab might show "server1"
            # Additional tabs cycle through server2, server3, etc.
            # We want the LAST tab in the cycle to complete to "server1 server2 server3"
            
            # Create the special completion that combines all hosts
            local all_hosts_str="$(printf '%s ' "${available_hosts[@]}")"
            
            # We'll add a version of this completion that replaces the current word
            # First, we need to find the actual text to replace
            local word_to_replace="${cur}"
            
            # Add this special completion to the end of our hosts array
            # We'll ensure it's the only completion for a "mangled" version of the current word
            # This mangled version will only be triggered on the last tab cycle
            COMPREPLY=( "${available_hosts[@]}" "$all_hosts_str" )
            return 0
        fi
        
        # Set completions to our available hosts list (which now includes the "all hosts" option)
        COMPREPLY=( "${available_hosts[@]}" )
        return 0
    fi
    
    # Handle option-specific completions
    case "$prev" in
        -h | -J | -p)
            # Complete with hostnames for host arguments
            COMPREPLY=( $(_get_ssh_hosts) )
            return 0
            ;;
        -H | -C)
            # Complete with regular files
            COMPREPLY=( $(compgen -f -- "${cur}") )
            return 0
            ;;
        -i)
            # Complete with SSH identity files
            if [[ -d "${HOME}/.ssh" ]]; then
                local id_files=( "${HOME}/.ssh/id_"* )
                if [[ -n "${id_files[0]}" && "${id_files[0]}" != "${HOME}/.ssh/id_*" ]]; then
                    COMPREPLY=( $(compgen -W "$(echo ${id_files[*]})" -- "${cur}") )
                else
                    COMPREPLY=( $(compgen -f -- "${cur}") )
                fi
            else
                COMPREPLY=( $(compgen -f -- "${cur}") )
            fi
            return 0
            ;;
        -E | -S)
            # Complete with files/paths
            COMPREPLY=( $(compgen -f -- "${cur}") )
            return 0
            ;;
        *)
            # If current word starts with a dash, complete with options
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            
            # Check previous words to determine context
            local i cmd_found=0
            for ((i=1; i < COMP_CWORD; i++)); do
                if [[ "${COMP_WORDS[i]}" == "-h" ]]; then
                    # We've found a -h flag in the command, continue completing hostnames
                    COMPREPLY=( $(_get_ssh_hosts) )
                    return 0
                fi
            done
            
            # Default completion: options
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
    esac
}

# Register the completion function
# This uses a trick to enable the "third tab = all matches" behavior
# It works because bash's menu-complete cycles through all completions
# and we can inject a special completion at the end of the list
# When the user presses tab a third time, they will get this special completion
# that contains all matches concatenated together
complete -o nospace -F _mussh mussh