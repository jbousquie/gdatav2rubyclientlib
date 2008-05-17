require 'net/https'
require 'cgi'
require 'rexml/document'
include REXML


class GappApi
  #attr_reader :connexion, :token
  @@google_host = 'www.google.com'
  @@google_port = 443

  def initialize(proxy=nil, proxy_port=nil, proxy_user=nil, proxy_passwd=nil)

    conn = Net::HTTP.new(@@google_host, @@google_port, proxy, proxy_port, proxy_user, proxy_passwd)
    conn.use_ssl = true
    #conn.enable_post_connection_check=  true
    conn.verify_mode = OpenSSL::SSL::VERIFY_PEER
	store = OpenSSL::X509::Store.new
	store.set_default_paths
	conn.cert_store = store
	@connexion = conn
  end

  def login(domain, mail, passwd)
  	@domain_path = '/a/feeds/'+domain
  	@user_path = @domain_path+'/user/2.0'
  	@nickname_path = @domain_path+'/nickname/2.0'
  	@email_list_path = @domain_path+'/emailList/2.0'
	request_body = '&Email='+CGI.escape(mail)+'&Passwd='+CGI.escape(passwd)+'&accountType=HOSTED&service=apps'
    @connexion.start {|http|
        res = http.post('/accounts/ClientLogin',request_body,{'Content-Type'=>'application/x-www-form-urlencoded'})
        regexp = /^Auth=(.+)$/
        md =regexp.match(res.body)
        @headers = {'Content-Type'=>'application/atom+xml', 'Authorization'=> 'GoogleLogin auth='+$1}
		   }
  end
  
  def create_user (username, given_name, family_name, password, password_hash_function=nil, integer_quota_limit_in_MB=nil )
  end
  
  def retrieve_user (username)
  	user = @user_path+'/'+username
	@connexion.request_get(user, @headers)
  end

mezapps = GappApi.new()




