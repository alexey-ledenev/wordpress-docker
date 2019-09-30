#!/usr/bin/env bash

#EXPORT CURRENT_UID=$(id -u):$(id -g)
trap 'echo "Exit"; exit 1' INT

FILES=()

##############
#FILES+=(add/extra/file.txt)
##############

while IFS=  read -r -d $'\0'; do
    FILES+=("$REPLY")
done < <(find . \
       -type f \
       -maxdepth 5 \
       -not -path "**/node_modules/*" \
       -not -path "**/bin/*" \
       -not -path "**/obj/*" \
       -not -path "**/.git/*" \
       \( -name 'package-lock.json'  -o -name '*.csproj'  -o -iname 'dockerfile' \) \
       -print0 \
       2>/dev/null)

HASH_FILE="./.rebuild.compose"
OLD_HASH=''
CURRENT_HASH=''

if [ -z "$1" ] ; then
    OLD_HASH=$(cat $HASH_FILE 2>/dev/null)
else
    echo "Force rebuid"
fi

for item in ${FILES[*]}
do
  CURRENT_HASH="$CURRENT_HASH$(sha1sum $item)"
done

if [ "$OLD_HASH" == "$CURRENT_HASH" ]; then
  echo "Regular start"
  docker-compose up
else
  docker-compose down
  echo "Build start"
  docker-compose build
  echo "$CURRENT_HASH" > $HASH_FILE
  docker-compose up
fi

