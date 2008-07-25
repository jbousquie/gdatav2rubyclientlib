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
	action[:subscription_retrieve] = {:method => 'GET', :path =>path_email_list+'/'}
	
	# special action "next" for linked feed results. :path will be affected with URL received in a link tag.
	action[:next] = {:method => 'GET', :path =>nil }
	return action  	
  end
  
  # Returns an UserEntry instance from an username
  # ex :	user = myapps.retrieve_user('jsmith')
  #		puts "givenName : "+user.given_name
  #		puts "familyName : "+user.family_name
  def retrieve_user(username)
	xml_response = request(:user_retrieve, username, @headers) 
	user_entry = UserEntry.new(xml_response.elements["entry"])
  end
 
  # Returns an UserEntry Array populated with all the users in the domain
  # ex : 	list= myapps.retrieve_all_users
  #		list.each{ |user| puts user.username} 
  #		puts 'nb users : ',list.size
  def retrieve_all_users
	response = request(:user_retrieve_all,nil,@headers)
	user_feed = Feed.new(response.elements["feed"],  UserEntry)
	user_feed = add_next_feeds(user_feed, response, UserEntry)
end

  # Returns an UserEntry Array populated with 100 users, starting from an username
  # ex : 	list= myapps.retrieve_page_of_users("jsmtih")
  #  		list.each{ |user| puts user.username}
  def retrieve_page_of_users(start_username)
	 param='?startUsername='+start_username
	response = request(:user_retrieve_all,param,@headers)
	user_feed = Feed.new(response.elements["feed"],  UserEntry)
  end



  # Returns a Nickname instance
  # ex : nick = myapps.retrieve('joe')
  #        puts nick.login 	=> jsmith
  def retrieve_nickname(nickname)
	  xml_response = request(:nickname_retrieve, nickname, @headers)
	  nickname_entry = NicknameEntry.new(xml_response.elements["entry"])
  end
  
  # Returns a Nickname object array from an username
  # ex : lists jsmith's nicknames
  #       mynicks = myapps.retrieve('jsmith')
  #       mynicks.each {|nick| puts nick.nickname }
  def retrieve_nicknames(username)
	  xml_response = request(:nickname_retrieve_all_for_user, username, @headers)
	  nicknames_feed = Feed.new(xml_response.elements["feed"],  NicknameEntry)
	  nicknames_feed = add_next_feeds(nicknames_feed, xml_response, NicknameEntry)
  end
  
  # Returns a Nickname object array for the whole domain
  # 	allnicks = myapps.retrieve_all_nicknames
  # 	allnicks.each {|nick| puts nick.nickname }
  def retrieve_all_nicknames
	  xml_response = request(:nickname_retrieve_all_in_domain, nil, @headers)
	  nicknames_feed = Feed.new(xml_response.elements["feed"],  NicknameEntry)
  	  nicknames_feed = add_next_feeds(nicknames_feed, xml_response, NicknameEntry)
  end
  
  # Returns an NicknameEntry Array populated with 100 nicknames, starting from an nickname
  # ex : 	list= myapps.retrieve_page_of_nicknames("joe")
  #  		list.each{ |nick| puts nick.login}
  def retrieve_page_of_nicknames(start_nickname)
	  param='?startNickname='+start_nickname
	  xml_response = request(:nickname_retrieve_all_in_domain, param, @headers)
	  nicknames_feed = Feed.new(xml_response.elements["feed"],  NicknameEntry)
  end
  
  # Returns an Email_list Array from an email adress
  # ex :	mylists = myapps.retrieve_email_lists('jsmith')   <= you could search from 'jsmith@mydomain.com' too 
  # 		mylists.each {|list| puts list.email_list }
  def retrieve_email_lists(email_adress)
	  xml_response = request(:email_list_retrieve_for_an_email, email_adress, @headers)
	  email_list_feed = Feed.new(xml_response.elements["feed"],  EmailListEntry) 
  	  email_list_feed = add_next_feeds(email_list_feed, xml_response, EmailListEntry)
  end	  
  
  # Returns an Email_list Array for the whole domain
  # ex :	all_lists = myapps.retrieve_all_email_lists
  # 		all_lists.each {|list| puts list.email_list }
  def retrieve_all_email_lists
	  xml_response = request(:email_list_retrieve_in_domain, nil, @headers)
	  email_list_feed = Feed.new(xml_response.elements["feed"],  EmailListEntry) 
    	  email_list_feed = add_next_feeds(email_list_feed, xml_response, EmailListEntry)
  end
  
  # Returns an EmailListEntry Array populated with 100 email lists, starting from an email list name
  # Startinf email list name must be written  as "mylist", not as "mylist@mydomain.com". Omit "@mydomaine.com".
  # ex : 	list= myapps.retrieve_page_of_email_lists("mylist") 
  #  		list.each{ |entry| puts entry.email_list}
  def retrieve_page_of_email_lists(start_listname)
	  param='?startEmailListName='+start_listname
	  xml_response = request(:email_list_retrieve_in_domain, param, @headers)
	  nicknames_feed = Feed.new(xml_response.elements["feed"],  EmailListEntry)
  end
  
  # Returns an Email_list_recipient Array from an email list
  # ex :	recipients = myapps.retrieve_all_recipients('mylist')  <= do not write "mylist@mydomain.com", write "mylist" only.
  # 		recipients.each {|recipient| puts recipient.email }
  def retrieve_all_recipients(email_list)
	  param = email_list+'/recipient/'
  	  xml_response = request(:subscription_retrieve, param, @headers)
	  email_list_recipient_feed = Feed.new(xml_response.elements["feed"],  EmailListRecipientEntry) 
	  email_list_recipient_feed = add_next_feeds(email_list_recipient_feed, xml_response, EmailListRecipientEntry)
  end
  
  # Returns an EmailListRecipientEntry Array populated with 100 recipients of an email list, starting from an recipient name
  # ex : 	list= myapps.retrieve_page_of_recipients('mylist', 'jsmith') 
  #  		list.each{ |recipient| puts recipient.email}
  def retrieve_page_of_recipients(email_list, start_recipient)
	   param = email_list+'/recipient/?startRecipient='+start_recipient
	  xml_response = request(:subscription_retrieve, param, @headers)
	  recipients_feed = Feed.new(xml_response.elements["feed"], EmailListRecipientEntry)
  end
  
  # protected methods
  protected
  
  # Sends credentials and returns an authentication token
  def login(mail, passwd)
	request_body = '&Email='+CGI.escape(mail)+'&Passwd='+CGI.escape(passwd)+'&accountType=HOSTED&service=apps'
	res = request(:domain_login, nil, {'Content-Type'=>'application/x-www-form-urlencoded'}, request_body)
	return /^Auth=(.+)$/.match(res.to_s)[1]
	# res.to_s needed, because res.class = REXML::Document
  end
  

 # Completes the feed by following et requesting the URL links
  def add_next_feeds(current_feed, xml_content,element_class)
	  xml_content.elements.each("feed/link") {|link|
		if link.attributes["rel"] == "next"
			@action[:next] = {:method => 'GET', :path=> link.attributes["href"]}
			next_response = request(:next,nil,@headers)
			current_feed.concat(Feed.new(next_response.elements["feed"], element_class))
			current_feed = add_next_feeds(current_feed, next_response, element_class)
			end
		}
	return current_feed
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

