if [ -n "${NUXEO_URL:-}" ]; then
  nuxeo_host=${NUXEO_URL#*://}
  nuxeo_host=${nuxeo_host%%/*}
  nuxeo_host=${nuxeo_host%%:*}
else
  nuxeo_host=
fi

for config_file in \
  "$NUXEO_HOME/templates/common-base/conf/server.xml.nxftl" \
  "$NUXEO_HOME/conf/server.xml"
do
  if [ -n "$nuxeo_host" ] && ! grep -q "proxyName=\"$nuxeo_host\"" "$config_file"; then
    sed -i '/<Connector port=.*protocol="HTTP\/1.1"/ { /SSLEnabled/! s|protocol="HTTP/1.1"|protocol="HTTP/1.1" proxyName="'"$nuxeo_host"'" proxyPort="443" scheme="https" secure="true"|; }' "$config_file"
  fi
  sed -i '/<Valve className="org.apache.catalina.valves.RemoteIpValve"/d' "$config_file"
done

if [ -n "${NUXEO_URL:-}" ]; then
  filter_source=/opt/nuxeo/public-origin-filter
  filter_build=$(mktemp -d)
  javac -source 7 -target 7 \
    -classpath "$NUXEO_HOME/lib/servlet-api.jar" \
    -d "$filter_build" "$filter_source"/*.java
  jar cfm "$NUXEO_HOME/nxserver/bundles/atlas-public-origin-filter.jar" \
    "$filter_source/META-INF/MANIFEST.MF" \
    -C "$filter_build" . -C "$filter_source" OSGI-INF
  rm -rf "$filter_build"
fi