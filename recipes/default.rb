#
# Cookbook:: builder
# Recipe:: default
#
# Copyright:: 2018, Steve Brown, sbrown@chef.io
extend Builder::HabHelpers

user node['builder']['hab_user'] do
  only_if node['builder']['hab_user_and_group']
end

directory node['builder']['archive_extract_path'] do
  recursive true 
#  owner node['builder']['hab_user']
#  group node['builder']['hab_user_group']
end

remote_file node['builder']['archive_path'] do
  source node['builder']['archive_url']
#  owner node['builder']['hab_user']
#  group node['builder']['hab_user_group']
  checksum node['builder']['archive_file_sha256sum']
end

execute 'extract_on_prem_archive' do
  command "tar xzf #{node['builder']['archive_path']} -C #{node['builder']['archive_extract_path']}"
  creates "#{node['builder']['archive_extract_path']}/harts"
#  user node['builder']['hab_user']
end

execute 'install_on_prem_builder' do
  command './install.sh'
  cwd node['builder']['archive_extract_path']
  not_if { ::File.directory?('/hab/pkgs') }
#  notifies :run, 'execute[change_ownership_of_hab_dir]', :immediately
end

#execute 'change_ownership_of_hab_dir' do
#  command "chown -R #{node['builder']['hab_user']}:#{node['builder']['hab_user_group']} /hab"
#end

# Creating the user.toml directorys for each service
# note: the on-prem-builder repo puts them in 
# /hab/svc/<service-name>/ https://github.com/habitat-sh/on-prem-builder/blob/master/scripts/provision.sh#L60
# this is deprecated so we create them in /hab/user/<service-name>/config/
node['builder']['svc'].each do |_name, params|
  directory params['user_dir'] do
    owner node['builder']['hab_user']
    group node['builder']['hab_user_group']
    recursive true
  end
end

# Note 1: The customer wants to be able to run the supervisor as
# a non root user - (we may want to revisit this decision with them)
# Note 2: The ca cert file below contains the root CA's. If you are using
# Automate 2 as an oauth provider, then load balancer certificate from the A2
# server (normaly found at /hab/svc/automate-load-balancer/data/<a2server-fqdn.cert>
# will need to be appended to this file
systemd_unit 'hab-sup.service' do
  extend Builder::HabHelpers
  content lazy {
    {
      'Unit' => {
        'Description' => 'The Habitat Supervisor',
      },
      'Service' => {
        'ExecStart' => '/bin/hab sup run --channel on-prem-builder',
        'Environment' => "SSL_CERT_FILE=#{hab_pkg_path('core/cacerts')}/ssl/cert.pem",
        'Restart' => 'on-failure',
        'User' => 'root',
        'Group' => 'root',
      }.compact,
      'Install' => {
        'WantedBy' => 'default.target',
      },
    }
  }
  action :create
end

service 'hab-sup' do
  action [:start, :enable]
#  notifies :run, 'execute[wait_for_supervisor_start]', :immediately
end

#execute 'wait_for_supervisor_start' do
#  command 'sleep 10'
#  action :nothing
#end

# We need to start the data store service first. As part of its
# init hoook it creates a database password file that is then used
# by the builder-api service
ds_service = node['builder']['svc'].select { |k| k == 'builder_datastore' }
other_services = node['builder']['svc'].reject { |k| k == 'builder_datastore' }

ds_service.each do |name, params|
  template "#{params['user_dir']}/user.toml" do
    source "#{name}_user.toml.erb"
    owner node['builder']['hab_user']
    group node['builder']['hab_user_group']
  end

# TODO: this 'not_if' is probably not ideal
# need to fix so it works in all situations
 execute "start_#{name}" do
    extend Builder::HabHelpers
    command "hab svc load #{params['pkg']} #{params['args']}"
#    user node['builder']['hab_user']
    not_if { hab_svc_running?(params['pkg']) }
  end
end

other_services.each do |name, params|
  template "#{params['user_dir']}/user.toml" do
    helpers(Builder::FsHelpers)
    source "#{name}_user.toml.erb"
    owner node['builder']['hab_user']
    group node['builder']['hab_user_group']
  end

# TODO: this 'not_if' is probably not ideal
# need to fix so it works in all situations
  execute "start_#{name}" do
    extend Builder::HabHelpers
    command "hab svc load #{params['pkg']} #{params['args']}"
#    user node['builder']['hab_user']
    not_if { hab_svc_running?(params['pkg']) }
  end
end

template '/usr/local/bin/generate_bldr_keys.sh' do
  source 'generate_bldr_keys.sh.erb'
  mode '0744'
end

execute 'generate_bldr_keys' do
  command '/usr/local/bin/generate_bldr_keys.sh'
  not_if 'ls /hab/cache/keys/bldr-*.pub'
end

# This is the collection of packages and keys making up the
# core origin; for testing we are just using a subset of packages
# for tomcat / jboss
remote_file node['builder']['core_bootstrap_path'] do
  source node['builder']['core_bootstrap_url']
  owner node['builder']['hab_user']
  group node['builder']['hab_user_group']
  checksum node['builder']['core_bootstrap_file_sha256sum']
end

if node['builder']['origin']['core']['access_token']
# This template is a combination of install scripts from 
# the on-prem-builder repo
  template '/usr/local/bin/builder_populate.sh' do
    source 'builder_populate.sh.erb'
    mode '0744'
  end

# TODO: We can probably get rid of the lock file
# when we know the api call to check the core
# origin for keys and packages
  execute 'builder_populate' do
    command '/usr/local/bin/builder_populate.sh'
    timeout 10800 # the import can take a long time, trying 3 hours
    not_if { ::File.file?(node['builder']['populate_lock_file']) }
  end

end
