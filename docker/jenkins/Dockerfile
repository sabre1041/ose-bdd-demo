FROM registry.access.redhat.com/rhel7/rhel

MAINTAINER Andrew Block <andy.block@gmail.com>

ENV MAVEN_VERSION=3.3.9 \
   GROOVY_VERSION=2.4.4 \
   HOME=/var/lib/jenkins \
   JENKINS_HOME=/var/lib/jenkins

# Install primary Components (Yum update, Java, Maven)
RUN curl -o /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo && \ 
  rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key && \
  yum install -y java-1.8.0-openjdk-devel which unzip tar git gettext jenkins-2.6-1.1 && \
  yum install -y yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
  yum install -y yum install jq nss_wrapper && \
  yum clean all && \
  curl -L http://dl.bintray.com/groovy/maven/apache-groovy-binary-${GROOVY_VERSION}.zip -o /tmp/apache-groovy-binary-${GROOVY_VERSION}.zip && \
  unzip /tmp/apache-groovy-binary-${GROOVY_VERSION}.zip -d /usr/local && \ 
  ln -s /usr/local/groovy-${GROOVY_VERSION} /usr/local/groovy && \
  echo "export GROOVY_HOME=/usr/local/groovy-${GROOVY_VERSION}" >> /etc/profile && \
  echo "export PATH=\$PATH:\$GROOVY_HOME/bin" >> /etc/profile && \
  rm -rf /tmp/apache-groovy-binary-${GROOVY_VERSION}.zip && \
  curl -L http://apache.mirrors.ionfish.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -o /tmp/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
  tar xzf tmp/apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /usr/local && \
  ln -s /usr/local/apache-maven-${MAVEN_VERSION} /usr/local/maven && \
  echo "export M2_HOME=/usr/local/apache-maven-${MAVEN_VERSION}" >> /etc/profile && \
  echo "export PATH=\$PATH:\$M2_HOME/bin" >> /etc/profile && \
  rm -rf /tmp/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
  source /etc/profile
  
COPY scripts /usr/local/bin
COPY conf lib /opt/openshift/

RUN /usr/local/bin/plugins.sh /opt/openshift/base-plugins.txt && \
    /usr/local/bin/fix-permissions /opt/openshift && \
    chown -R 1001:0 /opt/openshift && \
    mv /opt/openshift/settings.xml /usr/local/maven/conf/settings.xml && \
    /usr/local/bin/fix-permissions /var/lib/jenkins

  
EXPOSE 8080 50000

VOLUME ["/var/lib/jenkins"]

USER 1001

CMD ["/usr/local/bin/startup.sh"]

      