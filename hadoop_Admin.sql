`HDFS SETUP AND Installation`
----------------------------
[hduser@master vmware-tools-distrib]$ ifconfig -a
eth1      Link encap:Ethernet  HWaddr 00:50:56:2C:BA:6C  
          inet addr:192.168.1.10  Bcast:192.168.1.255  Mask:255.255.255.0
          inet6 addr: fe80::250:56ff:fe2c:ba6c/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:520 errors:0 dropped:0 overruns:0 frame:0
          TX packets:28 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:31727 (30.9 KiB)  TX bytes:2136 (2.0 KiB)

[hduser@master vmware-tools-distrib]$ cat /etc/sysconfig/network
NETWORKING=yes
HOSTNAME=master
NTPSERVERARGS=iburst
GATEWAY=192.168.222.10
[hduser@master vmware-tools-distrib]$ cat /etc/sysconfig/network-scripts/ifcfg-eth0 
DEVICE=eth1
TYPE=Ethernet
BOOTPROTO=static
IPADDR=192.168.1.10
NETMAASK=255.255.255.0

Mapping the nodes: on all nodes

sudo vi /etc/hosts
192.168.1.11 master
192.168.1.12 dn1
192.168.1.13 dn2
192.168.1.5 base

To set the ipaddress of the nodes (in VM the ipaddress often changing)
sudo ifconfig eth1 192.168.222.129 netmask 255.255.255.0

Set passwordless SSH setup between servers:

ssh-keygen -t rsa 

cat .ssh/id_rsa.pub | ssh hduser@master 'cat >> .ssh/authorized_keys'
ssh hduser@master "chmod 700 .ssh; chmod 640 .ssh/authorized_keys"

cat .ssh/id_rsa.pub | ssh hduser@dn2 'cat >> .ssh/authorized_keys'
ssh hduser@dn2 "chmod 700 .ssh; chmod 640 .ssh/authorized_keys"

cat .ssh/id_rsa.pub | ssh hduser@dn1 'cat >> .ssh/authorized_keys'
ssh hduser@dn1 "chmod 700 .ssh; chmod 640 .ssh/authorized_keys"

sudo groupadd hadoop
sudo usermod -g hadoop hduser

Installing Java:

Download java (JDK -> jdk-8u181-linux-x64.tar.gz) by visiting the following link http://www.oracle.com/technetwork/java/javase/downloads/
place the tar file in /usr/lib/jvm
extract with -> sudo tar -zxf jdk-8u181-linux-x64.tar.gz
cd jdk1.8.0_181

sudo  alternatives --install /usr/bin/java java /usr/lib/jvm/jdk1.8.0_181/bin/java 2
sudo alternatives --config java
java -version

Configure JAVA_HOME in ‘hadoop-env.sh’:

sudo vi /usr/local/hadoop/etc/hadoop/hadoop-env.sh
export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_181

Download and Unpack Hadoop Binaries:
Untar the complete hadoop-2.7.1 package

cd /home/hduser/install/
tar xvzf hadoop-2.7.1.tar.gz
sudo mv hadoop-2.7.1 /usr/local/hadoop
sudo chown -R hduser:hadoop /usr/local/hadoop

sudo ln -s hadoop-2.7.1 hadoop
sudo chown -R hduser:hadoop hadoop


stop firewall:  on both master and slaves
sudo service iptables save
sudo service iptables stop
sudo service iptables status

Update the Configuration Files:

vi .bashrc

# Set Hadoop-related environment variables
export HADOOP_PREFIX=/usr/local/hadoop
export HADOOP_HOME=/usr/local/hadoop
export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
export HADOOP_MAPRED_HOME=/usr/local/hadoop
export HADOOP_COMMON_HOME=/usr/local/hadoop
export HADOOP_HDFS_HOME=/usr/local/hadoop
export YARN_HOME=/usr/local/hadoop

# Native Path
export HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_PREFIX}/lib/native
export HADOOP_OPTS="-Djava.library.path=$HADOOP_PREFIX/lib"

#Java Path
export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_181
export JRE_HOME=/usr/lib/jvm/jdk1.8.0_181/jre
export PATH=$PATH:${JAVA_HOME}/bin:${JRE_HOME}/bin

# Add Hadoop bin/ directory to PATH
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

