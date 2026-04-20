#!/bin/bash
set -euo pipefail
#detect java version
JAVA_VER=$(java -version 2>&1 | sed -n ';s/.* version "\(.*\)\.\(.*\)\..*".*/\1\2/p;')
# Setup Catalina Opts
: ${CATALINA_CONNECTOR_PROXYNAME:=}
: ${CATALINA_CONNECTOR_PROXYPORT:=}
: ${CATALINA_CONNECTOR_SCHEME:=http}
: ${CATALINA_CONNECTOR_SECURE:=false}
: ${CATALINA_OPTS:=}
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorProxyName=${CATALINA_CONNECTOR_PROXYNAME}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorProxyPort=${CATALINA_CONNECTOR_PROXYPORT}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorScheme=${CATALINA_CONNECTOR_SCHEME}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorSecure=${CATALINA_CONNECTOR_SECURE}"
CATALINA_OPTS="${CATALINA_OPTS} -Dupm.plugin.upload.enabled=true"
CATALINA_OPTS="${CATALINA_OPTS} -Datlassian.upm.signature.check.disabled=true"
CATALINA_OPTS="${CATALINA_OPTS} -Datlassian.upm.signature.check.upload.disabled=true"
CATALINA_OPTS="${CATALINA_OPTS} -Datlassian.upm.signature.check.marketplace.disabled=true"
CATALINA_OPTS="${CATALINA_OPTS} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"

# OpenSearch integration (only applied if OPENSEARCH_HTTP_URL is set)
if [ -n "${OPENSEARCH_HTTP_URL:-}" ]; then
  CATALINA_OPTS="${CATALINA_OPTS} -Dsearch.platform=opensearch"
  CATALINA_OPTS="${CATALINA_OPTS} -Dopensearch.username=${OPENSEARCH_USERNAME:-admin}"
  CATALINA_OPTS="${CATALINA_OPTS} -Dopensearch.password=${OPENSEARCH_PASSWORD}"
  CATALINA_OPTS="${CATALINA_OPTS} -Dopensearch.http.url=${OPENSEARCH_HTTP_URL}"
fi

export CATALINA_OPTS
echo "CATALINA_OPTS=$CATALINA_OPTS"
exec "$CONFLUENCE_INSTALL_DIR/bin/start-confluence.sh" "$@"
