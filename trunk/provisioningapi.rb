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
	path_user = '/a/feeds/'+domain+'/user/2.0'
	path_nickname = '/a/feeds/'+domain+'/nickname/2.0'
	path_email_list = '/a/feeds/'+domain+'/emailList/2.0'
	action = Hash.new
	action[:domain_login] = {:method => 'POST', :path => '/accounts/ClientLogin' }
	action[:user_create] = { :method => 'POST', :path => path_user }
	action[:user_retrieve] = { :method => 'GET', :path => path_user+'/' }
	action[:user_retrieve_all] = { :method => 'GET', :path => path_user } 
	action[:user_update] = { :method => 'PUT', :path => path_user +'/' }
	action[:user_delete] = { :method => 'DELETE', :path => path_user +'/' }
	action[:nickname_create] = { :method => 'POST', :path =>path_nickname }
	action[:nickname_retrieve] = { :method => 'GET', :path =>path_nickname+'/' }
	action[:nickname_retrieve_all_for_user] = { :method => 'GET', :path =>path_nickname+'?username=' }
	action[:nickname_retrieve_all_in_domain] = { :method => 'GET', :path =>path_nickname }
	action[:nickname_delete] = { :method => 'DELETE', :path =>path_nickname+'/' }
	action[:email_list_retrieve_for_an_email] = { :method => 'GET', :path =>path_email_list+'?recipient=' }
	action[:email_list_retrieve_in_domain] = { :method => 'GET', :path =>path_email_list }
	return action  	
  end
  
  # Returns an UserEntry instance
  def retrieve_user(username)
	xml_response = request(:user_retrieve, username, @headers) 
	user_entry = UserEntry.new(xml_response.elements["entry"])
  end

def retrieve_all_users
	response = request(:user_retrieve_all,nil,@headers)
	user_feed = Feed.new(response.elements["feed"], UserEntry)
end

  # Returns an Nickname instance
  def retrieve_nickname(nickname)
	  xml_response = request(:nickname_retrieve, nickname, @headers)
	  nickname_entry = NicknameEntry.new(xml_response.elements["entry"])
  end
  
  def retrieve_nicknames(username)
	  xml_response = request(:nickname_retrieve_all_for_user, username, @headers)
	  nicknames_feed = Feed.new(xml_response.elements["feed"], NicknameEntry)
  end
  
  def retrieve_all_nicknames
	  xml_response = request(:nickname_retrieve_all_in_domain, nil, @headers)
	  nicknames_feed = Feed.new(xml_response.elements["feed"], NicknameEntry)
  end
  
  def retrieve_email_lists(email_adress)
	  xml_response = request(:email_list_retrieve_for_an_email, email_adress, @headers)
	  nicknames_feed = Feed.new(xml_response.elements["feed"], EmailListEntry) 
  end	  

  def retrieve_all_email_lists
	  xml_response = request(:email_list_retrieve_in_domain, nil, @headers)
	  nicknames_feed = Feed.new(xml_response.elements["feed"], EmailListEntry) 
  end
  
  # Sends credentials and returns an authentication token
  def login(mail, passwd)
	request_body = '&Email='+CGI.escape(mail)+'&Passwd='+CGI.escape(passwd)+'&accountType=HOSTED&service=apps'
	res = request(:domain_login, nil, {'Content-Type'=>'application/x-www-form-urlencoded'}, request_body)
	return /^Auth=(.+)$/.match(res.to_s)[1]
	# res.to_s needed, because res.class = REXML::Document
  end
  
  # Perfoms a REST request based on the action hash (cf setup_actions)
  # ex : request (:user_retrieve, 'jsmith') sends an http GET www.google.com/a/feeds/domain/user/2.0/jsmith
  # returns  REXML Document
  def request(action, value=nil, header=nil, message=nil)
  #param value : value to be concatenated to action path ex: GET host/path/value
  	method = @action[action][:method]
  	value = '' if !value
  	path = @action[action][:path]+value
	response = @connection.perform(method, path, message, header)
	return Document.new(response.body)
  end

end

# UserEntry object
class UserEntry 
attr_reader :given_name, :family_name, :username, :suspended, :ip_whitelisted, :admin, :change_password_at_next_login, :agreed_to_terms, :quota_limit
  # UserEntry constructor. Needs a REXML::Element "entry" as parameter
  def initialize(entry)
	@family_name = entry.elements["apps:name"].attributes["familyName"]
	@given_name = entry.elements["apps:name"].attributes["givenName"]
	@username = entry.elements["apps:login"].attributes["userName"]
	@suspended = entry.elements["apps:login"].attributes["suspended"]
	@ip_whitelisted = entry.elements["apps:login"].attributes["ipWhitelisted"]
	@admin = entry.elements["apps:login"].attributes["admin"]
	@change_password_at_next_login = entry.elements["apps:login"].attributes["changePasswordAtNextLogin"]
	@agreed_to_terms = entry.elements["apps:login"].attributes["agreedToTerms"]
	@quota_limit = entry.elements["apps:quota"].attributes["limit"]
  end

end


# NicknameEntry object 
class NicknameEntry 
  attr_reader :login, :nickname
  # NicknameEntry constructor. Needs a REXML::Element "entry" as parameter
  def initialize(entry)
	@login = entry.elements["apps:login"].attributes["userName"]
	@nickname = entry.elements["apps:nickname"].attributes["name"]
  end	
end

# EmailListEntry object 
class EmailListEntry 
  attr_reader :email_list
  # EmailListEntry constructor. Needs a REXML::Element "entry" as parameter
  def initialize(entry)
	@email_list = entry.elements["apps:emailList"].attributes["name"]
  end	
end

# UserFeed object : Array populated with UserEntry objects
class Feed < Array
  # UserFeed constructor. Populates an array with Entry_class objects. Each object is an xml "entry" parsed from the REXML::Element "feed".
  def initialize(feed, entry_class)
	   feed.elements.each("entry"){ |entry| self << entry_class.new(entry) }
  end
end