Create NameNode and DataNode directory:

sudo mkdir -p /usr/local/hadoop_store/tmp
sudo mkdir -p /usr/local/hadoop_store/hdfs/namenode
sudo mkdir -p /usr/local/hadoop_store/hdfs/datanode
sudo mkdir -p /usr/local/hadoop_store/hdfs/secondarynamenode
sudo chown -R hduser:hadoop /usr/local/hadoop_store

sudo chmod -R  777 /usr/local/hadoop_store/

Configure the Default File system:

sudo vi /usr/local/hadoop/etc/hadoop/core-site.xml (Master+Slave nodes)

<configuration>
<property>
<name>hadoop.tmp.dir</name>
<value>/usr/local/hadoop_store/tmp</value>
<description>A base for other temporary directories.</description>
</property>
<property>
<name>fs.default.name</name>
<value>hdfs://master:54310</value>
<description>
The name of the default file system. A URI whose scheme and authority determine the FileSystem
implementation. The uris scheme determines the config property fs.SCHEME.impl) naming the
FileSystem implementation class. The uris authority is used to determine the host, port, etc. for a
filesystem.
</description>
</property>
</configuration>

Configure the HDFS::

sudo vi /usr/local/hadoop/etc/hadoop/hdfs-site.xml (Namenode on Master and datanode setting only on slave machines)

<configuration>
<property>
<name>dfs.replication</name>
<value>2</value>
<description>Default block replication.
The actual number of replications can be specified when the file is created.
The default is used if replication is not specified in create time.
</description>
</property>
<property>
<name>dfs.namenode.name.dir</name>
<value>file:/usr/local/hadoop_store/hdfs/namenode</value>
</property>
<property>
<name>dfs.datanode.data.dir</name>
<value>file:/usr/local/hadoop_store/hdfs/datanode</value>
</property>
<property>
<name>dfs.namenode.checkpoint.dir</name>
<value>file:/usr/local/hadoop_store/hdfs/secondarynamenode</value>
</property>
<property>
<name>dfs.namenode.checkpoint.period</name>
<value>3600</value>
</property>
</configuration>

Configure YARN framework:

sudo vi /usr/local/hadoop/etc/hadoop/yarn-site.xml (All Master and Slave nodes)

<configuration>
<!-- Site specific YARN configuration properties -->
<property>
 <name>yarn.nodemanager.aux-services</name>
 <value>mapreduce_shuffle</value>
</property>
<property>
<name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
<value>org.apache.hadoop.mapred.ShuffleHandler</value>
</property>
<property>
 <name>yarn.resourcemanager.scheduler.address</name>
 <value>master:8030</value>
</property> 
<property>
 <name>yarn.resourcemanager.address</name>
 <value>master:8032</value>
</property>
<property>
  <name>yarn.resourcemanager.webapp.address</name>
  <value>master:8088</value>
</property>
<property>
  <name>yarn.resourcemanager.resource-tracker.address</name>
  <value>master:8031</value>
</property>
<property>
  <name>yarn.resourcemanager.admin.address</name>
  <value>master:8033</value>
</property>

Configure MapReduce framework:

cp /usr/local/hadoop/etc/hadoop/mapred-site.xml.template /usr/local/hadoop/etc/hadoop/mapred-site.xml

sudo vi /usr/local/hadoop/etc/hadoop/mapred-site.xml

<configuration>
<property>
<name>mapreduce.framework.name</name>
<value>yarn</value>
</property>
</configuration>

<property>
  <name>mapreduce.jobhistory.address</name>
  <value>192.168.1.11:10020</value>
  <description>Host and port for Job History Server (default 0.0.0.0:10020)</description>
</property>

Run only in master
------------------
sudo vi /usr/local/hadoop/etc/hadoop/slaves (edit on both master and slaves)
dn1
dn2
sudo vi /usr/local/hadoop/etc/hadoop/masters (edit only in master)
master

The first step in starting up your Hadoop installation is formatting the Hadoop file-system:
(At master)

hdfs namenode -format


