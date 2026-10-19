#!/bin/bash -e

# usage
# curl -sSL https://raw.githubusercontent.com/YeicoCom/yeico_flex/refs/heads/main/flex3.sh | sh
# ./flex3.sh install # installs cached version from ./flex3 or main
# ./flex3.sh update  # installs main and caches it to ./flex3
# add deps to .gitignore

q() { 
    echo $@
    "$@" &>/dev/null
}

checkout() {
    echo Getting flex $3
    [ -d $1 ] && q git -C $1 clean -fdx 
    [ -d $1 ] && q git -C $1 fetch --force --all --prune --tags
    [ -d $1 ] && q git -C $1 reset --hard origin/main
    [ -d $1 ] || q git -C deps clone $2
    q git -C $1 checkout $3 || true
    git -C $1 rev-parse HEAD > ./.flex3
    echo Using flex $(cat ./.flex3)
}

setup() {
    q mkdir -p deps
    checkout deps/yeico_flex git@github.com:YeicoCom/yeico_flex.git $1
    for route in applets/*.exs; do
        applet=$(basename ${route%.*})
        q rsync -avr --delete deps/yeico_flex/applets/flex3 applets/$applet/
        q mkdir -p applets/$applet/css/
        q mkdir -p applets/$applet/js/
        q mkdir -p applets/$applet/static/
        q cp -f applets/$applet/flex3/css/* applets/$applet/css/
        q cp -f applets/$applet/flex3/js/* applets/$applet/js/
        q cp -f applets/$applet/flex3/static/sw.js applets/$applet/static/
        q cp -f applets/$applet/flex3/code.exs applets/$applet/
        q cp -f applets/$applet/flex3/make.exs applets/$applet/
        q cp -f applets/$applet/flex3/package.json applets/$applet/
        q cp -f applets/$applet/flex3/tailwind.config.js applets/$applet/
    done
    q cp -f deps/yeico_flex/flex3.sh .
    q chmod a+x flex3.sh
}

update() {
    setup main
}

install() {
    commit=$(cat ./.flex3 2>/dev/null || echo main)
    setup $commit
}

${1:-install}
