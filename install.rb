#!/usr/bin/env sprinkle -c -s
#/ Usage 
#/
#/ This is how you do things 

$stderr.sync = true

%w(config).each do |lib|
  require_relative lib
end

file = __FILE__

package :install_beams do
  binary "#{PACKAGE_URL}" do
    prefix   "#{KAZOO_DIR}"
    archives "/tmp"
  end 
end

package :backup_kazoo_dir do
  runner "test -d #{KAZOO_DIR} && sudo tar -zcvf kazoo-config." + Time.now.to_s.gsub(':', '_').split("\s").join("_") + ".tar.gz #{KAZOO_DIR}", :sudo => true do
    pre :install, "echo Cowardly backing up #{KAZOO_DIR}... This will always run!"
  end
end

package :chown_beams do
  runner "chown -R #{USER}:#{GROUP} #{KAZOO_DIR}; echo done" do
  end
end

policy :jonny5_crawler, :roles => :apps do
  requires :backup_kazoo_dir
  requires :install_beams
  requires :chown_beams
end

deployment do
  delivery :capistrano do
    begin
      recipes 'Capfile'
    rescue LoadError
      recipes 'deploy'
    end    
  end
end
