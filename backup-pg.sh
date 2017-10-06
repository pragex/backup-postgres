#!/bin/bash

date=$(date "+%Y-%m-%d")
bf="${0##*/}"
log="log.txt"
incremental=false

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

if [ "${incremental}" == true ]; then
    opt="-b"
    ext="sql"
else
    opt="-Fc"
    ext="dump"
fi


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

	    pg_dump  "${opt}" -U "${user}" -h "${host}" "${db}" > "${dest}${db}_${date}.${ext}" 2>> "${dest}${log}"

	    if [ $? -eq 0 ]; then
		msg="Dump: '${db}'... ok"

		if [ "${incremental}" == true ]; then
		    
		    if [ -f "${dest}${db}.${ext}" ]; then
		      cmp -s "${dest}${db}.${ext}" "${dest}${db}_${date}.${ext}"

		      if [ $? -eq 0 ]; then #no change
			  rm "${dest}${db}_${date}.${ext}"
			  msg="Dump: '${db}'... no change"
		      fi
		    fi

		    if [ -f "${dest}${db}_${date}.${ext}" ]; then
		      mv "${dest}${db}_${date}.${ext}" "${dest}${db}.${ext}"
		    fi
		fi
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
