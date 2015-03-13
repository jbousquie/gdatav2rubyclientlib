# Provisioning API v2.0  Ruby client library #

## NEW : [Ruby version 2.+  download](http://jerome.bousquie.fr/gappsprovisioning/v3/gappsprovisioning3.zip) !!! ##

Provisioning API v2.0  Ruby client library for Google Apps.
Based on [GData API v2.0](http://code.google.com/apis/apps/gdata_provisioning_api_v2.0_reference.html).

  * running even behind authenticated http proxies
  * using REXML (no extra module dependency)

Just uncompress the downloaded file in your working directory.


Ruby language : from version 1.8.6 patch-level 111
(just type ruby -v to check your version)

for Ruby version 2.+, please get the [new download](http://jerome.bousquie.fr/gappsprovisioning/v3/gappsprovisioning3.zip)

[On-line documentation](http://jerome.bousquie.fr/gappsprovisioning/doc/index.html)

Example :
```
     #!/usr/bin/ruby
     # require for Ruby 1.8.6+
     require 'gappsprovisioning/provisioningapi'

     # or require for Ruby 2.+
     # require 'path/to/your/gappsprovisioning_folder/provisioningapi'
     require './gappsprovisioning3/provisioningapi'


     include GAppsProvisioning
     adminuser = "root@mydomain.com"
     password  = "PaSsWo4d!"
     myapps = ProvisioningApi.new(adminuser,password)

     new_user = myapps.create_user("jsmith", "john", "smith", "secret", nil, "2048")
     puts new_user.family_name
     puts new_user.given_name
```
Want to update a user ?
```
     user = myapps.retrieve_user('jsmith')
     user_updated = myapps.update_user(user.username, user.given_name, user.family_name, nil, nil, "true")
```
Want to add an alias or nickname ?
```
     new_nickname = myapps.create_nickname("jsmith", "john.smith")
```
**NEW!!!**
Want to add an email forwarding _(thanks to Scott Jungling)_ ?
```
     new_forwarding = myapps.create_email_forwarding("jsmith", "brenda@yourdomain.com", "KEEP")
```

Want to manage groups ? (i.e. mailing lists)
```
     new_group = myapps.create_group("sales-dep", ['Sales Departement'])
     new_member = myapps.add_member_to_group("jsmith", "sales-dep")
     new_owner = myapps.add_owner_to_group("jsmith", "sales-dep")
     #     (ATTENTION: a owner is added only if it's already member of the group!)
```
Want to handle errors ?
```
     begin
             user = myapps.retrieve_user('noone')
             puts "givenName : "+user.given_name, "familyName : "+user.family_name, "username : "+user.username
             puts "admin ? : "+user.admin
     rescue GDataError => e
             puts "errorcode = "+e.code, "input : "+e.input, "reason : "+e.reason
     end
```
