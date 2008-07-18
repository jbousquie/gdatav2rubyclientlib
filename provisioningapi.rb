require 'connection'
require 'cgi'
require 'rexml/document'
include REXML


class ProvisioningApi
  @@google_host = 'www.google.com'
  @@google_port = 443
  attr_reader :token


  # Creates a new ProvisioningApi object
  # mail : Google Apps domain administrator e-mail (string)
  # passwd : Google Apps domain administrator password (string)
  # proxy : (optional) host name, or IP, of the proxy (string)
  # proxy_port : (optional) proxy port number (numeric)
  # proxy_user : (optional) login for authenticated proxy only (string)
  # proxy_passwd : (optional) password for authenticated proxy only (string)
  # The domain name is extracted from the mail param value.
  #
  # Examples
  # standard : no proxy
  # myapps = ProvisioningApi.new('root@mydomain.com','PaSsWoRd')
  # proxy :
  # myapps = ProvisioningApi.new('root@mydomain.com','PaSsWoRd','domain.proxy.com',8080)
  # authenticated proxy :
  # myapps = ProvisioningApi.new('root@mydomain.com','PaSsWoRd','domain.proxy.com',8080,'foo','bAr')
  def initialize(mail, passwd, proxy=nil, proxy_port=nil, proxy_user=nil, proxy_passwd=nil)
    domain = mail.split('@')[1]
    @action = setup_actions(domain)
  	conn = Connection.new(@@google_host, @@google_port, proxy, proxy_port, proxy_user, proxy_passwd)
  	@connection = conn
  	@token = login(mail, passwd)
	@headers = {'Content-Type'=>'application/atom+xml', 'Authorization'=> 'GoogleLogin auth='+token}
	return @connection
  end
  
  # Associates methods, http verbs and URL for REST access
  def setup_actions(domain)
	path = '/a/feeds/'+domain+'/user/2.0'
	action = Hash.new(Hash.new)
	action[:domain][:login] = {:method => 'POST', :path => '/accounts/ClientLogin' }
	action[:user][:create] = { :method => 'POST', :path => path }
	action[:user][:retrieve] = { :method => 'GET', :path => path+'/' }
	action[:user][:retrieve_all] = { :method => 'GET', :path => path } 
	action[:user][:update] = { :method => 'PUT', :path => path +'/' }
	return action  	
  end
  
  # Returns an UserEntry instance
  def retrieve_user(username)
	response = request(:user, :retrieve, username, @headers) 
	user_entry = UserEntry.new response.body
  end
  
  # Sends credentials and returns an authentication token
  def login(mail, passwd)
	request_body = '&Email='+CGI.escape(mail)+'&Passwd='+CGI.escape(passwd)+'&accountType=HOSTED&service=apps'
	res = request(:domain, :login, nil, {'Content-Type'=>'application/x-www-form-urlencoded'}, request_body)
	return /^Auth=(.+)$/.match(res.body)[1]
  end
  
  # Perfoms a REST request based on the action hash (cf setup_actions)
  # ex : request (:user, :retrieve, 'jsmith') sends an http GET www.google.com/a/feeds/domain/user/2.0/jsmith
  def request(object, action, value=nil, header=nil, message=nil)
  #param value : value to be concatenated to action path ex: GET host/path/value
  	method = @action[object][action][:method]
  	value = '' if !value
  	path = @action[object][action][:path]+value
	@connection.perform(method, path, message, header)
  end

end

# UserEntry object : Google REST API received response relative to an user
class UserEntry < Document
attr_reader :given_name, :family_name, :username, :suspended?, :ip_whitelisted?, :admin?, :change_password_at_next_login?, :agreed_to_terms? 
  def initialize
    super 
  	elements.each("entry/apps:name") { |element| @given_name = element.attributes["givenName"]
									@family_name = element.attributes["familyName"] }
  	elements.each("entry/apps:login"){ |element| @username = element.attributes["userName"]
									@suspended? = element.attributes["suspended"]
									@ip_whitelisted? =  element.attributes["ipWhitelisted"]
									@admin? = element.attributes["admin"]
									@change_password_at_next_login? = element.attributes["changePasswordAtNextLogin"]
									@agreed_to_terms? = element.attributes["agreedToTerms"]
									 }
  end
end


