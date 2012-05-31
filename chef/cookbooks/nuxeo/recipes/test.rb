
node["attributes"]["instances"].each do | id, instance |

    running_user = ENV["SUDO_USER"] ||= ENV["USER"]

    nuxeo_nxuser "#{id}" do
        username    instance["user"] ||= running_user
        action      :create
    end

    nuxeo_nxinstance "#{id}" do
        user        instance["user"] ||= running_user
        home        instance["home"] ||= "/home/#{id}"
        platform     "cap-5.5"
        action      :create
    end

end

#nuxeo_nxinstance "same one" do
#    username    "nxtest"
#    action      :delete
#end
