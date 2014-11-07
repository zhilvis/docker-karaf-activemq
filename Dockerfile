FROM java:7

RUN wget http://apache.openmirror.de/karaf/3.0.2/apache-karaf-3.0.2.tar.gz; \
    mkdir /opt/karaf; \
    tar --strip-components=1 -C /opt/karaf -xzvf apache-karaf-3.0.2.tar.gz; \
    rm apache-karaf-3.0.2.tar.gz;

RUN apt-get update -q; apt-get install -y procps

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
EXPOSE 1099 8101 44444

RUN /opt/karaf/bin/start; until /opt/karaf/bin/client -u karaf version; do sleep 5s; done; /opt/karaf/bin/stop;

RUN /opt/karaf/bin/instance create db; /opt/karaf/bin/instance create mq;

RUN /opt/karaf/instances/mq/bin/start; \
    until /opt/karaf/bin/client -a 8103 -u karaf version; do sleep 5s; done; \
    /opt/karaf/bin/client -a 8103 -u karaf feature:repo-add activemq 5.9.0; \
    /opt/karaf/bin/client -a 8103 -u karaf feature:install activemq-broker; \
    /opt/karaf/bin/client -a 8103 -u karaf "bundle:install -s mvn:org.apache.activemq/activemq-web/5.9.0"; \
    /opt/karaf/bin/client -a 8103 -u karaf "bundle:install -s mvn:org.apache.activemq/activemq-web-demo/5.9.0/war"; \
    /opt/karaf/instances/mq/bin/stop;

RUN sed -i '/jaasAuthenticationPlugin/d' /opt/karaf/instances/mq/etc/activemq.xml

EXPOSE 8102 8103
