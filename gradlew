#!/bin/sh
# Gradle Wrapper 启动脚本
set -e
PRG="$0"
while [ -h "$PRG" ]; do
  ls=$(ls -ld "$PRG"); link=$(expr "$ls" : '.*-> \(.*\)$')
  [ "$(expr "$link" : '/.*')" = 0 ] && link="$(dirname "$PRG")/$link"
  PRG="$link"
done
APP_HOME=$(cd "$(dirname "$PRG")" >/dev/null && pwd)
CLASSPATH="$APP_HOME/gradle/wrapper/gradle-wrapper.jar"
JAVA_EXE="${JAVA_HOME:-}/bin/java"
[ -z "$JAVA_EXE" ] || JAVA_EXE=java
exec "$JAVA_EXE" -Xmx128m -Xms64m -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
