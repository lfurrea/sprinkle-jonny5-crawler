#!/usr/bin/env sprinkle -c -s
#/ Usage 
#/
#/ This is how you do things 
require 'json'

$stderr.sync = true

%w(config couch_lib).each do |lib|
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
  runner "test -d #{KAZOO_DIR} && sudo tar -zcvf kazoo." + Time.now.to_s.gsub(':', '_').split("\s").join("_") + ".tar.gz #{KAZOO_DIR}", :sudo => true do
    pre :install, "echo Cowardly backing up #{KAZOO_DIR}... This will always run!"
  end
end

package :chown_beams do
  runner "chown -R #{USER}:#{GROUP} #{KAZOO_DIR}; echo done" do
  end
end

package :configure_crawler do
  crawler_keys = {'balance_crawler_enabled' => "#{CRAWLER_ENABLED}",
                   'balance_crawler_cycle_ms' => "#{CRAWLER_INTERVAL}",
                   'default_disconnect_active_calls' => "#{DISCONNECT_ACTIVE}",
                   'balance_crawler_interaccount_delay_ms' => "#{INTERACCOUNT_DELAY}",
                   'balance_crawler_delayed_hangup' => "#{DELAYED_HANGUP}"}
  conn = Couch::Server.new("#{COUCH_HOST}", "#{COUCH_PORT}")
  res_get = conn.get("/system_config/jonny5")
  jonny5_config = JSON.parse(res_get.body)
  update_doc = false
  crawler_keys.each_pair do |key, value|
    if jonny5_config["default"].has_key?(key) then
      unless jonny5_config["default"][key] == value
        update_doc = true
        jonny5_config["default"][key] = value
      end
    else
      update_doc = true
      jonny5_config["default"][key] = value
    end
  end

  if update_doc
    res_put = conn.put("/system_config/jonny5",JSON.generate(jonny5_config))
    puts res_put.body
  else
    puts 'Not Updating anything!'
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
