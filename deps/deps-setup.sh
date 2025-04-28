echo 'deb https://repo.scala-sbt.org/scalasbt/debian all main' > /etc/apt/sources.list.d/sbt.list
curl -sL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x99e82a75642ac823' | apt-key add -
curl -sL 'https://downloads.lightbend.com/scala/2.12.18/scala-2.12.18.tgz' -o '/opt/scala-2.12.18.tgz'
chmod +x '/opt/scala-2.12.18.tgz'
tar -xvzf '/opt/scala-2.12.18.tgz' -C '/opt'
ln -sfn '/opt/scala-2.12.18' '/opt/scala'
export PATH='/opt/scala/bin':$PATH
curl -sL 'https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64' -o '/usr/local/bin/yq'
chmod +x '/usr/local/bin/yq'
