
YUM=$(shell which yum)
APT=$(shell which apt-get)
TOOLS=git gcc cmake pdsh
TEZ_VERSION=0.3.0-incubating-SNAPSHOT
TEZ_BRANCH=master
HDFS=$(shell id hdfs 2> /dev/null)
HADOOP_VERSION=2.3.0-SNAPSHOT
APP_PATH:=$(shell echo /user/$$USER/apps/`date +%Y-%b-%d`/)
INSTALL_ROOT:=$(shell echo $$PWD/dist/)
HIVE_CONF_DIR=/etc/hive/conf/

-include local.mk

ifneq ($(HDFS),)
	AS_HDFS=sudo -u hdfs env PATH=$$PATH JAVA_HOME=$$JAVA_HOME HADOOP_HOME=$$HADOOP_HOME HADOOP_CONF_DIR=$$HADOOP_CONF_DIR bash
else
	AS_HDFS=bash
endif

git: 
ifneq ($(YUM),)
	which $(TOOLS) || yum -y install git-core \
	gcc gcc-c++ \
	pdsh \
	cmake \
	zlib-devel openssl-devel \
	mysql-connector-java
endif
ifneq ($(APT),)
	which $(TOOLS) || apt-get install -y git gcc g++ python man cmake zlib1g-dev libssl-dev libmysql-java 
endif

maven: 
	wget -c http://www.us.apache.org/dist/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz
	-- mkdir -p $(INSTALL_ROOT)/maven/
	tar -C $(INSTALL_ROOT)/maven/ --strip-components=1 -xzvf apache-maven-3.0.5-bin.tar.gz

ant: 
	wget -c http://archive.apache.org/dist/ant/binaries/apache-ant-1.9.1-bin.tar.gz
	-- mkdir -p $(INSTALL_ROOT)/ant/
	tar -C $(INSTALL_ROOT)/ant/ --strip-components=1 -xzvf apache-ant-1.9.1-bin.tar.gz
	-- yum -y remove ant

protobuf: git 
	wget -c http://protobuf.googlecode.com/files/protobuf-2.5.0.tar.bz2
	tar -xvf protobuf-2.5.0.tar.bz2
	test -f $(INSTALL_ROOT)/protoc/bin/protoc || \
	(cd protobuf-2.5.0; \
	./configure --prefix=$(INSTALL_ROOT)/protoc/; \
	make -j4; \
	make install -k)

tez: git maven protobuf
	test -d tez || git clone --branch $(TEZ_BRANCH) https://git-wip-us.apache.org/repos/asf/incubator-tez.git tez
	export PATH=$(INSTALL_ROOT)/protoc/bin:$(INSTALL_ROOT)/maven/bin/:$$PATH; \
	cd tez/; . /etc/profile; \
	mvn package install -Pdist -DskipTests -Dhadoop.version=$(HADOOP_VERSION);


tez-maven-register: tez
	$(INSTALL_ROOT)/maven/bin/mvn org.apache.maven.plugins:maven-install-plugin:2.5.1:install-file -Dfile=./tez/tez-api/target/tez-api-$(TEZ_VERSION).jar -DgroupId=org.apache.tez -DartifactId=tez-api -Dversion=$(TEZ_VERSION) -Dpackaging=jar -DlocalRepositoryPath=/root/.m2/repository 
	$(INSTALL_ROOT)/maven/bin/mvn org.apache.maven.plugins:maven-install-plugin:2.5.1:install-file -Dfile=./tez/tez-mapreduce/target/tez-mapreduce-$(TEZ_VERSION).jar -DgroupId=org.apache.tez -DartifactId=tez-mapreduce -Dversion=$(TEZ_VERSION) -Dpackaging=jar -DlocalRepositoryPath=/root/.m2/repository 
	$(INSTALL_ROOT)/maven/bin/mvn org.apache.maven.plugins:maven-install-plugin:2.5.1:install-file -Dfile=./tez/tez-runtime-library/target/tez-runtime-library-$(TEZ_VERSION).jar -DgroupId=org.apache.tez -DartifactId=tez-runtime-library -Dversion=$(TEZ_VERSION) -Dpackaging=jar -DlocalRepositoryPath=/root/.m2/repository 
	$(INSTALL_ROOT)/maven/bin/mvn org.apache.maven.plugins:maven-install-plugin:2.5.1:install-file -Dfile=./tez/tez-tests/target/tez-tests-$(TEZ_VERSION)-tests.jar -DgroupId=org.apache.tez -DartifactId=tez-tests -Dversion=$(TEZ_VERSION) -Dclassifier=tests -Dpackaging=test-jar -DlocalRepositoryPath=/root/.m2/repository 
	$(INSTALL_ROOT)/maven/bin/mvn org.apache.maven.plugins:maven-install-plugin:2.5.1:install-file -Dfile=./tez/tez-common/target/tez-common-$(TEZ_VERSION).jar -DgroupId=org.apache.tez -DartifactId=tez-common -Dversion=$(TEZ_VERSION) -Dpackaging=jar -DlocalRepositoryPath=/root/.m2/repository


