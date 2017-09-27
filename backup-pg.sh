#!/bin/bash

date=$(date "+%Y-%m-%d")
bf="${0##*/}"
log="log.txt"

if [[ "$1" = "--help" || "$1" = "--version" || "$1" = "-h" ]]; then
    echo "${bf}: backup PostgreSQL"
    echo "use: ${bf} [HOST] [DIRECTORY] [USER] [USER_DB]"    
    exit
fi

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    echo -n "$var"
}

if [ $# -lt 1 ]; then
    host="127.0.0.1"
else
    host="$1"
fi

if [ $# -lt 2 ]; then
    dest=pg_backup
else
    dest="$2"
fi

if [ $# -lt 3 ]; then
    user=postgres
else
    user="$3"
fi

user_db="$4"


if [ ! -d "${dest}" ]; then
    mkdir "${dest}"

    if [ $? -ne 0 ]; then
	echo "error: unable to create folder \"${dir}\""
	exit 2
    fi
fi

if [[ "${dest: -1}" != "/" ]]; then
    dest+="/"
fi


msg="Server: ${user}@${host}"
echo "${msg}"
echo "${msg}" > "${dest}${log}"
echo ""

psql -U "${user}" -h "${host}" "${user_db}" -tc "SELECT datname FROM pg_database WHERE datistemplate = false;" |
    while IFS= read -r line;
    do
	if [ -n "${line}" ]; then
	    db=$(trim "${line}")

	    pg_dump  -U "${user}" -h "${host}" "${db}" -Fc > "${dest}${db}_${date}.dump" 2>> "${dest}${log}"
	    
	    if [ $? -eq 0 ]; then
		msg="Dump: '${db}'... ok"
	    else
		msg="Dump: '${db}'... fail"
	    fi

	    echo "$msg"
	    echo "$msg"  >> "${dest}${log}"
	fi
    done

fin=$(date "+%A %e %b %Y %X")
echo "Done: $fin"  >> "${dest}${log}"

exit 0
