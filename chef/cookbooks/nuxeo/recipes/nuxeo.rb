
node["attributes"]["instances"].each do | id, instance |

    running_user_name = ENV["SUDO_USER"] ||= ENV["USER"]
    running_user_uid = Etc.getpwnam(running_user_name).uid
    running_user_gid = Etc.getpwnam(running_user_name).gid
    running_user_home = Etc.getpwnam(running_user_name).dir
    running_group_name = Etc.getgrgid(running_user_gid).name

    nuxeo_nxuser "#{id}" do
        username    instance["user"] ||= running_user_name
        action      :create
    end

    nuxeo_nxinstance "#{id}" do
        user        instance["user"] ||= running_user_name
        group       instance["group"] ||= running_group_name
        home        instance["home"] ||= ::File.join(running_user_home, "nxinstance-#{id}")
        platform    instance["targetplatform"] ||=  "cap-5.5"
        action      :create
    end

end

#nuxeo_nxinstance "same one" do
#    username    "nxtest"
#    action      :delete
#end
