  <property>
    <name>hive.execution.engine</name>
    <value>tez</value>
  </property>
  <property>
    <name>hive.vectorized.execution.enabled</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.limit.pushdown.memory.usage</name>
    <value>0.04</value>
  </property>
  <property>
    <name>hive.vectorized.groupby.checkinterval</name>
    <value>4096</value>
  </property>
  <property>
    <name>hive.input.format</name>
    <value>org.apache.hadoop.hive.ql.io.HiveInputFormat</value>
  </property>
  <property>
    <name>hive.auto.convert.join.noconditionaltask.size</name>
    <value>128000000</value>
  </property>
  <property>
    <name>hive.optimize.reducededuplication.min.reducer</name>
    <value>4</value>
  </property>
  <property>
    <name>hive.optimize.index.filter</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.jar.directory</name>
    <value>hdfs:///user/hive/</value>
  </property>
  <property>
    <name>hive.server2.thrift.port</name>
    <value>10002</value>
  </property>
  <property>
    <name>hive.server2.tez.default.queues</name>
    <value>default</value>
  </property>
  <property>
    <name>hive.server2.tez.sessions.per.default.queue</name>
    <value>1</value>
  </property>
  <property>
    <name>hive.server2.tez.initialize.default.sessions</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.server2.enable.doAs</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.server2.enable.doAs</name>
    <value>false</value>
  </property>
  <property>
    <name>hive.fetch.task.conversion</name>
    <value>more</value>
  </property>
  <property>
    <name>hive.compute.query.using.stats</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.stats.fetch.column.stats</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.stats.fetch.partition.stats</name>
    <value>true</value>
  </property>
<!--  <property>
    <name>hive.tez.java.opts</name>
    <value>-Dsun.net.inetaddr.negative.ttl=0  -Dsun.net.inetaddr.ttl=0 ${mapreduce.map.java.opts}</value>
  </property> -->
</configuration>
