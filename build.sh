set -e
unzip -q AudioMerger.zip
sed -i 's/extractSevenZipSafely(File archiveFile, File destination)/extractSevenZipSafely(File archiveFile, final File destination)/' AudioMerger/android/app/src/main/java/com/axelzerox23/portyou/MainActivity.java
cat >> AudioMerger/android/app/build.gradle <<'EOF'
configurations.all {
  exclude group: 'androidx.appcompat'
  exclude group: 'androidx.core'
  exclude group: 'androidx.fragment'
  exclude group: 'androidx.activity'
  exclude group: 'androidx.lifecycle'
}
EOF
cat > AudioMerger/android/local.properties <<EOF
sdk.dir=$ANDROID_HOME
ndk.dir=$ANDROID_HOME/ndk/20.0.5594570
EOF
sudo chown -R $USER $ANDROID_HOME
SDKM=$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager
cat > pkgs.txt <<EOF
platform-tools
platforms;android-28
build-tools;28.0.3
cmake;3.10.2.4988404
ndk;20.0.5594570
EOF
yes | JAVA_HOME=$JAVA_HOME_17_X64 $SDKM --licenses > /dev/null || true
JAVA_HOME=$JAVA_HOME_17_X64 $SDKM --package_file=pkgs.txt
cd $ANDROID_HOME
find platforms -mindepth 1 -maxdepth 1 ! -name android-28 -exec rm -rf {} +
find build-tools -mindepth 1 -maxdepth 1 ! -name 28.0.3 -exec rm -rf {} +
find ndk -mindepth 1 -maxdepth 1 ! -name 20.0.5594570 -exec rm -rf {} +
find cmake -mindepth 1 -maxdepth 1 ! -name 3.10.2.4988404 -exec rm -rf {} +
rm -rf ndk-bundle sources add-ons extras
cd $GITHUB_WORKSPACE/AudioMerger
curl -sSL -o $HOME/g.zip https://services.gradle.org/distributions/gradle-4.6-bin.zip
unzip -q $HOME/g.zip -d $HOME/g
sh scripts/fetch-native-deps.sh
sh scripts/fetch-codecs.sh
$HOME/g/gradle-4.6/bin/gradle -p android --no-daemon --stacktrace assembleDebug > build.log 2>&1 || {
  echo === WHAT WENT WRONG ===
  grep -n -A12 'What went wrong' build.log | head -40
  echo === C++ ERRORS ===
  grep -n -e 'error:' -e 'fatal error' -e 'undefined reference' -e 'ninja:' build.log | head -25
  exit 1
}
echo BUILD DONE
