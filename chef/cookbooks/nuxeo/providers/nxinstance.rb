
action :create do

    # code outside blocks is always executed first
    url = "#{node["distributions"]["#{new_resource.platform}"]["url"]}"
    filename = "/tmp/#{node["distributions"]["#{new_resource.platform}"]["filename"]}"
    dirname = "#{node["distributions"]["#{new_resource.platform}"]["dirname"]}"
    sha256sum = "#{node["distributions"]["#{new_resource.platform}"]["sha256sum"]}"

    remote_file "nxarchive" do
        source  "#{url}"
        path    "#{filename}"
        checksum "#{sha256sum}"
        mode    "0644"
        action  :create_if_missing
    end

    directory "nxhome" do
        path    "#{new_resource.home}"
        owner   "#{new_resource.user}"
        mode    "0700"
        action  :create
    end

    execute "unzip" do
        command "unzip -q #{filename}"
        creates "#{new_resource.home}/#{dirname}"
        cwd     "#{new_resource.home}"
        user    "#{new_resource.user}"
        umask   0077
    end

    # umask isn't working with unzip
    execute "chown" do
        command "chmod -R og-rwx #{dirname}"
        cwd     "#{new_resource.home}"
        user    "#{new_resource.user}"
    end

    link "server" do
        target_file "#{new_resource.home}/server"
        to          "#{new_resource.home}/#{dirname}"
        owner       "#{new_resource.user}"
        link_type   :symbolic
        action      :create
    end

    ruby_block "remove_conf_from_distrib" do
        block do
            ::File.exists?("#{new_resource.home}/server/bin/nuxeo.conf") do
                Chef::Log.info("Removing default nuxeo.conf")
                ::File.remove("#{new_resource.home}/server/bin/nuxeo.conf")
            end
        end
    end

    template "nuxeo.conf" do
        path    "#{new_resource.home}/server/bin/nuxeo.conf"
        source  "nuxeo.conf.erb"
        owner   "#{new_resource.user}"
        mode    "0600"
        variables   ({
            :data_dir => "#{new_resource.home}/data",
            :log_dir => "#{new_resource.home}/logs",
            :tmp_dir => "#{new_resource.home}/tmp",
            :pid_dir => "#{new_resource.home}",
        })
    end

end


action :delete do

    #nuxeo_nxuser "nxuser" do
    #    username "#{new_resource.username}"
    #    action :delete
    #end

end

