# this will be nil when first provisioning a builder. after the manual generation of
# the origin and the hab access token you can put the value of the hab access token in this attribute
default['builder']['origin']['core']['access_token'] = nil 

# Customer requirement:
# the user and group to run habitat and its services
# When used at the customer site this will be a user
# from Active Directory - also setting a flag to
# create the user and group for testing
default['builder']['create_user_and_group'] = false
default['builder']['hab_user'] = 'sysbukdevopshabitat'
default['builder']['hab_user_group'] = 'sysbukdevopshabitat'

# set up a list of our artifacts and where to get them from
# internal_repo: base url of a s3,webserver,nexus,artifactory or other file store
# archive_file_name: the name of the remote file that contains the builder hab pkgs and
# the hab supervisor packages and the install script
# core_bootstrap_file_name: the name of the file that contains
# the set of packages that make up the core repo (or a subset for jboss/tomcat/jdk)
default['builder']['internal_repo'] = ''
# the version numbers are not related to the habitat pkgs but rather to the script used
# to package them. Used to track the structure changes of the bundle archive
# once a formal structure is agreed we can drop the version
# current structure:
# ./harts/<all the hart files of the required services and dependencies>
# ./keys/<all of the public keys from the services origins and dependent origins>
# ./bin/hab - if the hab cli is needed for bootstrapping - builder bundle only
# ./install.sh - needed if bootstrapping the builder otherwise not included
default['builder']['archive_file_name'] = 'on-prem-builder-bundle-v0.5.8.tar.gz'
default['builder']['archive_file_sha256sum'] = 'ae998fd5d1467931b7a64573bb79d9a6e577b9674043aeb7b7fb1c00523981e6'
# normally this would be the entire contnent of the habitat core origin, to save
# time I am just using a bundle of tomcat and it dependencies 
# the structure of these files is as follows:
# ./harts/<all the hart files for an origin such as core>
# ./keys/<all the keys for that origin>
default['builder']['core_bootstrap_file_name'] = 'tomcat-bundle-v0.2.0.tar.gz'
default['builder']['core_bootstrap_file_sha256sum'] = '402ca2bebfc46fc4caf760eb926831df92d711524a8db3e3e94e18eb3c6187a2' # 170mb tomcat/java based bundle
# default['builder']['core_bootstrap_file_sha256sum'] = '488fdb22e2cc5fed7a56cc76ccb471f2bff1587d9d1fc7b1c8b81223daac6b5d' # checksum for the 10gb core packages file

default['builder']['archive_url'] =
  "#{node['builder']['internal_repo']}/#{node['builder']['archive_file_name']}"

default['builder']['core_bootstrap_url'] =
  "#{node['builder']['internal_repo']}/#{node['builder']['core_bootstrap_file_name']}"

default['builder']['archive_path'] = "#{Chef::Config[:file_cache_path]}/on-prem-builder.tar.gz"
default['builder']['core_bootstrap_path'] = "#{Chef::Config[:file_cache_path]}/hab-core-packages.tar.gz"

default['builder']['archive_extract_path'] = "#{Chef::Config[:file_cache_path]}/builder_bootstap_files"
default['builder']['core_extract_path'] = "#{Chef::Config[:file_cache_path]}/core_packages_bootstap_files"
default['builder']['populate_lock_file'] = '/root/builder_populate_lock_file'

# examples for oauthing with chef-automate
# for bitbicket examples see .kitchen.example
default['builder']['oauth'] = {
  'provider' => 'chef-automate',
  'authorize_url' => 'https://automate.sb.success.chef.co/session/new',
  'builder_url' => 'http://builder.sb.success.chef.co',
  'redirect_url' => 'http://builder.sb.success.chef.co/',
  'token_url' => 'https://automate.sb.success.chef.co/session/token',
  'userinfo_url' =>  'https://automate.sb.success.chef.co/session/userinfo',
  'client_id' => 'bcbd159916107c3c858bbdc5020b115e',
  'client_secret' => '5c2c81cce4e5ee8dd8caaa435c492b42',
}

default['builder']['s3'] = {
  'backend' => 'minio',
  'key_id' => 'depot',
  'secret_key' => 'password',
  'endpoint' => 'http://localhost:9000',
  'bucket_name' => 'habitat-builder-artifact-store.local',
}

default['builder']['svc']['builder_memcached'] = {
  'user_dir' => '/hab/user/builder-memcached/config/',
  'pkg' => 'devoptimist/builder-memcached',
  'args' => '--channel on-prem-builder --force',
}

default['builder']['svc']['builder_minio'] = {
  'user_dir' => '/hab/user/builder-minio/config/',
  'pkg' => 'devoptimist/builder-minio',
  'args' => '--channel on-prem-builder --force',
}

default['builder']['svc']['builder_api'] = {
  'user_dir' => '/hab/user/builder-api/config/',
  'pkg' => 'devoptimist/builder-api',
  'args' => '--bind memcached:builder-memcached.default \
--bind datastore:builder-datastore.default \
--channel on-prem-builder --force',
}

default['builder']['svc']['builder_api_proxy'] = {
  'user_dir' => '/hab/user/builder-api-proxy/config/',
  'pkg' => 'devoptimist/builder-api-proxy',
  'args' => '--bind http:builder-api.default --channel on-prem-builder --force',
  'http_port' => 8081,
}

default['builder']['svc']['builder_datastore'] = {
  'user_dir' => '/hab/user/builder-datastore/config/',
  'pkg' => 'devoptimist/builder-datastore',
  'args' => '--channel on-prem-builder --force',
}