start-all.sh
OR
To start the Daemons separately HDFS and YARN (Useful when hdfs and yarn daemons installed separately)
start-yarn.sh (Resource Manager and Node manager)
start-dfs.sh (namenode, datanode and secondarynamenode)
OR
To start the Daemons individually ( Useful in multinode cluster setup)
hadoop-daemons.sh start secondarynamenode
hadoop-daemons.sh start namenode
hadoop-daemons.sh start datanode
yarn-daemon.sh start nodemanager
yarn-daemon.sh start resourcemanager
mr-jobhistory-daemon.sh start historyserver

`SQOOP Installation`
--------------------
================================================================

1. Discover the exact DB2 Version (and FixPack Level):
https://www-01.ibm.com/support/docview.wss?uid=swg21642926

2. Download the proper IBM DB2 JDBC Driver for the DB2 version/FP level gathered on Step #1
https://www-01.ibm.com/support/docview.wss?uid=swg27007053

3. Determine the port number of DB2 database instance:
https://www-01.ibm.com/support/docview.wss?uid=swg21343520

4. Copy the downloaded DB2 JDBC JAR file to Sqoop-client library directory:
/usr/hdp/current/sqoop-client/lib

5. Test connection with the following Sqoop syntax (example provided using default port number and doing a list database command):
sqoop list-databases --connect jdbc:db2://<FQDN of DB2 Host>:50000/SAMPLE --username <userid> --password <password>
$sqoop import --driver com.ibm.db2.jcc.DB2Driver --connect jdbc:db2://master:50000 --username mling --password Sanjeevin@1 --table db2tbl --split-by tbl_primarykey --target-dir sqoopimports

This article created by Hortonworks Support (Article: 000004491) on 2016-06-23 12:25
OS: Linux
Type: Configuration
Version: 2.3.0, 2.3.4, 2.4.0

------------
cd ~/install
tar xvzf sqoop-1.4.6.bin__hadoop-2.0.4-alpha.tar.gz
sudo mv sqoop-1.4.6.bin__hadoop-2.0.4-alpha /usr/local/sqoop

export SQOOP_HOME=/usr/local/sqoop
export PATH=$PATH:$SQOOP_HOME/bin

cd $SQOOP_HOME/conf
mv sqoop-env-template.sh sqoop-env.sh
echo 'export HADOOP_COMMON_HOME=/usr/local/hadoop' >> $SQOOP_HOME/conf/sqoop-env.sh
echo 'export HADOOP_MAPRED_HOME=/usr/local/hadoop' >> $SQOOP_HOME/conf/sqoop-env.sh

==============================================================================
`HIVE Installation`:
Refer https://data-flair.training/blogs/apache-hive-metastore/ --> for hive set up
    https://cwiki.apache.org/confluence/display/Hive/AdminManual+MetastoreAdmin#AdminManualMetastoreAdmin-Local/EmbeddedMetastoreDatabase(Derby)

cd /home/hduser/install/
tar xvzf apache-hive-0.14.0-bin.tar.gz
sudo mv apache-hive-0.14.0-bin /usr/local/hive

hadoop fs -mkdir -p /user/hive/warehouse/
hadoop fs -chmod g+w /user/hive/warehouse
hadoop fs -chmod g+w /tmp

echo 'export HADOOP_HOME=/usr/local/hadoop' >> /usr/local/hive/bin/hive-config.sh

cp /usr/local/hive/conf/hive-env.sh.template /usr/local/hive/conf/hive-env.sh
echo 'export HADOOP_HOME=/usr/local/hadoop' >> /usr/local/hive/conf/hive-env.sh

export HADOOP_HOME=/home/hduser/hadoop-2.6.5
export HIVE_HOME=/usr/local/hive
export PATH=$PATH:$HIVE_HOME/bin
export CLASSPATH=$CLASSPATH:/usr/local/hadoop/lib/*:.
export CLASSPATH=$CLASSPATH:/usr/local/hive/lib/*:.
*/
Install mysql - place mysql jdbc connector and place in /usr/local/hive/lib

cd /usr/local/hive/conf
mv hive-default.xml.template hive-site.xml

Make below changes in hive-site.xml

sudo vi /usr/local/hive/conf/hive-site.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?> 
<configuration>
<!-- -
<property> 
  <name>hive.metastore.uris</name> 
  <value>thrift://192.168.1.7:9083</value>
  <description>IP address (or fully-qualified domain name) and port of the metastore host</description>
