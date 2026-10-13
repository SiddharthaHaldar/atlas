for config_file in \
  "$NUXEO_HOME/templates/common-base/conf/server.xml.nxftl" \
  "$NUXEO_HOME/conf/server.xml"
do
  if [ -f "$config_file" ] && ! grep -q 'RemoteIpValve' "$config_file"; then
    sed -i '/<Engine name="Catalina" defaultHost=/a\
      <Valve className="org.apache.catalina.valves.RemoteIpValve" internalProxies="127\\..*|10\\..*|172\\.(1[6-9]|2[0-9]|3[01])\\..*|192\\.168\\..*" remoteIpHeader="x-forwarded-for" protocolHeader="x-forwarded-proto" portHeader="x-forwarded-port" />' "$config_file"
  fi
done