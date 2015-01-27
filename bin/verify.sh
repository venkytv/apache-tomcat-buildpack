run=`ps ax | grep httpd | grep -v grep | cut -c1-5 | paste -s -` 

if [ "$run" ]; 
then 
  echo "Apache is running" 
else 
   echo "Apache is not running"
fi 


#curl --silent --show-error --connect-timeout 1 -I http://localhost:8080

