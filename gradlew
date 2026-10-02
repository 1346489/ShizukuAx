#!/bin/sh
APP_HOME=$(cd "$(dirname "$0")" >/dev/null && pwd)
CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar
if [ -z "$JAVA_HOME" ]; then JAVA_EXE=java; else JAVA_EXE="$JAVA_HOME/bin/java"; fi
exec "$JAVA_EXE" -Xmx64m -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
