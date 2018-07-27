local_mode true
chef_repo_path   File.expand_path('../' , __FILE__)
use_policyfile true
versioned_cookbooks true
policy_document_native_api false
knife[:before_bootstrap] = 'chef update && chef export ./ -f'
knife[:before_converge]  = 'chef update && chef export ./ -f'

knife[:ssh_attribute] = "knife_zero.host"
knife[:use_sudo] = true

# knife[:listen] = false

## use specific key file to connect server instead of ssh_agent(use ssh_agent is set true by default).
# knife[:identity_file] = "~/.ssh/id_rsa"

## Attributes of node objects will be saved to json file.
## the automatic_attribute_whitelist option limits the attributes to be saved.
knife[:automatic_attribute_whitelist] = %w[
  fqdn
  os
  os_version
  hostname
  ipaddress
  roles
  recipes
  ipaddress
  platform
  platform_version
  cloud
  cloud_v2
  chef_packages
]
