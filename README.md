# pki

Vault PKI certificate Issue resource

NOTE: In all examples, etc, where you see wherefor.com, you'll
need to change to your own domains, etc.  

Also the role used to talk to vault will need to be customized for your
setup.<br/>
recipes/example.rb:  common_name 'test.wherefor.com'<br/>
  recipes/example.rb:  private_key_path '/tmp/test.wherefor.com.key'<br/>
  recipes/example.rb:  certificate_path '/tmp/test.wherefor.com.crt'<br/>
  recipes/example.rb:  alt_names ['test2.wherefor.com','test3.wherefor.com']<br/>
  resources/certificate.rb:        # "subjectAltName = DNS:test.wherefor.com, DNS:test2.wherefor.com, DNS:test3.wherefor.com, IP Address:127.0.0.1, IP Address:127.0.0.2"<br/>


  the below is our root certificate for validation of the vault SSL endpoint cert<br/>
  resources/certificate.rb:      ssl_ca_cert: '/usr/local/share/ca-certificates/pki.wherefor.com.crt'<br/><br/>


  the below line needs to point to YOUR vault server<br/>
  resources/certificate.rb:      address: "https://vault.service.aws.w2:8200",<br/><br/>


  this is our chef AppRole issue endpoint:<br/>
  resources/certificate.rb:      'pki/issue/chef',<br/>
