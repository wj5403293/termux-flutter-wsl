#!/data/data/com.termux/files/usr/bin/bash
export JAVA_HOME=/data/data/com.termux/files/usr
export ANDROID_HOME=/data/data/com.termux/files/usr/opt/android-sdk
export PATH=$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH
echo "JAVA_HOME=$JAVA_HOME"
echo "ANDROID_HOME=$ANDROID_HOME"
java --version
cd ~/testapp
flutter build apk --debug
