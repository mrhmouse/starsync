#!/usr/bin/zsh

PROGNAME=starsync
USER=
STARDIR=
TOTAL_NEW=0
TOTAL_UPDATED=0
CLONE=1

main() {
    parse-opts "$@"
    prompt-for-username
    make-star-directory
    cd "$STARDIR"
    fetch-all-stars
    restart-line
    show-summary
    cd ..
}

parse-opts() {
    while test $# -gt 0 ; do
        case "$1" in
            --no-clones)
                CLONE=
                ;;
            
            --user) ;&
            -u)
                USER="$2"
                shift
                ;;
            
            *) ;&
            --help) ;&
            -h)
                show-usage-and-exit
                ;;
        esac
        shift
    done
}

show-usage-and-exit() {
    echo "Usage: $PROGNAME [--no-clones] [-h|--help] [-u|--user]"
    echo '  --no-clones     Do not clone new stars'
    echo '  -h | --help     Show this help message'
    echo '  -u | --user     Set your username. If unset, you will be prompted for it'
    exit
}

show-summary() {
    echo -n "Synced $TOTAL_UPDATED repositor"
    if test 1 -eq $TOTAL_UPDATED ; then
        echo 'y'
    else
        echo -n 'ies.'
        case $TOTAL_UPDATED in
            0)
                echo
                ;;
            1)
                echo ' Of those, one was new.'
                ;;
            *)
                echo " Of those, $TOTAL_NEW were new."
                ;;
        esac
    fi
}

prompt-for-username() {
    if test -n "$USER" ; then
        return
    fi
    
    USER="$(whoami)"
    if prompt "Using $USER as your username; is this OK?" ; then
        return
    fi

    input USER "Please enter your username"
}

make-star-directory() {
    STARDIR="${USER}'s stars"
    mkdir -p "$STARDIR"
}

fetch-all-stars() {
    set -e
    local PAGE=1
    local READ=1
    while test 1 -eq $READ ; do
        READ=0
        curl -s "https://api.github.com/users/$USER/starred?page=$PAGE" \
            | jq -r '.[]|[.git_url, .owner.login, .name]|@tsv' \
            | while read -r URL AUTHOR NAME
        do
            READ=1
            clone-or-pull $URL $AUTHOR $NAME
        done

        PAGE=$((PAGE + 1))
    done
    set +e
}

prompt() {
    echo -n "$@ (y/n) "
    read -r ANSWER
    if test 0 -ne $? ; then
        prompt "$@"
        return $?
    fi

    ANSWER="${ANSWER[1]}"
    if test "$ANSWER" = y -o Y = "$ANSWER" ; then
        return 0
    elif test "$ANSWER" = n -o N = "$ANSWER" ; then
        return 1
    fi

    prompt "$@"
}

input() {
    local VAR="$1"
    shift
    echo -n "${@}: "
    read -r "$VAR"
    if test 0 -ne $? ; then
        input "$VAR" "$@"
        return
    fi
}

restart-line() {
    echo -ne '\e[G\e[K'
}

msg() {
    restart-line
    echo -n "[$@]"
}

clone-or-pull() {
    local URL="$1"
    local AUTHOR="$2"
    local NAME="$3"
    set -e
    TOTAL_UPDATED=$((TOTAL_UPDATED + 1))
    if test -d "$AUTHOR/$NAME" ; then
        msg "Updating $AUTHOR/$NAME..."
        cd "$AUTHOR/$NAME"
        git pull --ff-only -q
        cd ../..
    elif test -n "$CLONE" ; then
        msg "Cloning $AUTHOR/$NAME..."
        TOTAL_NEW=$((TOTAL_NEW + 1))
        mkdir -p "$AUTHOR"
        cd "$AUTHOR"
        git clone -q "$URL"
        cd ..
    fi
    set +e
}

PROGNAME="$(basename "$0")"
main "$@"
