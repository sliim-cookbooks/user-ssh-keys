use_inline_resources

action :create do
  username = new_resource.name

  user = PMSIpilot::SshKeys::User.normalize!(
      username,
      {
          :authorized_keys => new_resource.authorized_keys.dup,
          :authorized_users => new_resource.authorized_users.dup
      },
      Proc.new do |item|
        if new_resource.secret_file and ! new_resource.secret_file.empty?
          data_bag_item(new_resource.data_bag, item, Chef::EncryptedDataBagItem.load_secret(new_resource.secret_file))
        else
          data_bag_item(new_resource.data_bag, item)
        end
      end
  )

  directory "#{user[:home]}/.ssh" do
    owner username
    group username
    mode '0700'
    action :create

    not_if "test -e #{user[:home]}/.ssh"
  end

  user[:keys].each do |key|
    key = PMSIpilot::SshKeys::Key.normalize!(key)

    file "#{user[:home]}/.ssh/#{key['id']}.pub" do
      owner username
      group username
      mode '0600'
      content key['pub']
      not_if { key['pub'].empty? }
    end

    file "#{user[:home]}/.ssh/#{key['id']}" do
      owner username
      group username
      mode '0600'
      content key['priv'].kind_of?(Array) ? key['priv'].join("\n") : key['priv']
    end
  end

  template "#{user[:home]}/.ssh/authorized_keys" do
    cookbook 'user-ssh-keys'
    source 'authorized_keys.erb'
    cookbook 'user-ssh-keys'
    owner username
    group username
    mode '0600'
    variables keys: user[:authorized_keys]
    not_if { user[:authorized_keys].empty? }
  end
end
