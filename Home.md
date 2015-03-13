# Ruby Client Library for Google Apps Provisioning API #

[On-line documentation](http://www.iut-rodez.fr/gappsprovisioning/doc/)

## Tip for Rails integration ##
_(thanks to [professor](http://code.google.com/u/professor/))_

  1. install zip in the lib/ directory
  1. create a config/google\_apps.yml file like this
```
development:
  username: XXX
  password: XXX
  google_domain: XXX
```
  1. create a config/initializers/google\_apps.rb which does the following...
```
GOOGLE_APPS_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/google_apps.yml")[RAILS_ENV]

require 'gappsprovisioning/provisioningapi'
include GAppsProvisioning
def google_apps_connection
  @google_apps_connection ||= ProvisioningApi.new(GOOGLE_APPS_CONFIG['username'], 
GOOGLE_APPS_CONFIG['password'])
rescue
  Rails.logger.debug "had to rescue (ie reconnect) google apps"
  @google_apps_connection = ProvisioningApi.new(GOOGLE_APPS_CONFIG['username'], 
GOOGLE_APPS_CONFIG['password'])
end
```
## Tip for JRuby ##

install jruby-openssl and declares where to find certs files:
```
jruby -S gem install jruby-openssl
export SSL_CERT_DIR=/etc/ssl/certs/   (for example on Ubuntu)
```
then run your script as in MRI :
```
jruby myscript_using_clientlib.rb
```
## Changelog ##

release 1.2.0
  * Added renaming username
  * Email list methods deprecated
  * online and embedded documentations updated

release 1.1.0
  * Added group management (thanks to Roberto Cerigato)
  * online documentation updated

release 1.0.3
  * target URL 'www.google.com' changed to 'apps-apis.google.com' for the @@google\_host class var, according to http://code.google.com/apis/apps/gdata_provisioning_api_v2.0_reference.html

release 1.0.2
  * some english errors fixed in the documentation
> CAUTION : a wrong package was uploaded for this version. If you download it from the Download tab, please rename your 'gdatav2rubyclientlib' directory after unziping to 'gappsprovisioning'.


release 1.0.1
  * added commented line in connection.rb : connection with no certificate checking allowed