hive: tez-dist.tar.gz 
	test -d hive || git clone --branch tez https://github.com/apache/hive
	cd hive; sed -i~ "s@<tez.version>.*</tez.version>@<tez.version>$(TEZ_VERSION)</tez.version>@" pom.xml
	export PATH=$(INSTALL_ROOT)/protoc/bin:$(INSTALL_ROOT)/maven/bin/:$(INSTALL_ROOT)/ant/bin:$$PATH; \
	cd hive/; . /etc/profile; \
	mvn package -DskipTests=true -Pdist -Phadoop-2 -Dhadoop-0.23.version=$(HADOOP_VERSION) -Dbuild.profile=nohcat;

dist-tez: tez 
	tar -C tez/tez-dist/target/tez-*full/tez-*full -czvf tez-dist.tar.gz .

dist-hive: hive
	tar --exclude='hadoop-*.jar' --exclude='protobuf-*.jar' -C hive/packaging/target/apache-hive*/apache-hive*/ -czvf hive-dist.tar.gz .

tez-dist.tar.gz:
	@echo "run make dist to get tez-dist.tar.gz"

hive-dist.tar.gz:
	@echo "run make dist to get tez-dist.tar.gz"

dist: dist-tez dist-hive

tez-hiveserver-on:
	@cp scripts/startHiveserver2.sh.on /tmp/startHiveserver2.sh
	@echo "HiveServer2 will now run jobs using Tez."
	@echo "Reboot the Sandbox for changes to take effect."

tez-hiveserver-off:
	@cp scripts/startHiveserver2.sh.off /tmp/startHiveserver2.sh
	@echo "HiveServer2 will now run jobs using Map-Reduce."
	@echo "Reboot the Sandbox for changes to take effect."

install: tez-dist.tar.gz hive-dist.tar.gz
	rm -rf $(INSTALL_ROOT)/tez
	mkdir -p $(INSTALL_ROOT)/tez/conf
	tar -C $(INSTALL_ROOT)/tez/ -xzvf tez-dist.tar.gz
	cp -v tez-site.xml $(INSTALL_ROOT)/tez/conf/
	sed -i~ "s@/apps@$(APP_PATH)@g" $(INSTALL_ROOT)/tez/conf/tez-site.xml
	$(AS_HDFS) -c "hadoop fs -rm -R -f $(APP_PATH)/tez/"
	$(AS_HDFS) -c "hadoop fs -mkdir -p $(APP_PATH)/tez/"
	$(AS_HDFS) -c "hadoop fs -copyFromLocal -f $(INSTALL_ROOT)/tez/*.jar $(INSTALL_ROOT)/tez/lib/ $(APP_PATH)/tez/"
	rm -rf $(INSTALL_ROOT)/hive
	mkdir -p $(INSTALL_ROOT)/hive
	tar -C $(INSTALL_ROOT)/hive -xzvf hive-dist.tar.gz
	(test -d $(HIVE_CONF_DIR) && rsync -avP $(HIVE_CONF_DIR)/ $(INSTALL_ROOT)/hive/conf/) \
	    || (cp hive-site.xml.default $(INSTALL_ROOT)/hive/conf && sed -i~ "s@HOSTNAME@$$(hostname)@" $(INSTALL_ROOT)/hive/conf/hive-site.xml)
	echo "export HADOOP_CLASSPATH=$(INSTALL_ROOT)/tez/*:$(INSTALL_ROOT)/tez/lib/*:$(INSTALL_ROOT)/tez/conf/:/usr/share/java/*:$$HADOOP_CLASSPATH" >> $(INSTALL_ROOT)/hive/bin/hive-config.sh
	(test -f $(INSTALL_ROOT)/hive/conf/hive-env.sh && sed -i~ "s@export HIVE_CONF_DIR=.*@export HIVE_CONF_DIR=$(INSTALL_ROOT)/hive/conf/@" $(INSTALL_ROOT)/hive/conf/hive-env.sh) \
		|| echo "export HIVE_CONF_DIR=$(INSTALL_ROOT)/hive/conf/" > $(INSTALL_ROOT)/hive/conf/hive-env.sh
	sed -e "s@hdfs:///user/hive/@hdfs://$(APP_PATH)/hive/@" hive-site.xml.frag > hive-site.xml.local
	sed -i~ \
	-e "s/org.apache.hadoop.hive.ql.security.ProxyUserAuthenticator//" \
	-e "/<.configuration>/r hive-site.xml.local" \
	-e "x;" \
	$(INSTALL_ROOT)/hive/conf/hive-site.xml    
	$(AS_HDFS) -c "hadoop fs -rm -f $(APP_PATH)/hive/hive-exec-0.13.0-SNAPSHOT.jar"
	$(AS_HDFS) -c "hadoop fs -mkdir -p $(APP_PATH)/hive/"
	$(AS_HDFS) -c "hadoop fs -copyFromLocal -f $(INSTALL_ROOT)/hive/lib/hive-exec-0.13.0-SNAPSHOT.jar $(APP_PATH)/hive/"

.PHONY: hive tez protobuf ant maven
