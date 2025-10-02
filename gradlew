#!/bin/sh

# Gradle Wrapper

GRADLE_VERSION=8.5

if [ ! -f gradle/wrapper/gradle-wrapper.jar ]; then
  echo "gradle-wrapper.jar not found. Please add it manually or regenerate wrapper."
  exit 1
fi

java -jar gradle/wrapper/gradle-wrapper.jar "$@"
