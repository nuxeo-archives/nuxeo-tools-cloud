require "etc"
require "uri"


def uri?(string)
    uri = URI.parse(string)
    %w( http https ).include?(uri.scheme)
rescue URI::BadURIError
    false
rescue URI::InvalidURIError
    false
end


action :create do

    user_info = Etc.getpwnam(@new_resource.user)
    instance_base = @new_resource.basedir || ::File.join(user_info.dir, "nxinstance-#{new_resource.id}")

    # Get distribution source and destination - look inside zip if needed
    distrib_source = "remote"
    filename = nil
    dirname = nil
    source = nil
    if ::File.exists?(@new_resource.distrib) then
        if ::File.directory?(@new_resource.distrib) then
            distrib_source = "dir"
            filename = @new_resource.distrib
            dirname = ::File.basename(@new_resource.distrib)
            source = @new_resource.distrib
        else
            distrib_source = "file"
            filename = @new_resource.distrib
            chef_gem "rubyzip"
            require "zip/zip"
            zip = Zip::ZipFile.open(filename)
            zip.entries.each do |entry|
                if entry.directory? &&
                   entry.to_s().sub(/\/$/, '').count('/') == 0 &&
                   !entry.to_s().include?("shell") then
                    dirname = entry.to_s().sub(/\/$/, '')
                end
            end
            source = @new_resource.distrib
        end
    else
        if uri?(@new_resource.distrib) then
            url = @new_resource.distrib
            filename = ::File.join(Dir.tmpdir, ::File.basename(@new_resource.distrib))
            sha256sum = nil
            source = @new_resource.distrib
        else
            url = "#{node["distributions"]["#{new_resource.distrib}"]["url"]}"
            filename = ::File.join(Dir.tmpdir, "#{node["distributions"]["#{new_resource.distrib}"]["filename"]}")
            sha256sum = "#{node["distributions"]["#{new_resource.distrib}"]["sha256sum"]}"
            source = url
        end
        remote_file "download-distrib" do
            only_if {distrib_source == "remote"}
            source  url
            path    filename
            checksum sha256sum
            mode    "0644"
            action  :nothing
        end.run_action(:create_if_missing)
        chef_gem "rubyzip"
        require "zip/zip"
        zip = Zip::ZipFile.open(filename)
        zip.entries.each do |entry|
            if entry.directory? &&
               entry.to_s().sub(/\/$/, '').count('/') == 0 &&
               !entry.to_s().include?("shell") then
                dirname = entry.to_s().sub(/\/$/, '')
            end
        end
    end

    Chef::Log.info("########################################################")
    Chef::Log.info("# Instance ID: #{new_resource.id}")
    Chef::Log.info("# Instance base: #{instance_base}")
    Chef::Log.info("# Instance owner: #{user_info.name}")
    Chef::Log.info("# Distribution source (#{distrib_source}): #{source}")
    Chef::Log.info("########################################################")

    directory "nxhome" do
        path    instance_base
        owner   user_info.name
        group   user_info.gid
        recursive true
        mode    "0700"
        action  :create
    end

    execute "unzip" do
        not_if  {distrib_source == "dir"}
        command "unzip -q #{filename}"
        creates ::File.join(instance_base, dirname)
        cwd     instance_base
        user    user_info.name
        group   user_info.gid
        umask   0077
    end

    ruby_block "copy-distrib" do
        only_if {distrib_source == "dir"}
        block do
            FileUtils.cp_r(filename, instance_base)
        end
    end

    execute "chown-dsitrib" do
        command "chown -R #{user_info.uid}:#{user_info.gid} #{dirname}"
        cwd     instance_base
    end

    execute "chmod" do
        command "chmod -R og-rwx #{dirname}"
        cwd     instance_base
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
    execute "chown-symlink" do
        command "chown --no-dereference #{user_info.uid}:#{user_info.gid} server"
        cwd     instance_base
    end

    ruby_block "remove_conf_from_distrib" do
        block do
            nuxeoconffile = ::File.join(instance_base, dirname, "bin", "nuxeo.conf")
            if ::File.exists?(nuxeoconffile) then
                Chef::Log.info("Removing default nuxeo.conf")
                FileUtils.rm(nuxeoconffile)
            else
                Chef::Log.info("No nuxeo.conf to remove")
            end
        end
    end

    template "nuxeo.conf" do
        path    ::File.join(instance_base, dirname, "bin", "nuxeo.conf")
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

