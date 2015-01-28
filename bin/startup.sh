
echo "STARTING TOMCAT ......"
JAVA_HOME=$HOME/jdk1.8.0_25 JAVA_OPTS="-Djava.io.tmpdir=$TMPDIR -Dhttp.port=8080" $HOME/apache-tomcat-7.0.57/bin/catalina.sh run  >> /dev/null 2>&1 &
#echo "TOMCAT STARTED -------> $(netstat -a)"
