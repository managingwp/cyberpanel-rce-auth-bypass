#!/usr/bin/env bash
VERSION="0.0.6"
INFECTED=0
FAILED=""

# _loading should be yellow background and black text
_loading () { echo -e "\033[0;103;30m$1\033[0m"; }
_loading2 () { echo -e "\033[0;44;97m$1\033[0m"; }
_running () { echo -e " \033[1;30m - ${1}\033[0m"; }
_error () { echo -e "\033[1;31m*ERROR*: ${1}\033[0m"; }
_warning () { echo -e "  \033[1;33m*WARNING*: ${1}\033[0m"; }
_success () { echo -e "\033[1;32m*SUCCESS*: ${1}\033[0m"; }

# Check to see if the script is being run as root
if [ "$EUID" -ne 0 ]; then
  _error "Please run as root"
  exit
fi

# ===============================================
# -- _check_immutable $LOCATION
# ===============================================
_check_immutable () {
    # Check if $LOCATION is immutable
    local LOCATIONS LOCATION
    LOCATION=$1
    LOCATIONS=( $LOCATION $(dirname $LOCATION) )
    for ITEM in ${LOCATIONS[@]}; do        
        # Check if -i or -a is set
        if [[ $(lsattr -d $ITEM |  awk '{ print $1 }' | grep -E 'i|a') ]]; then
            _running "Checking if $ITEM is immutable...$(_error "$ITEM is immutable")"
            chattr -ia $ITEM
            if [[ $? -eq 0 ]]; then
                _running "Attempting to remove immutable flag $(_success "Removed immutable flag from $ITEM")"
            else
                _running "Attempting to remove immutable flag $(_error "Failed to remove immutable flag from $ITEM")"                
                FAILED="$ITEM"
            fi
        else
            _running "$ITEM is not immutable"
        fi
    done
}

# ===============================================
# -- _check_for_running_kinsing
# ===============================================
_check_for_running_kinsing () {
    KINSING_PROCESSES=(
        kdevtmpfsi
        kinsing
        xmrig
        xmrigDaemon
        xmrigMiner
        xmrigMinerd
        xmrigMinerDaemon
        xmrigMinerServer
        xmrigMinerServerDaemon
        udiskssd
        bash2
        .network-setup
        syshd
        atdb
        /usr/.network-setup/config.json
    )
    for PROCESS in ${KINSING_PROCESSES[@]}; do
        $(pgrep $PROCESS > /dev/null)
        if [ $? -eq 0 ]; then
            return 0
        fi
    done
}

# ===============================================
# -- _check_patch
# -- Check if /usr/local/CyberCP/databases/views.py is patched
# ===============================================
_check_patch () {
    local VIEWS_PY GREP
    VIEWS_PY="/usr/local/CyberCP/databases/views.py"
    GREP=$(grep -B5 'currentACL = ACLManager.loadedACL(userID)' /usr/local/CyberCP/databases/views.py | grep -q upgrademysqlstatus)
    if [[ $? -ne 0 ]]; then
        _error "$VIEWS_PY is not patched."
        _running "Downloading and replacing views.py..."
        wget -q https://raw.githubusercontent.com/usmannasir/cyberpanel/refs/heads/stable/databases/views.py -O /usr/local/CyberCP/databases/views.py
        if [[ $? -eq 0 ]]; then
            _success "views.py has been updated."
        else
            _error "Failed to update views.py."
        fi
    else
        _success "views.py is already up-to-date."
    fi
}

# =================================================================================================
# -- Main
# =================================================================================================

# ===============================================
# -- Check 1: Check for running kinsing malware
# ===============================================
_loading "Check 1: Checking for running kinsing malware... "
if [[ $(_check_for_running_kinsing) ]]; then
    _warning "Found kinsing malware"
    INFECTED=1
    # Use ps to see if kdevtmpfsi is running
else
    _success "No kinsing malware found running"
fi
echo


# ===============================================
# -- Check 2: Check if /usr/local/CyberCP/databases/views.py is patched
# ===============================================
_loading "Check 2: Check if /usr/local/CyberCP/databases/views.py is patched... "
_check_patch
echo

# ===============================================
# -- Start Cleanup
# ===============================================
_loading "Proceeding to clean kinsing malware from system"
echo

# ===============================================
# Step 1: Disable cron
# ===============================================
_loading "Step 1: Disable cron"
systemctl stop cron
if [[ $? -eq 0 ]]; then 
    _success "Cron service stopped"
else
    _error "Failed to stop cron service"
fi
echo


# =================================================================================================
# Step 2: Delete Malware Files
# =================================================================================================
_loading "Step 2: Delete Malware Files"
MALWARE_LOCATION=(
    /etc/data/kinsing
    /etc/kinsing
    /tmp/kdevtmpfsi
    /tmp/kinsing
    /var/tmp/kinsing
    /usr/lib/secure
    /usr/lib/secure/udiskssd
    /usr/bin/network-setup.sh
    /usr/.sshd-network-service.sh
    /usr/.network-setup
    /usr/.network-setup/config.json
    /usr/.network-setup/xmrig-*tar.gz
    /usr/.network-watchdog.sh
    /etc/data/libsystem.so
    /etc/data/kinsing
    /dev/shm/kdevtmpfsi
    /tmp/.ICEd-unix
    /var/tmp/.ICEd-unix
)

