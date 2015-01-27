---

# A buildpack for hosting java webapplication  on Cloud Foundry using apache-tomcat


## Using this buildpack as-is

##Detect phase :
Ensure that your app's root folder has an `index.html` or `index.htm` or `Default.htm` or '*.war'

##Compile phase : 
	
	1) compile build dir and compile cache dir are the two arguments for compile script.
			compile_build_dir: /tmp/staged/app
			compile_cache_dir: /tmp/cache
	2) build pack scripts will be downloded to below folder.
			compile_buildpack_bin: /tmp/buildpacks/{build-pack-repository-name}/bin
			compile_buildpack_dir: /tmp/buildpacks/{build-pack-repository-name}
	3) current working directory
			pwd: /tmp/staged

    4) creating public directory under cache directory (tmb/cache/public)
	
	5)moving all the files from cache directory to public
	
	6) creating .Procfile under public folder . refered few scripts are following this standard will review it later for the need basis) 
			PROC file systme acts as an interface to kernal, so user can treat it as a normal file to access,
	but it only exists in memory, does not exist in the physical disk.
	
	7) extracting jdk 
	        a) if jdk is available in cache folder we will copy to build directory
	        b) other wise download the jdk from https://s3.amazonaws.com/covisintrnd.com-software/jdk-8u25-linux-x64.gz and extract it
	        c) Export JAVA_HOME into path variable
	        
	8) compile and install apache
	        a) if apache2 folder available in cache folder then copy into build directory.
	        b)other wise httpd-2.2.29.tar.gz has been available in buildpack binaries then configure, make and make install .
	            --enable [mods-shared=all,http,deflate ,expires ,slotmem-shm, headers, rewrite, proxy, proxy-balancer, proxy-http, 
	            proxy- fcgi,mime-magic,log-debug,with-mpm=event,with-included-apr]
			    make and make install
	9)extract tomcat
	        a) if tomcat available in cache folder then copy into build directory         
            b) otherwise we need to extract the  apache-tomcat-7.0.57.tar.gz which has available in binaries folder. 
	
	10) apache 2 configuration
	        a) httpd.conf which has available in buildpack conf folder will be copied over to apache2/conf folder
	                VCAP_APP_PORT , VCAP_APP_HOST has been dynamically render for Listen and ServerName purpose.
	        b) httpd-vhosts.conf which has available in build pack conf folder will be copied over to apache2/conf/extra folder.
	                <VirtualHost *:<%= ENV["VCAP_APP_PORT"] %>>
                            ProxyRequests Off
                            ProxyPreserveHost On
                            ProxyPass / http://localhost:8080/
                            ProxyPassReverse / http://localhost:8080/
                            ErrorLog "logs/error.log"
                            CustomLog "logs/access.log" common
                    </VirtualHost>      
	            Note : currently we have used ProxyPass for proxy later it will be enhanced with mod_jk.
	         c) webagent.conf configuration file is used for cTrust integration. So this file will be copied over apache2/conf folder.
	                libct_apache22_agent-4.8.0.46-x64.so module will be used for integrating Ctrust.
	         d) error and access logs will be copied over from conf of buildpack to apache2/logs folder.
	 
	 11)tomcat2 configuration
	        a) logging.properties has been copied from conf folder to tomcat*/conf
	                we have removed the ConsoleHandler to avoid the STDOUT (catalina.out) logs to console. 
	        b)server.xml from conf folder of buildpack will be copied into tomcat*/conf folder.
	          ${http.port} connector port will be comming dynamically.            
	 12)copy boot.sh and startup.sh to buildpack directory which will be used during release phase of buildpack
	           boot.sh : 
	                a) using Ruby erb template we will merge VCAP varibles and copy the config files (httpd, httpd-vhosts) to apache2.
	                b) export the LD_LIBRARY_PATH which is for apache2
	                c) start the httpd
	           startup.sh:
	                    we are starting catalina.sh by passing JAVA_HOME & JAVA_OPTS.
	  13) remove jdk , apache and tomcat from cache folder 
	  14) copy latest jdk,apache and tomcat to cache folder from builddir.
	  15) extracting war files
	            copy all the war files available in buildpack folder into tomcat*/webapps folder.
	     
	
##Release phase :

		a) release phase will invoke the boot.sh, startup.sh 	
		
##Risks / Issues :
			1)need to integrate Ctrust agent to apache2
			2)need to develope ruby project which will be replacement for fatjar which is generating webagent.conf dyanamically. 
	
##Run:

```
cf push {project-name} -b https://github.com/happiestminds-covisint/apache-tomcat-buildpack.git
```

``