</property> 
<!- -->
<property>
  <name>javax.jdo.option.ConnectionURL</name>
  <value>jdbc:mysql://192.168.1.7:3306/metastore?createDatabaseIfNotExist=true&amp;useSSL=false</value>
  <description>the URL of the MySQL database</description>
</property>
<property>
  <name>javax.jdo.option.ConnectionDriverName</name>
  <value>com.mysql.cj.jdbc.Driver</value>
</property>
<property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/hive/warehouse</value>
    <description>location of default database for the warehouse</description>
 </property>
<property>
  <name>javax.jdo.option.ConnectionUserName</name>
  <value>hive</value>
</property>
<property>
  <name>javax.jdo.option.ConnectionPassword</name>
  <value>hive</value>
</property>
<!-- -
<property>
  <name>hive.stats.dbclass</name>
  <value>jdbc:mysql</value>
<description>The default database that stores temporary hive statistics.</description>
</property>
<property>
  <name>hive.stats.jdbcdriver</name>
  <value>com.mysql.cj.jdbc.Driver</value>
<description>The JDBC driver for the database that stores temporary hive statistics.</description> </property>
<property>
  <name>hive.stats.dbconnectionstring</name>
  <value>jdbc:mysql://192.168.1.7:3306/metastore</value>
  <description>The defaultconnection string for the database that stores temporary hive statistics.</description>
</property>

<property>
  <name>datanucleus.autoCreateSchema</name>
  <value>false</value>
</property>
<property>
  <name>datanucleus.fixedDatastore</name>
  <value>true</value>
</property>
<property>
  <name>datanucleus.autoCreateTables</name>
  <value>True</value>
 </property>
 <property>
   <name>datanucleus.autoStartMechanism</name>
   <value>SchemaTable</value>
 </property>
<!- -->

"before starting the hive session - Run in mysql session"
  create database metastore;
  USE metastore;
  SOURCE /usr/local/hive/scripts/metastore/upgrade/mysql/hive-schema-0.14.0.mysql.sql;  <<---- Creates the schema for hive metastore
  show tables;
  CREATE USER 'hiveuser'@'%' IDENTIFIED BY 'hivepassword';
  GRANT all on *.* to 'hiveuser'@localhost identified by 'hivepassword';
  flush privileges;
  quit;

  or 
  create database metastore; in mysql
  USE metastore;
  CREATE USER 'hiveuser'@'ipaddress' IDENTIFIED BY 'hivepassword';
  GRANT all on *.* to 'hiveuser'@localhost identified by 'hivepassword';
  flush privileges;
  $HIVE_HOME/bin/schematool -initSchema -dbType mysql (run in new shell)   <<---- Creates the schema for hive metastore  

hive --service metastore

hive -hiveconf hive.root.logger=DEBUG,console

set hive.cli.print.header=true; 

===================================================
`SPARK Installation`:


'Installation':
  Download tar file http://mirrors.wuchna.com/apachemirror/spark/spark-2.3.2/spark-2.3.2-bin-hadoop2.7.tgz
    tar -xf spark-2.3.2-bin-hadoop2.7.tgz
    sudo mv  spark-2.3.2-bin-hadoop2.7 /usr/local/spark
    ls -ld /usr/local/spark
    vi ~/.bashrc --> add following lines
  Scala Path
    export SPARK_HOME=/usr/local/scala
    export PATH=$PATH:$SPARK_HOME/bin
    
  Spark Master Configuration:
    cd /usr/local/spark/conf
    cp spark-env.sh.template spark-env.sh
    
  vi /usr/local/spark/conf/spark-env.sh --> add following lines
    export SPARK_MASTER_HOST=master
    export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_181
  
  vi /usr/local/hadoop/etc/hadoop/yarn-site.xml
    <property>
     <name>yarn.nodemanager.vmem-check-enabled</name>
     <value>false</value>
     <description>Whether virtual memory limits will be enforced for containers</description>
    </property>
    <property>
     <name>yarn.nodemanager.vmem-pmem-ratio</name>
     <value>4</value>
     <description>Ratio between virtual memory to physical memory for containers</description>
    </property> 


  hadoop fs -put /usr/local/spark/jars/* /user/spark/share/lib/     -- */

  spark.yarn.memory=256m
  spark.driver.memory=25m
  spark.driver.cores=1
  spark.executor.cores=1
  spark.executor.memory=256m
  spark.yarn.jars=hdfs://master:54310/user/spark/share/lib/*.jar      ---- */


