require 'connection'
require 'rexml/document'
require 'cgi'
include REXML


class ProvisioningApi
  @@google_host = 'www.google.com'
  @@google_port = 443
  attr_reader :token



  def initialize(mail, passwd, proxy=nil, proxy_port=nil, proxy_user=nil, proxy_passwd=nil)
    domain = mail.split('@')[1]
    @action = setup_actions(domain)
  	conn = Connection.new(@@google_host, @@google_port, proxy, proxy_port, proxy_user, proxy_passwd)
  	@connection = conn
  	@token = login(mail, passwd)
	@headers = {'Content-Type'=>'application/atom+xml', 'Authorization'=> 'GoogleLogin auth='+token}
	return @connection
  end
  
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
  
  def retrieve_user(username)
	request(:user, :retrieve, username, @headers) 
  end
  
  def login(mail, passwd)
	request_body = '&Email='+CGI.escape(mail)+'&Passwd='+CGI.escape(passwd)+'&accountType=HOSTED&service=apps'
	res = request(:domain, :login, nil, {'Content-Type'=>'application/x-www-form-urlencoded'}, request_body)
	return /^Auth=(.+)$/.match(res.body)[1]
  end
  
  def request(object, action, value=nil, header=nil, message=nil)
  #param value : ce qui est concaténé au path de l'action ex: username
  	method = @action[object][action][:method]
  	value = '' if !value
  	path = @action[object][action][:path]+value
	@connection.perform(method, path, message, header)
  end

end


