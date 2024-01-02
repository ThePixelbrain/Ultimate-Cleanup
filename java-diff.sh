#!/bin/bash

if ! [ "$#" -eq 2 ]; then
    echo "Invalid args! Usage: java-diff.sh <Jar1> <Jar2>"
    exit 0
fi

jar1=$(basename -- $1)
jar2=$(basename -- $2)

decompFolder1=/tmp/$jar1-decomp1
decompFolder2=/tmp/$jar2-decomp2

echo "Decompiling $1"
jd-cli "$1" -od "$decompFolder1"

echo "Decompiling $2"
jd-cli "$2" -od "$decompFolder2"

echo "Generate diff between jars"
diff -r "$decompFolder1" "$decompFolder2" > "$jar1-$jar2.diff"

echo "Success!"