-----------------------------------------------------------

  'Error while starting spark-shell':
  ERROR TransportClient:233 - Failed to send RPC
  refer --> https://issues.apache.org/jira/browse/YARN-4714 
  'Solution':
    spark-shell --master yarn --conf "spark.executor.extraJavaOptions = -XX:ReservedCodeCacheSize=100M -XX:MaxMetaspaceSize=256m -XX:CompressedClassSpaceSize=256m" driver-memory 512m --num-executors 1 --executor-cores 2 --executor-memory 512m --conf "spark.yarn.jars=hdfs://master:54310/user/spark/share/lib/*.jar" --conf "spark.yarn.maxAppAttempts=1"


=============================


=============================================================================
`PIG`:

for Loading and Storing Hive Data into Pig --> https://acadgild.com/blog/loading-and-storing-hive-data-into-pig

export HCAT_HOME=/usr/local/hive/hcatalog



'Errors and Solution:'
MR job fails with below exception: 
java.net.ConnectException: Call From master/192.168.1.11 to 0.0.0.0:10020 failed on connection exception: java.net.ConnectException: Connection refused;

10020 is a port for jobHistory server, so check the port is in listen state ->
  sudo netstat -lpten |  grep -i listen
also make an entry in mapred-site.xml for the property 'mapreduce.jobhistory.address'

=============================================================================

=============================================================================
`Zookeeper`

  Read --> https://unskilledcoder.github.io/hadoop/hbase/2016/12/11/hbase-cluster-setup-with-zookeeper.html
'Installation'
  tar xzf zookeeper-3.4.6.tar.gz
  sudo mv zookeeper-3.4.6 /usr/local/zookeeper
  sudo chown -R hduser:hadoop /usr/local/zookeeper

  vi ~/.bashrc
  export ZK_HOME=/usr/local/zookeeper
  export PATH=$PATH:$ZK_HOME/bin

  cp $ZK_HOME/conf/zoo_sample.cfg $ZK_HOME/conf/zoo.cfg; vi $ZK_HOME/conf/zoo.cfg
  dataDir=/usr/local/zookeeper/data
  server.1=master:2888:3888
  server.2=dn1:2888:3888
  server.3=dn2:2888:3888

  in dn1 -> sudo mkdir /usr/local/zookeeper; sudo chown -R hduser:hadoop /usr/local/zookeeper
  in dn2 -> sudo mkdir /usr/local/zookeeper; sudo chown -R hduser:hadoop /usr/local/zookeeper

  scp -r /usr/local/zookeeper/\* hduser@dn1:/usr/local/zookeeper
  scp -r /usr/local/zookeeper/\* hduser@dn2:/usr/local/zookeeper

  if you have two servers (SERVER1 and SERVER2) for which you have created "myid" files in dataDir for zookeeper as below

  SERVER1 (myid)
  1

  SERVER2 (myid)
  2

  ssh master mkdir $ZK_HOME/data
  ssh dn1 mkdir $ZK_HOME/data
  ssh dn2 mkdir $ZK_HOME/data

  lsof -i -P | grep 2181
  sudo netstat -nlpo | grep :2181 

  ${HBASE_HOME}/bin/hbase-daemons.sh {start,stop} zookeeper

  cd /usr/local/zookeeper/bin/; ./zkServer.sh stop
  cd /usr/local/zookeeper/bin/; ./zkServer.sh start

  sudo /etc/init.d/hbase-master restart
  sudo /etc/init.d/hbase-regionserver restart
  sudo /etc/init.d/zookeeper-server status