# EmailListRecipientEntry object 
class EmailListRecipientEntry 
  attr_reader :email
  # EmailListEntry constructor. Needs a REXML::Element "entry" as parameter
  def initialize(entry)
	@email = entry.elements["gd:who"].attributes["email"]
  end	
end

# UserFeed object : Array populated with Element_class objects
class Feed < Array
  # UserFeed constructor. Populates an array with Element_class objects. Each object is an xml "entry" parsed from the REXML::Element "feed".
  # Ex : user_feed = Feed.new(xml_feed, UserEntry)
  #	    nickname_feed = Feed.new(xml_feed, NicknameEntry
  def initialize(xml_feed, element_class)
	  xml_feed.elements.each("entry"){ |entry| self << element_class.new(entry) }
   end
   
end

class Request < Document
  # Request message constructor.
  # parameter type : "user", "nickname" or "emailList"  
  def initialize
	 super '<?xml version="1.0" encoding="UTF-8"?>' 
	 self.add_element "atom:entry"
	 self.elements["atom:entry"].add_element "atom:category", {"scheme" => "http://schemas.google.com/g/2005#kind"}
 end
 
  def add_path(url)
	 self.elements["atom:entry"].add_element "atom:id"
	 self.elements["atom:entry/atom:id"].text = url
 end
 
   def about_email_list(email_list)
     	 self.elements["atom:entry/atom:category"].add_attribute("term", "http://schemas.google.com/apps/2006#emailList")
	 self.elements["atom:entry"].add_element "apps:emailList", {"name" => email_list } 
  end
 
  # warning :  if valued admin, suspended, or change_passwd_at_next_login must be the STRINGS "true" or "false", not the boolean true or false
  def about_login(user_name, passwd=nil, hash_function_name=nil, admin=nil, suspended=nil, change_passwd_at_next_login=nil)
       	 self.elements["atom:entry/atom:category"].add_attribute("term", "http://schemas.google.com/apps/2006#user")
	 self.elements["atom:entry"].add_element "apps:login", {"userName", user_name } 
	 self.elements["atom:entry/apps:login"].add_attribute("password", passwd) if passwd
	 self.elements["atom:entry/apps:login"].add_attribute("hashFunctionName", hash_function_name) if hash_function_name
	 self.elements["atom:entry/apps:login"].add_attribute("admin", admin) if admin.nil?
	 self.elements["atom:entry/apps:login"].add_attribute("suspended", suspended) if not suspended.nil?
	 self.elements["atom:entry/apps:login"].add_attribute("changePasswordAtNextLogin", change_passwd_at_next_login) if change_passwd_at_next_login.nil?
  end

  
end
