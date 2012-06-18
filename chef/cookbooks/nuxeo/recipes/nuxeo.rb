require "etc"

running_user_name = ENV["SUDO_USER"] || ENV["USER"]


node["attributes"]["instances"].each do | id, instance |

    nuxeo_nxinstance "#{id}" do
        id          id
        user        instance["user"]
        group       instance["group"]
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

