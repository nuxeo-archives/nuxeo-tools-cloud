
action :create do

    nuxeo_nxuser "nxuser" do
        username "#{new_resource.username}"
        home "#{new_resource.home}"
        action :create
    end

    url = "#{node["nxdistrib"]["#{new_resource.variant}"]["#{new_resource.version}"]["url"]}"
    filename = "/tmp/#{node["nxdistrib"]["#{new_resource.variant}"]["#{new_resource.version}"]["filename"]}"
    dirname = "#{node["nxdistrib"]["#{new_resource.variant}"]["#{new_resource.version}"]["dirname"]}"
    sha256sum = "/tmp/#{node["nxdistrib"]["#{new_resource.variant}"]["#{new_resource.version}"]["sha256sum"]}"

    remote_file "nxarchive" do
        source  "#{url}"
        path    "#{filename}"
        checksum "#{sha256sum}"
        mode    "0644"
        action  :create_if_missing
    end

    execute "unzip" do
        command "unzip #{filename}"
        creates "#{new_resource.home}/#{dirname}"
        cwd     "#{new_resource.home}"
        user    "#{new_resource.username}"
    end

    link "server" do
        target_file "#{new_resource.home}/server"
        to          "#{new_resource.home}/#{dirname}"
        owner       "#{new_resource.username}"
        link_type   :symbolic
        action      :create
    end

    template "nuxeo.conf" do
        path    "#{new_resource.home}/server/bin/nuxeo.conf"
        source  "nuxeo.conf.erb"
        owner   "#{new_resource.username}"
        mode    "0644"
        variables   ({
            :data_dir => "#{new_resource.home}/data",
            :log_dir => "#{new_resource.home}/logs",
            :tmp_dir => "#{new_resource.home}/tmp",
            :pid_dir => "#{new_resource.home}",
            :http_port => "#{new_resource.http_port}",
            :admin_port => "#{new_resource.tomcat_admin_port}"
        })
    end

end


action :delete do

    nuxeo_nxuser "nxuser" do
        username "#{new_resource.username}"
        action :delete
    end

end