=============================================================================
`HBASE`
'Installation'
  tar xzf hbase-0.98.4-hadoop2-bin.tar.gz
  sudo mv hbase-0.98.4-hadoop2 /usr/local/hbase
  sudo chown -R hduser:hadoop /usr/local/hbase

  cd /usr/local/hbase/conf
  echo "export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_181" >> hbase-env.sh
  echo "export HBASE_MANAGES_ZK=false" >> hbase-env.sh

  vi ~/.bashrc
  export HBASE_HOME=/usr/local/hbase
  export PATH=$PATH:$HBASE_HOME/bin
  export HBASE_MANAGES_ZK=false

  hadoop fs -mkdir /user/hduser/hbase

  vi /usr/local/hbase/conf/hbase-site.xml
  <configuration>
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://master:54310/user/hduser/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>/usr/local/zookeeper/data</value>
  </property>
  <property>
      <name>hbase.master</name>
      <value>master:60000</value>
  </property>
  <property>
      <name>hbase.master.port</name>
      <value>60000</value>
      <description>The port master should bind to.</description>
  </property>
  <!-- zookeeper cluster we setup in previous post -->
  <property>
      <name>hbase.zookeeper.quorum</name>
      <value>master,dn1,dn2</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.clientPort</name>
    <value>2181</value>
  </property>
  <!-- 2 since we have 2 slaves for data -->
  <property>
      <name>dfs.replication</name>
      <value>2</value>
  </property>
  </configuration>

  . ~/.bashrc
  Write correct region server hostnames into $HBASE_HOME/conf/regionservers
  echo dn1 > $HBASE_HOME/conf/regionservers
  echo dn2 >> $HBASE_HOME/conf/regionservers

  Copy the environment variables and HBase config to other nodes
  scp -r ~/.bashrc hduser@dn1:/home/hduser
  scp -r ~/.bashrc hduser@dn2:/home/hduser

  sudo mkdir /usr/local/hbase/  && sudo chown -R hduser:hadoop /usr/local/hbase --> in dn1 and dn2

  scp -r /usr/local/hbase/\* hduser@dn1:/usr/local/hbase
  scp -r /usr/local/hbase/\* hduser@dn2:/usr/local/hbase

start-hbase.sh
  >list --> to list tables
  >create 'Patient1','Personal','Medical'
  >put 'Patient','001','Personal:pname','Ramesh'

  >alter 'Patient1',{NAME=>'Personal',VERSIONS=>3} --> to change the update history from 1 to 3
  >put 'Patient1','001','Personal:pname','Ramesh k'
  >put 'Patient1','001','Personal:pname','k Ramesh'
  >scan 'Patient1',{VERSIONS => 3} --> to list the values of table with last 3 update history

  >delete 'Patient1','002','Personal:pname' --> delete a specific column from rowkey
  >deleteall 'Patient1','001' --> delete entire rowkey details
  >alter 'custmaster',{NAME=>'insurancehive',METHOD=>'delete'}

`Error and SOlution`
1. The following error appears in /usr/local/hbase/logs/hbase-hduser-master-master.log

  2018-10-04 12:07:46,986 FATAL [master:master:60000] master.HMaster: Master server abort: loaded coprocessors are: []
  2018-10-04 12:07:46,987 FATAL [master:master:60000] master.HMaster: Unhandled exception. Starting shutdown.
  org.apache.hadoop.hbase.TableExistsException: hbase:namespace
          at org.apache.hadoop.hbase.master.handler.CreateTableHandler.prepare(CreateTableHandler.java:120)
          at org.apache.hadoop.hbase.master.TableNamespaceManager.createNamespaceTable(TableNamespaceManager.java:232)
          at org.apache.hadoop.hbase.master.TableNamespaceManager.start(TableNamespaceManager.java:86)
          at org.apache.hadoop.hbase.master.HMaster.initNamespace(HMaster.java:1051)
          at org.apache.hadoop.hbase.master.HMaster.finishInitialization(HMaster.java:914)
          at org.apache.hadoop.hbase.master.HMaster.run(HMaster.java:603)
          at java.lang.Thread.run(Thread.java:748)
  2018-10-04 12:07:46,989 INFO  [master:master:60000] master.HMaster: Aborting
  .
  .
  .
  2018-10-04 12:07:47,122 INFO  [master:master:60000] master.HMaster: HMaster main thread exiting
  2018-10-04 12:07:47,123 ERROR [main] master.HMasterCommandLine: Master exiting
  java.lang.RuntimeException: HMaster Aborted
          at org.apache.hadoop.hbase.master.HMasterCommandLine.startMaster(HMasterCommandLine.java:194)
          at org.apache.hadoop.hbase.master.HMasterCommandLine.run(HMasterCommandLine.java:135)
          at org.apache.hadoop.util.ToolRunner.run(ToolRunner.java:70)
          at org.apache.hadoop.hbase.util.ServerCommandLine.doMain(ServerCommandLine.java:126)
          at org.apache.hadoop.hbase.master.HMaster.main(HMaster.java:2793)
  Thu Oct  4 12:10:15 IST 2018 Stopping hbase (via master)

  According the error above, there should be a table named hbase:namespace for maintaining the information of namespace tables. The above error is displayed when the HMaster creates the namespace directory under /hbase-unsecure directory(for non-secured cluster) and /hbase-secure(for secured cluster) while starting the process.

  Manually repair the Hbase Metastore by
  $HBASE_HOME/bin/hbase org.apache.hadoop.hbase.util.hbck.OfflineMetaRepair
  $ZK_HOME/bin/zkCli.sh
  -> ls /
  -> rmr /hbase-unsecure
  -> quit
  Restart HBase Service.