for LOCATION in ${MALWARE_LOCATION[@]}; do    
    if [ -f $LOCATION ]; then
        rm -f $LOCATION
        if [[ $? -eq 0 ]]; then
            _running "Checking $LOCATION $(_success "Deleted $LOCATION")"
        else
            _running "Checking $LOCATION $(_error "Failed to delete $LOCATION")"            
            _check_immutable $LOCATION
        fi
    elif [ -d $LOCATION ]; then
        rm -rf $LOCATION
        [[ $? -eq 0 ]]; _success "Deleted $LOCATION" || _error "Failed to delete $LOCATION"
    else
        _running "Checking $LOCATION $(_success "$LOCATION not found")"
    fi
done
echo

# =================================================================================================
# Step 3: Remove Suspicious Service
# =================================================================================================
_loading "Step 3: Remove Suspicious Service"
SUSPICIOUS_SERVICE=(
    bot
    system_d
    sshd-network-service
    network-monitor
)

for SERVICE in ${SUSPICIOUS_SERVICE[@]}; do
    # Check if service exists
    systemctl is-active --quiet $SERVICE
    if [[ $? -eq 0 ]]; then
        _running "Checking if $SERVICE is setup $(_warning "$SERVICE found")"
        _running "Stopping, disabling and removing $SERVICE service"
        systemctl stop $SERVICE
        systemctl disable $SERVICE
        rm -f /etc/systemd/system/$SERVICE.service    
    else
        _running "Checking if $SERVICE is setup $(_success "$SERVICE not found")"
        continue
    fi
done
echo

# =================================================================================================
# Step 4: Kill Suspicious Processes
# =================================================================================================
_loading "Step 4: Kill Suspicious Processes"
SUSPICIOUS_PROCESS=(
    kdevtmpfsi
    kinsing
    xmrig
    xmrigDaemon
    xmrigMiner
    xmrigMinerd
    xmrigMinerDaemon
    xmrigMinerServer
    xmrigMinerServerDaemon
    udiskssd
    bash2
    .network-setup
    syshd
    atdb
)
# Don't kill the script itself
SCRIPT_PID=$$
_loading2 "Running as PID: $SCRIPT_PID"
for PROCESS_GREP in ${SUSPICIOUS_PROCESS[@]}; do
    _running "Checking for $PROCESS_GREP"

    PIDS_TO_KILL=($(pgrep -f $PROCESS_GREP))
    # remove script PID from PIDS_TO_KILL
    PIDS_TO_KILL=(${PIDS_TO_KILL[@]/$SCRIPT_PID})

    if [[ ${#PIDS_TO_KILL[@]} -eq 0 ]]; then
        _success "No $PROCESS_GREP found"
        continue
    else
        
        _warning "Found $PIDS_TO_KILL instances of $PROCESS_GREP"
        for PID in ${PIDS_TO_KILL[@]}; do
            # Get process name from PID
            PROCESS=$(ps -p $PID -o comm=)
            if [[ $PID -eq $SCRIPT_PID ]]; then
                continue
            fi
            _running "Killing: ${PROCESS}:${PID} $(_warning "Found $PROCESS")"
            kill -9 $PID
        done
    fi
done
echo

# =================================================================================================
# Step 5: Unload pre-loaded libraries (Delete /etc/ld.so.preload)
# =================================================================================================
_loading "Step 5: Unload pre-loaded libraries"
if [ -f /etc/ld.so.preload ]; then
    rm -f /etc/ld.so.preload
    [[ $? -eq 0 ]] && _success "Deleted /etc/ld.so.preload" || _error "Failed to delete /etc/ld.so.preload"
    _running "Restarting services"
    RUNNING_PROCS_INJECTED=$(lsof | grep libsystem.so)
    if [[ -n $RUNNING_PROCS_INJECTED ]]; then
        _running "Killing processes with libsystem.so"
        echo $RUNNING_PROCS_INJECTED | awk '{ print $2 }' | xargs kill -9
    else
        _success "No processes found with libsystem.so"
    fi
else
    _success "/etc/ld.so.preload not found"
fi
echo


# =================================================================================================
# Step 6: Remove Malicious Cron Jobs
# =================================================================================================
_loading "Step 6: Remove Malicious Cron Jobs"
CRONTAB_FILES=(
    /var/spool/cron/crontabs/root
    /var/spool/cron/root
)
MALICIOUS_MATCH_CRON=(
    kdevtmpfsi
    unk.sh
    atdb
    cp.sh
    p.sh
    wget
)

for CRON_FILE in ${CRONTAB_FILES[@]}; do
    _loading2 "Checking if $CRON_FILE exists"
    if [ -f $CRON_FILE ]; then        
        _check_immutable $CRON_FILE
        for MATCH in ${MALICIOUS_MATCH_CRON[@]}; do
            # check if the cron file contains the malicious match and remove line
            MATCHED_LINE=$(grep $MATCH $CRON_FILE)
            MATCHED_LINE_STATUS=$?
            if [[ $MATCHED_LINE_STATUS -eq 0 ]]; then
                _running "Removing $MATCH from $CRON_FILE"
                # Make a backup of the cron file
                cp $CRON_FILE $CRON_FILE.bak
                sed -i "/$MATCH/d" $CRON_FILE
                [[ $? -eq 0 ]] && _success "Removed $MATCH from $CRON_FILE" || _error "Failed to remove $MATCH from $CRON_FILE"
            else
                _running "$MATCH not found in $CRON_FILE"
            fi
        done
    else
        _running "$CRON_FILES not found"
    fi
done

# =================================================================================================
# Step 8: Start Cron
# =================================================================================================
_loading "Step 8: Start Cron"
systemctl start cron
[[ $? -eq 0 ]] && _success "Cron service started" || _error "Failed to start cron service"
echo
