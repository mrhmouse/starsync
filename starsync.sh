#!/usr/bin/zsh

USER=
STARDIR=

main() {
    prompt-for-username
    make-star-directory
    cd "$STARDIR"
    fetch-all-stars
    cd ..
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
    curl "https://api.github.com/users/$USER/starred" \
         | jq -r '.[]|[.git_url, .owner.login, .name]|@tsv' \
         | while read -r URL AUTHOR NAME
    do
        clone-or-pull $URL $AUTHOR $NAME
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

msg() {
    echo "[$@]"
}

clone-or-pull() {
    local URL="$1"
    local AUTHOR="$2"
    local NAME="$3"
    if test -d "$AUTHOR/$NAME" ; then
        msg "Updating $NAME..."
        cd "$AUTHOR/$NAME"
        git pull --ff-only
        cd ../..
    else
        msg "Cloning $NAME..."
        mkdir -p "$AUTHOR"
        cd "$AUTHOR"
        git clone "$URL"
        cd ..
    fi
}

main
