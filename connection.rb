require 'net/https'
require 'cgi'

class Connection
  attr_reader  :http_connection
  
  # Establishes SSL connection to Google host
  def initialize(host, port, proxy=nil, proxy_port=nil, proxy_user=nil, proxy_passwd=nil)
    conn = Net::HTTP.new(host, port, proxy, proxy_port, proxy_user, proxy_passwd)
    conn.use_ssl = true
    #conn.enable_post_connection_check=  true
    conn.verify_mode = OpenSSL::SSL::VERIFY_PEER
	store = OpenSSL::X509::Store.new
	store.set_default_paths
	conn.cert_store = store
	conn.start
	@http_connection = conn
  end
  
  def login(mail, passwd)
  # TODO : faire une remontée des URL dans la classe ProvisioningApi
	request_body = '&Email='+CGI.escape(mail)+'&Passwd='+CGI.escape(passwd)+'&accountType=HOSTED&service=apps'
    res = @http_connection.post('/accounts/ClientLogin',request_body,{'Content-Type'=>'application/x-www-form-urlencoded'})
    return /^Auth=(.+)$/.match(res.body)[1]
  end
  
  def perform(method, path, body=nil, header=nil)
  	req = Net::HTTPGenericRequest.new(method, !body.nil?, true, path)
  	req['Content-Type'] = header['Content-Type'] if header['Content-Type']
  	req['Authorization'] = header['Authorization'] if header['Authorization']
  	req['Content-length'] = body.length.to_s if body
	resp = @http_connection.request(req, body)
	return resp
  end
  
end