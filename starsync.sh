#!/usr/bin/zsh

PROGNAME=starsync
USER=
STARDIR=
TOTAL_NEW=0
TOTAL_UPDATED=0
CLONE=1
SHALLOW=
MAX_REPO_SIZE_KB=$((1024 * 50))

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

            --shallow) ;&
            -s)
                SHALLOW=1
                ;;

            --max-repo-size) ;&
            -m)
                MAX_REPO_SIZE_KB="$2"
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
    echo "Usage: $PROGNAME [options]"
    echo 'Options:'
    echo '  --no-clones           Do not clone new stars'
    echo '  -h | --help           Show this help message'
    echo '  -u | --user           Set your username. If unset, you will be prompted for it'
    echo '  -s | --shallow        Perform a shallow clone of new repositories'
    echo '  -m | --max-repo-size  Set the maximum allowable repository size, in kilobytes.'
    echo '                        Repositories over this limit will not be cloned.'
    echo '                        Defaults to 50 megabytes'
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
    local PAGE=1
    local READ=1
    while test 1 -eq $READ ; do
        READ=0
        curl -s "https://api.github.com/users/$USER/starred?page=$PAGE" \
            | jq -r '.[]|[.git_url, .owner.login, .name, .size]|@tsv' \
            | while read -r URL AUTHOR NAME SIZE
        do
            READ=1
            clone-or-pull $URL $AUTHOR $NAME $SIZE
        done

        PAGE=$((PAGE + 1))
    done
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
    local SIZE="$4"
    
    if test $SIZE -ge $MAX_REPO_SIZE_KB ; then
        msg "Skipping $AUTHOR/$NAME..."
        return
    fi
    
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
        if test -n "$SHALLOW" ; then
            git clone -q "$URL" --depth 1
        else
            git clone -q "$URL"
        fi
        cd ..
    fi
}

PROGNAME="$(basename "$0")"
main "$@"