2. 'Error creating table in HBASE'. previous tables were available and error appeared after fresh start. Last session of Hbase closed properly but not zookeeper (power shut down)

hbase(main):002:0> create 'custmaster', 'customer'

ERROR: java.io.IOException: Table Namespace Manager not ready yet, try again later
        at org.apache.hadoop.hbase.master.HMaster.getNamespaceDescriptor(HMaster.java:3179)
        at org.apache.hadoop.hbase.master.HMaster.createTable(HMaster.java:1735)
        at org.apache.hadoop.hbase.master.HMaster.createTable(HMaster.java:1774)
        at org.apache.hadoop.hbase.protobuf.generated.MasterProtos$MasterService$2.callBlockingMethod(MasterProtos.java:40470)
        at org.apache.hadoop.hbase.ipc.RpcServer.call(RpcServer.java:2027)
        at org.apache.hadoop.hbase.ipc.CallRunner.run(CallRunner.java:98)
        at org.apache.hadoop.hbase.ipc.FifoRpcScheduler$1.run(FifoRpcScheduler.java:74)
        at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
        at java.util.concurrent.FutureTask.run(FutureTask.java:266)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
        at java.lang.Thread.run(Thread.java:748)

Work Around:  Running hbck to identify inconsistencies
[hduser@master ~]$ hbase hbck
         >Version: 0.98.4-hadoop2
         >Number of live region servers: 2
         >Number of dead region servers: 0
         >Master: master,60000,1538793456542
         >Number of backup masters: 0
         >Average load: 0.0
         >Number of requests: 11
         >Number of regions: 0
         >Number of regions in transition: 1
         >
         >ERROR: META region or some of its attributes are null.
         >ERROR: hbase:meta is not found on any region.
         >ERROR: hbase:meta table is not consistent. Run HBCK with proper fix options to fix hbase:meta inconsistency. Exiting...
         .
         .
         .
         >Summary:         >
         >3 inconsistencies detected.
         >Status: INCONSISTENT

[hduser@master ~]$ hbase hbck -details
         .
         .
         >ERROR: META region or some of its attributes are null.
         >ERROR: hbase:meta is not found on any region.
         >ERROR: hbase:meta table is not consistent. Run HBCK with proper fix options to fix hbase:meta inconsistency. Exiting...
         >Summary:
         >3 inconsistencies detected.
         >Status: INCONSISTENT

Meta store corrupted because the underlying file/blocks in HDFS corrupted. Either manually repair the Hbase Metastore by
  >$HBASE_HOME/bin/hbase org.apache.hadoop.hbase.util.hbck.OfflineMetaRepair
  >zkCli.sh
  >[zk: localhost:2181(CONNECTED) 0] ls /
  >[zookeeper, hbase]
  >[zk: localhost:2181(CONNECTED) 1] rmr hbase /
  >Command failed: java.lang.IllegalArgumentException: Path must start with / character
  >[zk: localhost:2181(CONNECTED) 2] rmr /hbase /
  >[zk: localhost:2181(CONNECTED) 3] ls /
  >[zookeeper]
  >[zk: localhost:2181(CONNECTED) 4] quit

  hadoop fs -rm -r /user/hduser/hbase
(OR)

Try to run hadoop fsck / to find out the corrupted files and repair 

