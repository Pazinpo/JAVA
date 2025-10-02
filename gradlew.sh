#!/bin/sh
# Unix용 Gradle Wrapper 실행 스크립트
DIR=$(dirname "$0")
if [ -f "$DIR/gradlew" ]; then
    sh "$DIR/gradlew" "$@"
else
    echo "gradlew not found!"
    exit 1
fi
