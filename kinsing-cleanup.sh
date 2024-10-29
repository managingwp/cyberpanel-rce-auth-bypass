#!/usr/bin/env bash
VERSION="0.0.1"
INFECTED=0
FAILED=""

_loading () { echo -ne "\033[1;33m$1\033[0m"; }
_running () { echo -ne "\033[1;32m$1\033[0m"; }
_error () { echo -ne "\033[1;31m$1\033[0m"; }
_warning () { echo -ne "\033[1;33m$1\033[0m"; }
_success () { echo -ne "\033[1;32m$1\033[0m"; }

# Check to see if the script is being run as root
if [ "$EUID" -ne 0 ]; then
  _error "Please run as root"
  exit
fi

# ===============================================
# -- _check_running_kinsing
# ===============================================
_check_for_running_kinsing () {
    $(pgrep kdevtmpfsi > /dev/null)
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# ===============================================
# -- _check_immutable $LOCATION
# ===============================================
_check_immutable () {
    # Check if $LOCATION is immutable
    LOCATIONS=( $LOCATION $(dirname $LOCATION) )
    for ITEM in ${LOCATIONS[@]}; do
        # Check if -i or -a is set
        if [[ $(lsattr $ITEM | grep -E 'i|a') ]]; then
            _error "$ITEM is immutable\n"
            _running "Attempting to remove immutable flag\n"
            chattr -ia $ITEM
            if [[ $? -eq 0 ]]; then
                _running "Removed immutable flag from $ITEM\n"
            else
                _error "Failed to remove immutable flag from $ITEM\n"
                FAILED="$ITEM"
            fi
        else
            _running "$ITEM is not immutable\n"
        fi
    done
}


_loading "Checking for kinsing malware... "
if [ -f /tmp/kdevtmpfsi ]; then
    _warning "Found kinsing malware\n"
    INFECTED=1
    # Use ps to see if kdevtmpfsi is running
elif [[ $(_check_running_kinsing) ]]; then
    _warning "Found kinsing malware running as a process"
    INFECTED=1
else
    _success "No kinsing malware found\n"
fi

_loading "Proceeding to clean kinsing malware from system"

# =================================================================================================
# Step 1: Disable cron
# =================================================================================================
_loading "Step 1: Disable cron"
systemctl stop cron
[[ $? -eq 0 ]] && _success "Cron service stopped\n" || _error "Failed to stop cron service\n"


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
            _running "Deleted $LOCATION\n" 
        else
            _error "Failed to delete $LOCATION\n"
            _running "Checking if $LOCATION is immutable\n"
            _check_immutable $LOCATION
        fi
    elif [ -d $LOCATION ]; then
        rm -rf $LOCATION
        [[ $? -eq 0 ]]; _success "Deleted $LOCATION\n" || _error "Failed to delete $LOCATION\n"
    else
        _running "$LOCATION not found\n"
    fi
done

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
    systemctl stop $SERVICE
    systemctl disable $SERVICE
    rm -f /etc/systemd/system/$SERVICE.service
    [[ $? -eq 0 ]] && _success "Removed $SERVICE service\n" || _error "Failed to remove $SERVICE service\n"
done

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

for PROCESS in ${SUSPICIOUS_PROCESS[@]}; do
    pkill -f $PROCESS
    [[ $? -eq 0 ]] && _success "Killed $PROCESS process\n" || _error "Failed to kill $PROCESS process\n"
done

# =================================================================================================
# Step 5: Unload pre-loaded libraries (Delete /etc/ld.so.preload)
# =================================================================================================
_loading "Step 5: Unload pre-loaded libraries"
if [ -f /etc/ld.so.preload ]; then
    rm -f /etc/ld.so.preload
    [[ $? -eq 0 ]] && _success "Deleted /etc/ld.so.preload\n" || _error "Failed to delete /etc/ld.so.preload\n"
else
    _warning "/etc/ld.so.preload not found\n"
fi

_running "Restarting services\n"
lsof | grep libsystem.so | awk '{ print $2 }' | xargs kill -9

# =================================================================================================
# Step 6: Remove Malicious Cron Jobs
# =================================================================================================
_loading "Step 6: Remove Malicious Cron Jobs"
CRONTAB_FILES=(
    /var/spool/cron/crontabs/root
    /var/spool/cron/root
)
MALICIOUS_MATCH=(
    kdevtmpfsi
    unk.sh
    atdb
    cp.sh
    p.sh
    wget
)

for CRON_FILE in ${CRONTAB_FILES[@]}; do
    if [ -f $CRON_FILE ]; then
        _check_immutable $CRON_FILE
        for MATCH in ${MALICIOUS_MATCH[@]}; do
            # check if the cron file contains the malicious match and remove line
            MATCHED_LINE=$(grep $MATCH $CRON_FILE)
            MATCHED_LINE_STATUS=$?
            if [[ $MATCHED_LINE_STATUS -eq 0 ]]; then
                _running "Removing $MATCH from $CRON_FILE\n"
                sed -i "/$MATCH/d" $CRON_FILE
                [[ $? -eq 0 ]] && _success "Removed $MATCH from $CRON_FILE\n" || _error "Failed to remove $MATCH from $CRON_FILE\n"
            else
                _running "$MATCH not found in $CRON_FILE\n"
            fi
        done
    else
        _running "$CRON_FILES not found\n"
    fi
done
