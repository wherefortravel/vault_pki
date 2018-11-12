file '/tmp/hi' do
  content 'pretend this is a service restart'
  action :nothing
end

pki_certificate 'test' do
  common_name 'test.wherefor.com'
  private_key_path '/tmp/test.wherefor.com.key'
  certificate_path '/tmp/test.wherefor.com.crt'
  alt_names ['test2.wherefor.com','test3.wherefor.com']
  ip_sans ['127.0.0.1', node['ipaddress']]
  ttl_days 30
  notifies :create, 'file[/tmp/hi]'
end
