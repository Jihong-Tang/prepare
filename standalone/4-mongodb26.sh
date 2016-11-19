#!/usr/bin/env bash

mkdir -p $HOME/share/

echo "====> Install MongoDB <===="

mkdir -p $HOME/share/mongodb

if [[ `uname` == 'Darwin' ]];
then
    echo "==> download"
    cd /prepare/resource/
    wget -N https://fastdl.mongodb.org/osx/mongodb-osx-x86_64-2.6.11.tgz

    echo "==> untar"
    cd $HOME/share/
    tar xvfz /prepare/resource/mongodb-osx*-2.*.tgz
    cp -R -n mongodb-osx*/ mongodb

    rm -fr mongodb-osx*/
else
    echo "==> download"
    cd /prepare/resource/
    wget -N https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1404-2.6.11.tgz

    echo "==> untar"
    cd $HOME/share/
    tar xvfz /prepare/resource/mongodb-linux*-2.*.tgz
    cp -R -n mongodb-linux*/ mongodb

    rm -fr mongodb-linux*/
fi

mkdir -p $HOME/share/mongodb/log
mkdir -p $HOME/share/mongodb/data

echo "==> cnf file"
cat <<EOF > $HOME/share/mongodb/mongod.cnf
systemLog:
    destination: file
    path: $HOME/share/mongodb/log/mongod.log
    logAppend: true
storage:
    dbPath: $HOME/share/mongodb/data
    directoryPerDB: true
    journal:
        enabled: false
net:
    bindIp: 127.0.0.1
    port: 27017
    http:
        enabled: true
        RESTInterfaceEnabled: true

EOF

if grep -q -i mongodbbin $HOME/.bashrc; then
    echo "==> .bashrc already contains mongodbbin"
else
    echo "==> Update .bashrc"

    LB_PATH='export PATH="$HOME/share/mongodb/bin:$PATH"'
    echo '# mongodbbin' >> $HOME/.bashrc
    echo $LB_PATH >> $HOME/.bashrc
    echo >> $HOME/.bashrc

    eval $LB_PATH
fi

echo "==> done"

if [[ `uname` == 'Darwin' ]];
then
cat <<EOF > $HOME/Library/LaunchAgents/org.mongodb.mongod.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>org.mongodb.mongod</string>
  <key>ProgramArguments</key>
  <array>
    <string>$HOME/share/mongodb/bin/mongod</string>
    <string>--config</string>
    <string>$HOME/share/mongodb/mongod.cnf</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <false/>
  <key>WorkingDirectory</key>
  <string>$HOME/share/mongodb</string>
  <key>StandardErrorPath</key>
  <string>$HOME/share/mongodb/output.log</string>
  <key>StandardOutPath</key>
  <string>$HOME/share/mongodb/output.log</string>
  <key>HardResourceLimits</key>
  <dict>
    <key>NumberOfFiles</key>
    <integer>4096</integer>
  </dict>
  <key>SoftResourceLimits</key>
  <dict>
    <key>NumberOfFiles</key>
    <integer>4096</integer>
  </dict>
</dict>
</plist>

EOF
fi

cat <<EOF

# Start mongodb by running

numactl --interleave=all ~/share/mongodb/bin/mongod --config ~/share/mongodb/mongod.cnf

OR

launchctl load ~/Library/LaunchAgents/org.mongodb.mongod.plist

EOF