[hduser@master ~]$ hadoop fsck /
  DEPRECATED: Use of this script to execute hdfs command is deprecated.
  Instead use the hdfs command for it.

  18/10/06 09:52:00 WARN util.NativeCodeLoader: Unable to load native-hadoop libr
  ary for your platform... using builtin-java classes where applicable
  Connecting to namenode via http://master:50070/fsck?ugi=hduser&path=%2F
  FSCK started by hduser (auth:SIMPLE) from /192.168.1.11 for path / at Sat Oct 0
  6 09:52:02 IST 2018
  ...............................................................................
  ..
  /user/hduser/hbase/.hbck/hbase-1538798774320/data/hbase/meta/1588230740/info/35
  9783d4cd07419598264506bac92dcf: CORRUPT blockpool BP-1664228054-192.168.1.11-15
  35828595216 block blk_1073744002

  /user/hduser/hbase/.hbck/hbase-1538798774320/data/hbase/meta/1588230740/info/35                                                   9783d4cd07419598264506bac92dcf: MISSING 1 blocks of total size 3934 B.........
  /user/hduser/hbase/data/default/IDX_STOCK_SYMBOL/a27db76f84487a05f3e1b8b74c13fa
  78/0/c595bf49443f4daf952df6cdaad79181: CORRUPT blockpool BP-1664228054-192.168.
  1.11-1535828595216 block blk_1073744000

  /user/hduser/hbase/data/default/IDX_STOCK_SYMBOL/a27db76f84487a05f3e1b8b74c13fa
  78/0/c595bf49443f4daf952df6cdaad79181: MISSING 1 blocks of total size 1354 B...
  .........
  ...
  /user/hduser/hbase/data/default/SYSTEM.CATALOG/d63574fdd00e8bf3882fcb6bd53c3d83
  /0/dcb68bbb5e394d19b06db7f298810de0: CORRUPT blockpool BP-1664228054-192.168.1.
  11-1535828595216 block blk_1073744001

  /user/hduser/hbase/data/default/SYSTEM.CATALOG/d63574fdd00e8bf3882fcb6bd53c3d83
  /0/dcb68bbb5e394d19b06db7f298810de0: MISSING 1 blocks of total size 2283 B.....                                                   ......................Status: CORRUPT
   Total size:    4232998 B
   Total dirs:    109
   Total files:   129
   Total symlinks:                0
   Total blocks (validated):      125 (avg. block size 33863 B)
    ********************************
    UNDER MIN REPLICAED BLOCKS:      3 (2.4 %)
    dfs.namenode.replication.min: 1
    CORRUPT FILES:        3
    MISSING BLOCKS:       3
    MISSING SIZE:         7571 B
    CORRUPT BLOCKS:       3
    ********************************
   Minimally replicated blocks:   122 (97.6 %)
   Over-replicated blocks:        0 (0.0 %)
   Under-replicated blocks:       0 (0.0 %)
   Mis-replicated blocks:         0 (0.0 %)
   Default replication factor:    2
   Average block replication:     1.952
   Corrupt blocks:                3
   Missing replicas:              0 (0.0 %)
   Number of data-nodes:          2
   Number of racks:               1
  FSCK ended at Sat Oct 06 09:52:02 IST 2018 in 66 milliseconds


  The filesystem under path '/' is CORRUPT

bin/hadoop fsck / -delete
        
==================================================================================
`Phoenix`
'Installation'
  Read https://dzone.com/articles/apache-phoenix-sql-driver

  vi /usr/local/hbase/conf/hbase-site.xml

  <property>
  <name>hbase.regionserver.wal.codec</name>
  <value>org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec</value>
  </property>

  .bashrc
  export PHOENIX_HOME=/usr/local/phoenix
  export PATH=$PATH:$PHOENIX_HOME/bin

  cd /home/hduser/install
  tar xzf phoenix-4.6.0-HBase-0.98-bin.tar.gz
  sudo mv phoenix-4.6.0-HBase-0.98-bin /usr/local/phoenix
  sudo chown -R hduser:hadoop /usr/local/phoenix
  Add below Jar files to hbase lib folder
  cd /usr/local/phoenix/

  Copy the below jars into region servers (dn1, dn2) path /usr/local/hbase/lib/

  cp phoenix-4.6.0-HBase-0.98-client-minimal.jar /usr/local/hbase/lib/
  cp phoenix-core-4.6.0-HBase-0.98.jar /usr/local/hbase/lib/ 
