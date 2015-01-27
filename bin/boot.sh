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
