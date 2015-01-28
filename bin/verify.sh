

while pgrep -f /app/apache2/bin/httpd >/dev/null; do
echo "Apache running..."
sleep 60
done


#curl --silent --show-error --connect-timeout 1 -I http://localhost:8080

