name 'maas_with_zero'
default_source :supermarket
default_source :chef_repo, 'cookbooks' do |s|
  s.preferred_for 'base'
  s.preferred_for 'maaster'
end
run_list 'base', 'maaster'
