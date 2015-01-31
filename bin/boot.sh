#!/bin/bash

echo "Starting websocketd..."
ls -l /app/websocketd/bash.sh
ls -l /app/websocketd/bin
/app/websocketd --port=$PORT --devconsole /app/websocketd/bash.sh
exit 1

# ------------------------------------------------------------------------------------------------

export APP_ROOT=$HOME

# -------------------------------config file manipulation-----------------------------------------------------------------
apache_conf_file=$APP_ROOT/apache2/conf/httpd.conf
mv $apache_conf_file $APP_ROOT/apache2/conf/orig.conf
erb $APP_ROOT/apache2/conf/orig.conf > $APP_ROOT/apache2/conf/httpd.conf

apache_vhost_conf_file=$APP_ROOT/apache2/conf/extra/httpd-vhosts.conf
mv $apache_vhost_conf_file $APP_ROOT/apache2/conf/extra/orig_vhost.conf
erb $APP_ROOT/apache2/conf/extra/orig_vhost.conf > $APP_ROOT/apache2/conf/extra/httpd-vhosts.conf
chmod -R uog+rx $APP_ROOT/apache2

# -------------------------------load apache Lib's-------------------------#
export LD_LIBRARY_PATH="$APP_ROOT/apache2/lib"

ldd $APP_ROOT/apache2/bin/httpd
# -------------------------------starting httpd-------------------------#
(tail -f -n 0 $APP_ROOT/apache2/logs/*.log &)
$APP_ROOT/apache2/bin/httpd -k start -f $APP_ROOT/apache2/conf/httpd.conf

echo "STARTING TOMCAT ......"
JAVA_HOME=$HOME/jdk1.8.0_25 JAVA_OPTS="-Djava.io.tmpdir=$TMPDIR -Dhttp.port=8080" $HOME/apache-tomcat-7.0.57/bin/catalina.sh run >> /dev/null 2>&1 &

while pgrep -f /app/apache2/bin/httpd >/dev/null; do
echo "Apache running..."
sleep 60
done
