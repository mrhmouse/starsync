#!/usr/bin/zsh

USER=
STARDIR=
TOTAL_NEW=0
TOTAL_UPDATED=0

main() {
    prompt-for-username
    make-star-directory
    cd "$STARDIR"
    fetch-all-stars
    restart-line
    show-summary
    cd ..
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
    curl -s "https://api.github.com/users/$USER/starred" \
         | jq -r '.[]|[.git_url, .owner.login, .name]|@tsv' \
         | while read -r URL AUTHOR NAME
    do
        clone-or-pull $URL $AUTHOR $NAME
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
        msg "Updating $NAME..."
        cd "$AUTHOR/$NAME"
        git pull --ff-only >/dev/null
        cd ../..
    else
        msg "Cloning $NAME..."
        TOTAL_NEW=$((TOTAL_NEW + 1))
        mkdir -p "$AUTHOR"
        cd "$AUTHOR"
        git clone "$URL" >/dev/null
        cd ..
    fi
    set +e
}

main
