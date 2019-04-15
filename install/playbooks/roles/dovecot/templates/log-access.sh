#!/bin/sh

# Post login script for Dovecot
# Blocking: Yes
# RunAsUser: Yes
# NeedDecryptKey: No

# If remote IP is 127.0.0.1, exit
# This is probably a webmail
# There is an attempt from the parent script
# to guess the real IP address , although
# it can be wrong for sites with a lot of
# email users, but it should be enough for a family
# or small numbers of users

log_error() {
    echo "$@" 1>&2;
}

# Accessed through a webmail
if [ "${IP}" = "127.0.0.1" ]; then
    exit 0
fi

if [ "${IP}" = "" ]; then
    log_error "No IP received for IP logging"
fi

# Initialise the environment
secdir="${HOME}/mails/security"
unixtime=$(date +%s)
day=$(date --rfc-3339=seconds | cut -f 1 -d ' ')
time=$(date --rfc-3339=seconds | cut -f 2 -d ' ')
hourmin=$(date --rfc-3339=seconds | cut -f 2 -d ' ' | cut -f 1,2 -d ':')

# Check if the GeoIP lookup binary is available
test -x /usr/bin/geoiplookup || exit 0

# Needed to ignore local IP addresses
test -x /usr/bin/ipcalc || exit 0

# Create the security directory for the user
test -d "${secdir}" || mkdir "${secdir}"

# Check if we already log this IP
ipSig=$(echo "${IP}" | md5sum | cut -f 1 -d ' ')
lockFile="${secdir}/${ipSig}.lock"

# The file that will contains the connection logs
connLogFile="${secdir}/connections.log"

# Exit if we are currently logging this IP
test -f "${lockFile}" && exit 0

# Start processing
touch "${lockFile}"
sync "${lockFile}"

# Remove lockfile on exit
trap "rm -f ${lockFile}" EXIT

# Create the file if it not exists
test -f "${connLogFile}" || touch "${connLogFile}"

# Exit if I cannot create the log file
test -f "${connLogFile}" || exit 0

# Check if already logged in from this IP in the current hour
# TODO: Use unix time
count=$(grep "${IP}" "${connLogFile}" | grep -c "^${day} ${hourmin}")

# Already logged in from this IP in the last hour
if [ "${count}" != "0" ]; then
    exit 0
fi

# Check if this is a private IP address
isPrivate=$(ipcalc "$IP" | grep -c "Private Internet")
isIPv6=$(echo "$IP" | grep -c ":")

# Create a log line with the origin
if [ "${isPrivate}" = "1" ]; then
    countryCode='-'
    countryName='-'
    lookup=''
elif [ "${isIPv6}" = "1" ]; then
    lookup=$(geoiplookup6 "$IP")
else
    lookup=$(geoiplookup "$IP")
fi

# Check if the country is found or not
notFound=$(echo "${lookup}" | grep -c 'IP Address not found')

if [ "${notFound}" = "1" ]; then
    # Country not found, use Neverland ;-)
    countryCode="XX"
    countryName="Neverland"
elif [ "${isPrivate}" = "0" ]; then
    countryCode=$(echo "${lookup}" | sed -r 's/.*: ([A-Z]{2}),.*/\1/g')
    countryName=$(echo "${lookup}" | cut -f 2 -d , | sed 's/^ //' | sed 's/ /_/g')
fi


# Add the IP to the list, need validatation
echo "${day} ${time} ${unixtime} ${IP} ${countryCode} ${countryName} ${SOURCE} NEW" >> "${connLogFile}"
sync "${connLogFile}"

# Remove old entries from the log connections
# Keep 1 year for now.

# End processing
rm -f "${lockFile}"
