FROM openjdk:8-jdk-alpine
MAINTAINER Mindgrub

ENV PIO_VERSION 0.12.0
ENV SPARK_VERSION 2.1.1
ENV ELASTICSEARCH_VERSION 5.5.2
ENV HBASE_VERSION 1.2.6

ENV HOME /home/pio
ENV PIO_HOME ${HOME}/PredictionIO-${PIO_VERSION}-incubating
ENV PIO_USER pio
ENV PATH=${PIO_HOME}/bin:$PATH
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# install dependencies.
RUN apk add --update \
    curl \
    bash \
#    libgfortran3 \
#    python \
#    python-dev \
#    py-pip \
#    python-pip \
    sudo \
    && rm -rf /var/cache/apk/*

# Create pio user.
RUN addgroup -S ${PIO_USER}
RUN adduser -S -G ${PIO_USER} -s /bin/bash ${PIO_USER} \
    && echo "${PIO_USER} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${PIO_USER} \
    && chmod 0440 /etc/sudoers.d/${PIO_USER}

# Switch to a none root user.
USER ${PIO_USER}

### Install Predictionio.
RUN cd ${HOME} \
    && curl -O http://apache.mirrors.pair.com/incubator/predictionio/${PIO_VERSION}-incubating/apache-predictionio-${PIO_VERSION}-incubating.tar.gz \
    && mkdir apache-predictionio-${PIO_VERSION}-incubating \
    && tar -xvzf apache-predictionio-${PIO_VERSION}-incubating.tar.gz -C ./apache-predictionio-${PIO_VERSION}-incubating \
    && rm apache-predictionio-${PIO_VERSION}-incubating.tar.gz \
    && cd apache-predictionio-${PIO_VERSION}-incubating \
    && ./make-distribution.sh

RUN tar zxvf ${HOME}/apache-predictionio-${PIO_VERSION}-incubating/PredictionIO-${PIO_VERSION}-incubating.tar.gz -C ${HOME} \
    && rm -r ${HOME}/apache-predictionio-${PIO_VERSION}-incubating \
    && mkdir /${PIO_HOME}/vendors

COPY config/pio-env.sh ${PIO_HOME}/conf/pio-env.sh

# Fix permissions
RUN sudo chown -R ${PIO_USER}:${PIO_USER} ${PIO_HOME}/conf/pio-env.sh

# Install Spark.
RUN cd ${HOME} \
    && curl -O http://d3kbcqa49mib13.cloudfront.net/spark-${SPARK_VERSION}-bin-hadoop2.6.tgz \
    && tar -zxvf spark-${SPARK_VERSION}-bin-hadoop2.6.tgz -C ${PIO_HOME}/vendors \
    && rm spark-${SPARK_VERSION}-bin-hadoop2.6.tgz

# Install elastic search.
RUN cd ${HOME} \
    && curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && tar -xvzf elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz -C ${PIO_HOME}/vendors \
    && rm elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && echo 'cluster.name: predictionio' >> ${PIO_HOME}/vendors/elasticsearch-${ELASTICSEARCH_VERSION}/config/elasticsearch.yml \
    && echo 'network.host: 127.0.0.1' >> ${PIO_HOME}/vendors/elasticsearch-${ELASTICSEARCH_VERSION}/config/elasticsearch.yml

# Install Hbase
RUN cd ${HOME} \
    && curl -O http://apache.mirrors.hoobly.com/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz \
    && tar -xvzf hbase-${HBASE_VERSION}-bin.tar.gz -C ${PIO_HOME}/vendors \
    && rm hbase-${HBASE_VERSION}-bin.tar.gz

COPY config/hbase-site.xml ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml

# Fix permissions
RUN sudo chown -R ${PIO_USER}:${PIO_USER} ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml

RUN sed -i "s|VAR_PIO_HOME|${PIO_HOME}|" ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml \
    && sed -i "s|VAR_HBASE_VERSION|${HBASE_VERSION}|" ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml

WORKDIR ${PIO_HOME}

#CMD ["pio-start-all"]