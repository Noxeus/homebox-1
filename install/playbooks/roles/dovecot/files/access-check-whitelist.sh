#!/bin/dash

# Check if the connection is from a whitelisted IP address or network.

# Post login script for Dovecot, this is parsed by the parrent script.
# Blocking: Yes
# RunAsUser: Yes
# NeedDecryptKey: No
# Score: Bonus
# Description: IP whitelist management

# Whitelisted IP address score:
WHITELIST_SCORE=$(grep WHITELIST_BONUS /etc/homebox/access-check.conf | cut -f 2 -d =)

# Do not change anything when the IP address is not found
NEUTRAL=0

# Security directory for the user, where the connection logs are saved
# and the custom comfiguration overriding
secdir="$HOME/security"

# User customisation directory
userconfDir="$HOME/.config/homebox"

# Create a unique lock file name for this IP address
# Exit if a script already check this IP address
ipSig=$(echo "$IP" | md5sum | cut -f 1 -d ' ')
lockFile="$secdir/$ipSig.lock"
test -f "$lockFile" && exit $WHITELIST_SCORE

# Needed the cidr grep executable
if [ ! -x /usr/bin/grepcidr ]; then
    logger -p user.warning "The program grepcidr is not found or not executable"
    exit $NEUTRAL
fi

# Start processing, but remove lockfile on exit
touch "$lockFile"
trap 'rm -f $lockFile' EXIT

# List of well known and trusted IP addresses
whitelistFile="$userconfDir/ip-whitelist.txt"

# No whitelist defined for this user
if [ ! -r "$whitelistFile" ]; then
    exit $NEUTRAL
fi

# Check if the IP address is whitelisted
whitelisted="0"
if [ -r "$whitelistFile" ]; then
    whitelisted=$(grepcidr -x -c "$IP" "$whitelistFile")
fi

# Exit directly if the IP address has been whitelisted
if [ "$whitelisted" != "0" ]; then
    echo "IP address is whitelisted by $USER"
    exit $WHITELIST_SCORE
fi

# Continue the normal access by default
exit $NEUTRAL
