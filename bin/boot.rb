#!/usr/bin/env ruby

require 'erb'
require 'fileutils'
require 'yaml'

INBASE = File.join(ENV['HOME'], 'templates')
OUTBASE = '/app'
ORIGDIR = Dir.getwd

configfile = File.join(ENV['HOME'], 'config.yml')
config = YAML.load(File.read(configfile))

# If Apache is not present, have Tomcat listen on the default port
tomcat_port = (config['bundles'].has_key?('apache') ?  8080 : ENV['VCAP_APP_PORT'])

# Substitute parameters in template files and install them
Dir.chdir INBASE
Dir['**/*'].each do |tmpl|
    next unless File.file? tmpl

    infile = File.join(INBASE, tmpl)
    outfile = File.join(OUTBASE, tmpl)
    outdir = File.dirname outfile
    FileUtils.mkdir_p outdir unless File.directory? outdir

    puts "Generating file: #{outfile}"
    out = ERB.new(File.read(infile)).result
    File.open(outfile, 'w') do |f|
        f.print out
    end
end

WEBAPPDIR = '/app/tomcat/webapps'

# Install the war files
Dir['*.war'].each do |war|
    puts "Deploying #{war}"
    FileUtils.cp(war, WEBAPPDIR)
end

# Install war files from zip bundles
Dir.chdir WEBAPPDIR
Dir[File.join(ORIGDIR, '*.zip')].each do |zip|
    puts "Deploying wars from #{File.basename(zip)}"
    system('unzip', zip, '*.war') \
        or abort "Failed to unzip #{zip}"
end
Dir.chdir ORIGDIR

daemons = [
    # Apache
    {
      :name => 'apache',
      :commline => %w( /app/apache/bin/httpd -k start ),
      :logs => %w( /app/apache/logs/error_log ),
    },

    # Tomcat
    {
      :name => 'tomcat',
      :env => {
                :CATALINA_HOME => '/app/tomcat',
                :JAVA_HOME => '/app/jre',
                :JAVA_OPTS => "-Djava.io.tmpdir=#{ENV['TMPDIR']} -Dhttp.port=#{tomcat_port}",
              },
      :commline => %w( /app/tomcat/bin/catalina.sh start ),
      :logs => %w( /app/tomcat/logs/catalina.out ),
      :pgrep_pattern => 'org.apache.catalina.startup.Bootstrap start',
    },
]

if (config['options']['enable_websocketd'])
    daemons.push({
        :name => 'websocketd',
        :commline => %w( /app/websocketd/websocketd --port=9090 --dir=/app/websocketd/commands --devconsole ),
    })
end

# Start the daemons
pgrep_patterns = {}
daemons.each do |daemon|
    name = daemon[:name]
    if (config['bundles'].has_key?(name))
        pid = fork do
            puts "Starting #{name}"
            env = (daemon.has_key?(:env) ? daemon[:env] : {})
            env.each do |name, value|
                ENV[name.to_s] = value
            end
            exec(*daemon[:commline])
        end

        # Store pgrep pattern for health check.
        # If :pgrep_pattern is not provided, use :commline as pgrep pattern
        # If :pgrep_pattern is nil, skip health check for this daemon
        if (not daemon.has_key?(:pgrep_pattern) or daemon[:pgrep_pattern])
            pattern = (daemon[:pgrep_pattern] || daemon[:commline])
            pattern = pattern.join(' ') if pattern.is_a?(Array)
            pgrep_patterns[name] = pattern
        end

        # Tail logs
        if (daemon.has_key?(:logs))
            daemon[:logs].each do |log|
                system("tail --follow=name --retry #{log} &")
            end
        end
    else
        puts "Skipping #{name}"
    end
end

# Wait for daemons to start up
sleep 5

# Spin as long as the daemons are alive
while (true)
    pgrep_patterns.each do |name, pattern|
        f = IO.popen("pgrep -f -l '#{pattern}' | grep -v grep")
        pids = f.readlines
        abort "Daemon not running: #{name}" if pids.length < 1

        pids = pids.collect{|l| l.split.first}.join(' ')
        puts "#{Time.now.to_s} #{name} pids = ( #{pids} )"
    end
    sleep 60
end

# vim: set tabstop=4 shiftwidth=4 expandtab :
