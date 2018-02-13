node['user_ssh_keys']['users'].each do |username, user|
  user_ssh_keys_key username do
    authorized_keys user['authorized_keys']
    authorized_users user['authorized_users']
    data_bag node['user_ssh_keys']['data_bag']
    secret_file user['secret_file']
    action :create
  end
end
