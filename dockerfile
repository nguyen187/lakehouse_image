# =========================
 # Stage 1: Build dependencies
 # =========================
 FROM flink:1.18.1-scala_2.12-java8 AS builder
 
 USER root
 
 # Install Maven for dependency resolution
 RUN apt-get update && \
 apt-get install -y curl unzip maven && \
 rm -rf /var/lib/apt/lists/*
 
 WORKDIR /build
 COPY ./tools.jar /usr/lib/jvm/java-8-openjdk-amd64/lib/tools.jar
 
 # ---------- Minimal POM with Hadoop 3.3.x enforced ----------
 RUN echo '<project xmlns="http://maven.apache.org/POM/4.0.0" \
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \
 xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 \
 http://maven.apache.org/xsd/maven-4.0.0.xsd"> \
 <modelVersion>4.0.0</modelVersion> \
 <groupId>custom.flink</groupId> \
 <artifactId>flink-deps</artifactId> \
 <version>1.0-SNAPSHOT</version> \
 <properties> \
 <hadoop.version>3.3.6</hadoop.version> \
 </properties> \
 <dependencyManagement> \
 <dependencies> \
 <!-- Force Hadoop to 3.3.6 for all modules --> \
 <dependency> \
 <groupId>org.apache.hadoop</groupId> \
 <artifactId>hadoop-common</artifactId> \
 <version>${hadoop.version}</version> \
 </dependency> \
 <dependency> \
 <groupId>org.apache.hadoop</groupId> \
 <artifactId>hadoop-hdfs</artifactId> \
 <version>${hadoop.version}</version> \
 </dependency> \
 <dependency> \
 <groupId>org.apache.hadoop</groupId> \
 <artifactId>hadoop-mapreduce-client-core</artifactId> \
 <version>${hadoop.version}</version> \
 </dependency> \
 <dependency> \
 <groupId>org.apache.hadoop</groupId> \
 <artifactId>hadoop-aws</artifactId> \
 <version>${hadoop.version}</version> \
 </dependency> \
 </dependencies> \
 </dependencyManagement> \
 <dependencies> \
 <dependency> \
 <groupId>org.apache.iceberg</groupId> \
 <artifactId>iceberg-flink-runtime-1.18</artifactId> \
 <version>1.6.0</version> \
 <exclusions> \
 <exclusion><groupId>org.apache.hadoop</groupId><artifactId>*</artifactId></exclusion> \
 </exclusions> \
 </dependency> \
 <dependency> \
 <groupId>org.apache.hadoop</groupId> \
 <artifactId>hadoop-aws</artifactId> \
 <version>${hadoop.version}</version> \
 </dependency> \
 <dependency> \
 <groupId>com.amazonaws</groupId> \
 <artifactId>aws-java-sdk-bundle</artifactId> \
 <version>1.12.696</version> \
 </dependency> \
 <dependency> \
 <groupId>org.apache.hive</groupId> \
 <artifactId>hive-metastore</artifactId> \
 <version>3.1.3</version> \
 <exclusions> \
 <exclusion><groupId>org.apache.hadoop</groupId><artifactId>*</artifactId></exclusion> \
 </exclusions> \
 </dependency> \
 <dependency> \
 <groupId>org.apache.hive</groupId> \
 <artifactId>hive-standalone-metastore</artifactId> \
 <version>3.1.3</version> \
 <exclusions> \
 <exclusion><groupId>org.apache.hadoop</groupId><artifactId>*</artifactId></exclusion> \
 </exclusions> \
 </dependency> \
 <dependency> \
 <groupId>commons-cli</groupId> \
 <artifactId>commons-cli</artifactId> \
 <version>1.5.0</version> \
 </dependency> \
 <dependency> \
 <groupId>org.apache.flink</groupId> \
 <artifactId>flink-core</artifactId> \
 <version>1.18.1</version> \
 </dependency> \
 <dependency> \
 <groupId>jdk.tools</groupId> \
 <artifactId>jdk.tools</artifactId> \
 <version>1.8.0_422</version> \
 <scope>system</scope> \
 <systemPath>/usr/lib/jvm/java-8-openjdk-amd64/lib/tools.jar</systemPath> \
 </dependency> \
 <dependency> \
 <groupId>org.apache.thrift</groupId> \
 <artifactId>libthrift</artifactId> \
 <version>0.13.0</version> \
 </dependency> \
 <dependency> \
 <groupId>org.apache.hive</groupId> \
 <artifactId>hive-exec</artifactId> \
 <version>3.1.3</version> \
 <scope>provided</scope> \
 <exclusions> \
 <exclusion><groupId>org.apache.hadoop</groupId><artifactId>*</artifactId></exclusion> \
 </exclusions> \
 </dependency> \
 <dependency> \ 
 <groupId>org.apache.hadoop</groupId> \ 
 <artifactId>hadoop-common</artifactId> \ 
 <version>3.3.6</version> \ 
 </dependency> \
 <dependency> \
 <groupId>com.alibaba.blink</groupId> \
 <artifactId>flink-shaded-hadoop3-uber</artifactId> \
 <version>blink-3.6.8</version> \
 </dependency> \
 <dependency> \
 <groupId>org.apache.flink</groupId> \
 <artifactId>flink-connector-kafka</artifactId> \
 <version>3.2.0-1.18</version> \
 </dependency> \
 <dependency> \ 
 <groupId>org.apache.flink</groupId> \
 <artifactId>flink-orc</artifactId> \
 <version>1.18.1</version> \
 </dependency> \
 <dependency> \
 <groupId>org.apache.flink</groupId> \
 <artifactId>flink-avro</artifactId> \
 <version>1.18.1</version> \
 </dependency> \
 <dependency> \
 <groupId>org.apache.flink</groupId> \
 <artifactId>flink-table-api-scala-bridge_2.12</artifactId> \
 <version>1.18.1</version> \
 </dependency>\
 <dependency> \
 <groupId>org.apache.commons</groupId> \
 <artifactId>commons-math3</artifactId> \
 <version>3.6.1</version> \
 </dependency> \
 </dependencies> \
 </project>' > pom.xml
 
 # Resolve runtime dependencies
 RUN mvn -B dependency:copy-dependencies \
 -DincludeScope=runtime \
 -DoutputDirectory=target/flink-lib
 
 # =========================
 # Stage 2: Final Flink image
 # =========================
 FROM flink:1.18.1-scala_2.12-java8
 
 USER root
 WORKDIR /opt/flink
 
 # Install Kerberos client + MinIO client
 RUN apt-get update && \
 apt-get install -y krb5-user libsasl2-modules-gssapi-mit wget && \
 wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc && \
 chmod +x /usr/local/bin/mc && \
 rm -rf /var/lib/apt/lists/*
 
 # Copy resolved dependency jars from builder stage
 COPY --from=builder /build/target/flink-lib/*.jar /opt/flink/lib/
 
 USER root
