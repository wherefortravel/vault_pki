include PkiCookbook::PkiHelpers::Base

property :common_name, String, required: true
property :private_key_path, String, required: true
property :certificate_path, String, required: true
property :alt_names, Array, default: []
property :ip_sans, Array, default: []
property :ttl_days, Integer, default: 365
property :reissue_within_days, Integer, default: 15, desired_state: false
property :force_issue, [true, false], default: false

def should_issue?
  return [true, "issuing because :force_issue is true"] if force_issue
  return [true, "issuing because no cert at :certificate_path (#{certificate_path}) exists"] if ! ::File.exist?(certificate_path)
  cert = OpenSSL::X509::Certificate.new ::File.read certificate_path
  not_after = cert.not_after
  days_until_expiry = (not_after - Time.now.utc()) / (60 * 60 * 24)
  return [true, "reissuing because cert is set to expire within :reissue_within_days (#{reissue_within_days}) (expires in #{days_until_expiry})"] if days_until_expiry < reissue_within_days
  return [false, '']
end

load_current_value do |desired|
  if ::File.exist?(desired.certificate_path)
    cert = OpenSSL::X509::Certificate.new ::File.read desired.certificate_path
    cert_common_name = cert.subject.to_s(OpenSSL::X509::Name::COMPAT).split('=')[1]
    common_name cert_common_name
    _alt_names = Array.new
    _ip_sans = Array.new
    cert.extensions.each do |ext|
      if ext.oid().to_s == "subjectAltName"
        # "subjectAltName = DNS:test.wherefor.com, DNS:test2.wherefor.com, DNS:test3.wherefor.com, IP Address:127.0.0.1, IP Address:127.0.0.2"
        ext.to_s.split('=')[1].split(',').each do |name|
          type = name.split(':')[0]
          value = name.split(':')[1]
          if type.strip == "DNS"
            _alt_names.push(value)
          elsif type.strip == "IP Address"
            _ip_sans.push(value)
          end
          alt_names _alt_names.sort - [desired.common_name, cert_common_name]
          ip_sans _ip_sans.sort
        end
      end
    end
  else
    common_name ''
  end
end

action :issue do
  issuing, reason = should_issue?
  if issuing
    converge_by reason do
      issue_cert
    end
  else
    converge_if_changed :common_name,:alt_names,:ip_sans do
      issue_cert
    end
  end
end

action_class do
  def issue_cert
    vault_creds = data_bag_item('vault', 'chef-approle')
    vault = Vault::Client.new(
      address: "https://vault.service.aws.w2:8200",
      token: vault_creds['token'],
      ssl_ca_cert: '/usr/local/share/ca-certificates/pki.wherefor.com.crt'
    )
    secret_id = vault.approle.create_secret_id('chef-pki').data[:secret_id]
    vault.auth.approle(vault_creds['role_id'], secret_id)
    secret = vault.logical.write(
      'pki/issue/chef',
      common_name: new_resource.common_name,
      alt_names: new_resource.alt_names.join(',').strip().chomp(','),
      ip_sans: new_resource.ip_sans.sort.join(',').strip().chomp(','),
      ttl: (new_resource.ttl_days * 24).to_s + 'h'
    )
    file new_resource.private_key_path do
      content "#{secret.data[:private_key]}"
      sensitive true
    end
    file new_resource.certificate_path do
      content "#{secret.data[:certificate]}"
      sensitive true
    end
  end
end
