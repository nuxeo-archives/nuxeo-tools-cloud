require "etc"

action :create do

    new_user = false
    begin
        user_info = Etc.getpwnam(@new_resource.username)
    rescue
        new_user = true
    end

    group "nxgroup" do
        only_if { new_user == true }
        group_name "#{new_resource.username}"
    end

    user "nxuser" do
        only_if { new_user == true }
        username "#{new_resource.username}"
        comment "Nuxeo Instance"
        home    "#{new_resource.home}"
        gid     "#{new_resource.username}"
        shell   "/bin/bash"
    end

    directory "nxhome" do
        path    "#{new_resource.home}"
        owner   "#{new_resource.username}"
        mode    "0700"
        recursive true
        action  :create
    end

end


action :delete do

    user_exists = true
    begin
        user_info = Etc.getpwnam(@new_resource.username)
    rescue
        user_exists = false
    end

    execute "process cleanup" do
        only_if { user_exists == true }
        command "pkill -9 -u #{new_resource.username}"
        returns [0, 1]
    end

    directory "nxhome" do
        path    "#{new_resource.home}"
        recursive true
        action :delete
    end

    user "nxuser" do
        username "#{new_resource.username}"
        action :remove
    end

end

