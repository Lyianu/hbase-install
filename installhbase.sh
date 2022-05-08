#!/bin/sh
#ast itbitw.com
DOWNLOAD_LINK="https://dlcdn.apache.org/hbase/2.4.12/hbase-2.4.12-bin.tar.gz"

#prompt
echo "Install HBase?(y/N)"
read USER_INPUT
case $USER_INPUT in 
	y)
		echo "Starting to install HBase..."
		;;
	Y)
		echo "Starting to install HBase..."
		;;
	*)
		echo "Exiting..."
		exit 1
		;;
esac

#set $PATH
set_path()
{
	cat <<EOF | sudo tee /etc/profile.d/hadoop_java.sh
	export JAVA_HOME=\$(dirname \$(dirname \$(readlink \$(readlink \$(which javac)))))
	export HADOOP_HOME=/usr/local/hadoop
	export HADOOP_HDFS_HOME=\$HADOOP_HOME
	export HADOOP_MAPRED_HOME=\$HADOOP_HOME
	export YARN_HOME=\$HADOOP_HOME
	export HADOOP_COMMON_HOME=\$HADOOP_HOME
	export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
	export HBASE_HOME=/usr/local/HBase
	export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$HBASE_HOME/bin
EOF

	source /etc/profile.d/hadoop_java.sh
}

#check distro
cat /proc/version | grep "Ubuntu" > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Only support Ubuntu!"
	exit 1
fi

sudo apt update

#check root
#[ $EUID -eq 0 ] || echo "Please login as root."

#check java installation, install openjdk if needed
sudo apt list --installed | grep java > /dev/null 2>&1
if [ $? -eq 1 ]; then
	echo "Java not found, installing openjdk17"
	sudo apt install openjdk-17-jdk
fi

if [ $? -ne 0 ]; then
	echo "Failed to install openjdk"
	exit 1
fi

#Update $PATH values
set_path

#download hbash binary
echo "Downloading hbase binary..."
curl -o hbase.tar.gz $DOWNLOAD_LINK
#check result
if [ $? -eq 0 ]; then
	echo "Download completed."
	else
		echo "Download failed, check internet connection. exiting..."
		exit 1
fi

#extract bin file
mkdir /usr/local/HBase
tar -zxvf hbase.tar.gz
sudo mv hbase-2.4.12/ /usr/local/HBase
rm hbase.tar.gz
rm -rf hbase-2.4.12

#configure hbase-env.sh
sed -i 's+# export JAVA_HOME=/usr/java/jdk1.8.0/+export JAVA_HOME=${JAVA_HOME}+g' /usr/local/HBase/conf/hbase-env.sh
sed -i 's+# export HBASE_MANAGES_ZK=true+export HBASE_MANAGES_ZK=true+g' /usr/local/HBase/conf/hbase-env.sh

#configure hbase-site.xml
sed -z -i 's+<name>hbase.cluster.distributed</name>\n    <value>false</value>\n  </property>+<name>hbase.cluster.distributed</name>\n    <value>false</value>\n  </property>\n  <property>\n    <name>hbase.rootdir</name>\n    <value>file:/hadoop/HBase/HFiles</value>\n  </property>\n  <property>\n    <name>hbase.zookeeper.property.dataDir</name>\n    <value>/hadoop/zookeeper</value>\n    </property>+g' /usr/local/HBase/conf/hbase-site.xml

#start hbase
#/usr/local/HBase/bin/start-all.sh
/usr/local/HBase/bin/start-hbase.sh
jps

#finalize
echo "Successfully installed Apache HBase"
echo -en "use "
echo -en "\033[0;31m./hbase shell\033[0m"
echo -e " in \033[0;31m/usr/local/HBase/bin\033[0m to access hbase shell"
echo -e "HBase location: \033[0;31m/usr/local/HBase/\033[0m"
echo "installation complete, thank you for using this script."
exit 0
