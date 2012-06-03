require "etc"

action :create do

    # code outside blocks is always executed first
    url = "#{node["distributions"]["#{new_resource.platform}"]["url"]}"
    filename = ::File.join(Dir.tmpdir, "#{node["distributions"]["#{new_resource.platform}"]["filename"]}")
    dirname = "#{node["distributions"]["#{new_resource.platform}"]["dirname"]}"
    sha256sum = "#{node["distributions"]["#{new_resource.platform}"]["sha256sum"]}"

    user_info = Etc.getpwnam(@new_resource.user)
    instance_base = @new_resource.basedir || ::File.join(user_info.dir, "nxinstance-#{new_resource.id}")
    print "########################################################\n"
    print "# Instance ID: #{new_resource.id}\n"
    print "# Instance base: #{instance_base}\n"
    print "# Instance owner: #{user_info.name}\n"
    print "########################################################\n"

    remote_file "nxarchive" do
        source  url
        path    filename
        checksum sha256sum
        mode    "0644"
        action  :create_if_missing
    end

    directory "nxhome" do
        path    instance_base
        owner   user_info.name
        group   user_info.gid
        recursive true
        mode    "0700"
        action  :create
    end

    execute "unzip" do
        command "unzip -q #{filename}"
        creates ::File.join(instance_base, dirname)
        cwd     instance_base
        user    user_info.name
        group   user_info.gid
        umask   0077
    end

    # umask isn't working with unzip
    execute "chmod" do
        command "chmod -R og-rwx #{dirname}"
        cwd     instance_base
        user    user_info.name
        group   user_info.gid
    end

    link "server" do
        target_file ::File.join(instance_base, "server")
        to          ::File.join(instance_base, dirname)
        # CHEF-3126
        #owner       user_info.uid
        #group       user_info.gid
        link_type   :symbolic
        action      :create
    end

    # CHEF-3126
    execute "chown" do
        command "chown --no-dereference #{user_info.uid}:#{user_info.gid} server"
        cwd     instance_base
    end

    ruby_block "remove_conf_from_distrib" do
        block do
            nuxeoconffile = ::File.join(instance_base, "server", "bin", "nuxeo.conf")
            ::File.exists?(nuxeoconffile) do
                Chef::Log.info("Removing default nuxeo.conf")
                ::File.remove(nuxeoconffile)
            end
        end
    end

    template "nuxeo.conf" do
        path    ::File.join(instance_base, "server", "bin", "nuxeo.conf")
        source  "nuxeo.conf.erb"
        owner   user_info.name
        group   user_info.gid
        mode    "0600"
        variables   ({
            :data_dir => "#{instance_base}/data",
            :log_dir => "#{instance_base}/logs",
            :tmp_dir => "#{instance_base}/tmp",
            :pid_dir => "#{instance_base}",
        })
    end

end


action :delete do

    #nuxeo_nxuser "nxuser" do
    #    username "#{new_resource.username}"
    #    action :delete
    #end

end

