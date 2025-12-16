FROM ubuntu:20.04
LABEL MAINTAINER @aruizca - Angel Ruiz

ENV JAVA_HOME /opt/jre
ENV PATH $JAVA_HOME/bin:$PATH
# https://confluence.atlassian.com/doc/confluence-home-and-other-important-directories-590259707.html
ENV CONFLUENCE_HOME          /var/atlassian/application-data/confluence
ENV CONFLUENCE_INSTALL_DIR   /opt/atlassian/confluence
ENV CURL_CA_BUNDLE /opt/netskope-cert-bundle.pem
ENV SSL_CERT_FILE /opt/netskope-cert-bundle.pem
ARG CONFLUENCE_VERSION
ARG JAVA_VERSION

COPY scripts/netskope-cert-bundle.pem /opt/

# Set JAVA_HOME first
ENV JAVA_HOME=/opt/java
ENV PATH=$JAVA_HOME/bin:$PATH

# Install some utilse
RUN apt-get update \
&& apt-get install -yq wget curl bash jq ttf-dejavu ca-certificates tzdata locales locales-all fontconfig unzip zip \
&& update-ca-certificates \
&& rm -rf /var/lib/{apt,dpkg,cache,log}/ /tmp/* /var/tmp/*

# Install SDKMAN and Java 21
RUN curl -s "https://get.sdkman.io" | bash \
    && bash -c "source /root/.sdkman/bin/sdkman-init.sh \
                && sdk install java ${JAVA_VERSION} \
                && sdk flush archives" \
    && ln -s /root/.sdkman/candidates/java/current $JAVA_HOME

# Verify installation
RUN $JAVA_HOME/bin/java -version && ls -l $JAVA_HOME/bin

# Add netskope pem to Java keystore
RUN echo "changeit" | $JAVA_HOME/bin/keytool \
    -import -keystore $JAVA_HOME/lib/security/cacerts \
    -file /opt/netskope-cert-bundle.pem -noprompt


# If no Confluence version provided via command line argument, the last available version will be installed

# Expose HTTP, Synchrony ports and Debug ports
EXPOSE 8090 8091 5005

WORKDIR $CONFLUENCE_HOME

RUN mkdir scripts
COPY scripts/features/entrypoint.sh /scripts/features/entrypoint.sh

# Download required Confluence version
RUN [ -n "${CONFLUENCE_VERSION}" ] || export CONFLUENCE_VERSION=$(curl -s https://marketplace.atlassian.com/rest/2/applications/confluence/versions/latest | jq -r '.version') \
    && export DOWNLOAD_URL="http://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz" \
    && echo $CONFLUENCE_VERSION \
    && echo $DOWNLOAD_URL \
    && echo $CONFLUENCE_INSTALL_DIR \
    && mkdir -p                          ${CONFLUENCE_INSTALL_DIR} \
    && curl -L                           ${DOWNLOAD_URL} | tar -xz --strip-components=1 -C "$CONFLUENCE_INSTALL_DIR"

# Perform settings modifications
RUN sed -i -e 's/-Xms\([0-9]\+[kmg]\) -Xmx\([0-9]\+[kmg]\)/-Xms\${JVM_MINIMUM_MEMORY:=\1} -Xmx\${JVM_MAXIMUM_MEMORY:=\2} \${JVM_SUPPORT_RECOMMENDED_ARGS} -Dconfluence.home=\${CONFLUENCE_HOME} -Dsynchrony.proxy.healthcheck.disabled=true/g' ${CONFLUENCE_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/<Context path=""/<Context path="\/confluence"/g' ${CONFLUENCE_INSTALL_DIR}/conf/server.xml \
    && sed -i -e 's/\${confluence.context.path}/\/confluence/g' ${CONFLUENCE_INSTALL_DIR}/conf/server.xml

CMD ["/scripts/features/entrypoint.sh", "-fg"]