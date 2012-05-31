require "etc"

action :create do

    user_exists = true
    begin
        user_info = Etc.getpwnam(@new_resource.username)
    rescue
        user_exists = false
    end

    user_home = @new_resource.home
    user_home = user_home ||= "/home/#{new_resource.username}"

    user "#{new_resource.username}" do
        not_if      { user_exists == true }
        username    "#{new_resource.username}"
        comment     "Nuxeo Instance"
        home        user_home
        shell       "/bin/bash"
    end

end


action :delete do

    user_exists = true
    begin
        user_info = Etc.getpwnam(@new_resource.username)
    rescue
        user_exists = false
    end

    guarded_user = false
    if "#{new_resource.username}" == "root"
        guarded_user = true
    elsif "#{new_resource.username}" == ENV["USER"]
        guarded_user = true
    elsif "#{new_resource.username}" == ENV["SUDO_USER"]
        guarded_user = true
    end

    execute "process cleanup" do
        only_if     { user_exists == true }
        only_if     { guarded_user == false }
        command     "pkill -9 -u #{new_resource.username}"
        returns     [0, 1]
    end

    user "#{new_resource.username}" do
        only_if     { user_exists == true }
        only_if     { guarded_user == false }
        username    "#{new_resource.username}"
        action      :remove
    end

end

