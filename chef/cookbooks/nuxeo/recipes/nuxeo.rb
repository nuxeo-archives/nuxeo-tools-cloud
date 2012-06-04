require "etc"

running_user_name = ENV["SUDO_USER"] || ENV["USER"]


node["attributes"]["instances"].each do | id, instance |

    new_user_name = instance["user"] || running_user_name
    new_user_home = instance["basedir"] || "/home/#{new_user_name}" # Is there a system-independant way to get "/home" ?
    new_group_name = instance["group"] || new_user_name

    user_exists = true
    begin
        user_info = Etc.getpwnam(new_user_name)
    rescue
        user_exists = false
    end

    new_group = group "newgroup" do
        not_if      {user_exists == true}
        group_name  new_group_name
        action      :nothing
    end

    new_user = user "newuser" do
        not_if      {user_exists == true}
        username    new_user_name
        gid         new_group_name
        comment     "Nuxeo Instance"
        home        new_user_home
        shell       "/bin/bash"
        action      :nothing
    end

    if user_exists == false then
        new_group.run_action(:create)
        new_user.run_action(:create)
    end

    user_info = Etc.getpwnam(new_user_name)
    group_info = Etc.getgrgid(user_info.gid)
    username = new_user_name
    groupname = group_info.name

    nuxeo_nxinstance "#{id}" do
        id          id
        user        username
        group       groupname
        basedir     instance["basedir"] ||= nil
        distrib     instance["distrib"] ||= "cap-5.5"
        clid        instance["clid"] ||= nil
        dbtemplate  instance["dbtemplate"]      # String
        basetemplates instance["basetemplates"] # Array
        nuxeoconf   instance["nuxeoconf"]       # Hash
        packages    instance["packages"]        # Hash (id => version)
        action      :create
    end

end

