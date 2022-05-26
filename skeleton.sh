#!/bin/bash

# ------------------------------------------------------------------------------
# Globals
# ------------------------------------------------------------------------------

declare -A ARGS
PACKAGE_FEED_URI="@PACKAGE_FEED_URI@"
PACKAGE_FEED_BASE_PATH="@PACKAGE_FEED_BASE_PATH@"



# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

function printUsage {
    echo "Usage: ${SCRIPT_NAME} [OPTION...]"
    cat << EOF
OPTIONS:
    -V, --version   Show installed image version
    -h, --help      Print this help message
EOF
exit 0
}

function checkCorrectUri {
    if [ "${PACKAGE_FEED_URI:(-1)}" = "/" ]; then
        PACKAGE_FEED_URI="${PACKAGE_FEED_URI:0:-1}"
    fi

    if [ "${PACKAGE_FEED_BASE_PATH:(-1)}" = "/" ]; then
        PACKAGE_FEED_BASE_PATH="${PACKAGE_FEED_BASE_PATH:0:-1}"
    fi
}

# ------------------------------------------------------------------------------
# Argument processing
# ------------------------------------------------------------------------------

TEMP=`getopt -o Vh --long version,help \
    -n $(basename $0) -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 2; fi

eval set -- "$TEMP"

while true; do
    case $1 in
        -V|--version) echo $(lsb_release -rs) ; exit ;;
        -h|--help) printUsage ; shift ;;
        --) shift ; break ;;
        *) echo "Unrecognized option '$1'";
            printUsage ;;
    esac
done

# ------------------------------------------------------------------------------
# main()
# ------------------------------------------------------------------------------

ARGS[confDir]="/etc/opkg"
checkCorrectUri
ARGS[uri]="${PACKAGE_FEED_URI}/${PACKAGE_FEED_BASE_PATH}"
ARGS[currentVersion]=$(lsb_release -rs)
ARGS[currentVersion]=$(echo "${ARGS[currentVersion]}" | awk -F '.' '{printf("%s.%s",$1,$2)}')
echo "${ARGS[confDir]}"
echo "${ARGS[uri]}"

versions_uri=$(curl -sL "${ARGS[uri]}" --list-only | grep -E '\[DIR\]' | awk -F '<a |</a>' '{print$2}' | awk -F '>' '{print$NF}')
versions_list=($(echo "${versions_uri}" | tr "/" "\n"))
echo "---------------------"
echo "${versions_list[@]}"
echo "${ARGS[currentVersion]}"

echo "---------------------"
for i in "${versions_list[@]}"; do
    watch_version=$(echo "${i}" | awk -F '.' '{printf("%s.%s",$1,$2)}')
    if [[ "${ARGS[currentVersion]}" < "${watch_version}" ]]; then
        echo "${watch_version}"
    fi
done
