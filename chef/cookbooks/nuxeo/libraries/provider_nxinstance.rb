require 'chef/provider'
require 'etc'
require 'uri'

class Chef
  class Provider
    class NuxeoNxinstance < Chef::Provider

    attr_accessor :id
    attr_accessor :user
    attr_accessor :group
    attr_accessor :basedir
    attr_accessor :distrib
    attr_accessor :clid

    attr_accessor :dbtemplate
    attr_accessor :basetemplates
    attr_accessor :nuxeoconf
    attr_accessor :packages

    attr_accessor :installed
    attr_accessor :running

    def initialize(new_resource, run_context=nil)
        super
    end

    def load_current_resource
        @current_resource = Chef::Resource::NuxeoNxinstance.new(@new_resource.name)
        # TODO
    end

    def action_create
        Chef::Log.info("ACTION: create")
        user_info = get_or_create_user
        instance_base = @new_resource.basedir || ::File.join(user_info.dir, "nxinstance-#{@new_resource.id}")
        dirname = unzip_distribution(user_info, instance_base)
        setup_nuxeo(user_info, instance_base, dirname)
    end

    def action_delete
        Chef::Log.info("ACTION: delete")
        Chef::Log.warn("Instance deletion not implemented")
    end

    def get_or_create_user
        running_user_name = ENV["SUDO_USER"] || ENV["USER"]
        new_user_name = @new_resource.user || running_user_name
        new_user_home = @new_resource.basedir || "/home/#{new_user_name}" # Is there a system-independant way to get "/home" ?
        new_group_name = @new_resource.group || new_user_name
        user_exists = true
        begin
            user_info = Etc.getpwnam(new_user_name)
        rescue
            user_exists = false
        end
        if user_exists == false then
            new_group = Chef::Resource::Group.new(new_group_name, run_context)
            new_group.run_action(:create)
            new_user = Chef::Resource::User.new(new_user_name, run_context)
            new_user.gid(new_group_name)
            new_user.comment("Nuxeo Instance")
            new_user.home(new_user_home)
            new_user.shell("/bin/bash")
            new_user.run_action(:create)
        end
        user_info = Etc.getpwnam(new_user_name)
    end

    def uri?(string)
        uri = URI.parse(string)
        %w( http https ).include?(uri.scheme)
    rescue URI::BadURIError
        false
    rescue URI::InvalidURIError
        false
    end

    def unzip_distribution(user_info, instance_base)
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
                rubyzip = Chef::Resource::ChefGem.new("rubyzip", run_context)
                rubyzip.run_action(:install)
                require 'zip/zip'
                distrib_source = "file"
                filename = @new_resource.distrib
                zip = Zip::ZipFile.open(filename)
                zip.entries.each do |entry|
                    if entry.directory? &&
                       entry.to_s().sub(/\/$/, '').count('/') == 0 &&
                       !entry.to_s().include?("nuxeo-shell") then
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
                url = "#{node["distributions"]["#{@new_resource.distrib}"]["url"]}"
                filename = ::File.join(Dir.tmpdir, "#{node["distributions"]["#{@new_resource.distrib}"]["filename"]}")
                sha256sum = "#{node["distributions"]["#{@new_resource.distrib}"]["sha256sum"]}"
                source = url
            end
            if distrib_source == "remote" then
                # Don't cache SNAPSHOTs
                if filename.include? "SNAPSHOT" then
                    if ::File.exists?(filename) then
                        FileUtils.rm(filename)
                    end
                end
                remote_file = Chef::Resource::RemoteFile.new("distrib-#{@new_resource.id}", run_context)
                remote_file.source(url)
                remote_file.path(filename)
                remote_file.checksum(sha256sum)
                remote_file.mode("0644")
                remote_file.run_action(:create_if_missing)
            end
            rubyzip = Chef::Resource::ChefGem.new("rubyzip", run_context)
            rubyzip.run_action(:install)
            require 'zip/zip'
            zip = Zip::ZipFile.open(filename)
            zip.entries.each do |entry|
                if entry.directory? &&
                   entry.to_s().sub(/\/$/, '').count('/') == 0 &&
                   !entry.to_s().include?("shell") then
                    dirname = entry.to_s().sub(/\/$/, '')
                end
            end
        end

        # Set up paths
        nuxeo_home_dir = ::File.join(instance_base, dirname)
        nuxeo_conf_file = ::File.join(nuxeo_home_dir, "bin", "nuxeo.conf")

        Chef::Log.info("########################################################")
        Chef::Log.info("# Instance ID: #{@new_resource.id}")
        Chef::Log.info("# Instance base: #{instance_base}")
        Chef::Log.info("# Instance owner: #{user_info.name}")
        Chef::Log.info("# Distribution source (#{distrib_source}): #{source}")
        Chef::Log.info("########################################################")

        nxhome = Chef::Resource::Directory.new("nxhome-#{@new_resource.id}", run_context)
        nxhome.path(instance_base)
        nxhome.owner(user_info.name)
        nxhome.group(user_info.gid)
        nxhome.recursive(true)
        nxhome.mode("0700")
        nxhome.run_action(:create)

        if distrib_source == "dir" then
            FileUtils.cp_r(filename, instance_base)
        else
            unzip = Chef::Resource::Execute.new("unzip-#{@new_resource.id}", run_context)
            unzip.command("unzip -q #{filename}")
            unzip.creates(nuxeo_home_dir)
            unzip.cwd(instance_base)
            unzip.user(user_info.name)
            unzip.group(user_info.gid)
            unzip.umask(0077)
            unzip.run_action(:run)
        end
        
        chown = Chef::Resource::Execute.new("chown-#{@new_resource.id}", run_context)
        chown.command("chown -R #{user_info.uid}:#{user_info.gid} #{dirname}")
        chown.cwd(instance_base)
        chown.run_action(:run)

        chmod = Chef::Resource::Execute.new("chmod-#{@new_resource.id}", run_context)
        chmod.command("chmod -R og-rwx #{dirname}")
        chmod.cwd(instance_base)
        chmod.run_action(:run)

        symlink = Chef::Resource::Link.new("symlink-#{@new_resource.id}", run_context)
        symlink.target_file(::File.join(instance_base, "server"))
        symlink.to(::File.join(instance_base, dirname))
        # CHEF-3126
        # symlink.owner(user_info.uid)
        # symlink.group(user_info.gid)
        symlink.link_type(:symbolic)
        symlink.run_action(:create)

        # CHEF-3126
        chownlink = Chef::Resource::Execute.new("chownlink-#{@new_resource.id}", run_context)
        chownlink.command("chown --no-dereference #{user_info.uid}:#{user_info.gid} server")
        chownlink.cwd(instance_base)
        chownlink.run_action(:run)

        nuxeo_conf_file = ::File.join(instance_base, dirname, "bin", "nuxeo.conf")
        if ::File.exists?(nuxeo_conf_file) then
            Chef::Log.info("Removing default nuxeo.conf")
            FileUtils.rm(nuxeo_conf_file)
        else
            Chef::Log.info("No nuxeo.conf to remove")
        end

        dirname
    end

    def setup_nuxeo(user_info, instance_base, dirname)
        nuxeo_home_dir = ::File.join(instance_base, dirname)
        nuxeo_conf_file = ::File.join(nuxeo_home_dir, "bin", "nuxeo.conf")
        nuxeo_data_dir = ::File.join(nuxeo_home_dir, "nxserver", "data")
        realnuxeoctl = ::File.join(nuxeo_home_dir, "bin", "nuxeoctl")
        nuxeoctl = ::File.join(instance_base, "nuxeoctl")
        # nuxeo.conf
        ::File.open(nuxeo_conf_file, 'w') do |conf|
            conf.puts("JAVA_OPTS=#{@new_resource.nuxeoconf["JAVA_OPTS"]}\n")
            @new_resource.nuxeoconf.delete("JAVA_OPTS")
            templates = @new_resource.basetemplates.insert(0, @new_resource.dbtemplate).join(",")
            conf.puts("nuxeo.templates=#{templates}\n")
            @new_resource.nuxeoconf.each do |key, value|
                if key == "nuxeo.data.dir" then
                    nuxeo_data_dir = value
                end
                conf.puts("#{key}=#{value}\n")
            end
        end
        ::File.chown(user_info.uid, user_info.gid, nuxeo_conf_file)
        ::File.chmod(0600, nuxeo_conf_file)
        # instance.clid
        if @new_resource.clid != nil then
            clidfile = ::File.join(nuxeo_data_dir, "instance.clid")
            ::File.open(clidfile, 'w') do |clid|
                clid.puts(@new_resource.clid)
            end
            ::File.chown(user_info.uid, user_info.gid, clidfile)
            ::File.chmod(0600, clidfile)
        end
        # Add fake nuxeoctl that includes env vars
        ::File.open(nuxeoctl, 'w') do |ctl|
            ctl.puts("#!/bin/bash\n")
            ctl.puts("export NUXEO_CONF=#{nuxeo_conf_file}\n")
            ctl.puts("export NUXEO_HOME=#{nuxeo_home_dir}\n")
            ctl.puts("#{realnuxeoctl} --gui=false $@\n")
        end
        ::File.chown(user_info.uid, user_info.gid, nuxeoctl)
        ::File.chmod(0700, realnuxeoctl)
        ::File.chmod(0700, nuxeoctl)

        # install packages
        installed_packages = []
        @new_resource.packages.each do |id, state|
            if Integer(state) > 2 then
                installed_packages << id
            end
        end

        if installed_packages.count() > 0 then
            mpinit = Chef::Resource::Execute.new("mpinit-#{@new_resource.id}", run_context)
            mpinit.command("#{nuxeoctl} -q mp-init")
            mpinit.user(user_info.name)
            mpinit.group(user_info.gid)
            mpinit.umask(0077)
            mpinit.run_action(:run)
        end
        if installed_packages.count() > 0 then
            mpinstall = Chef::Resource::Execute.new("mpinstall-#{@new_resource.id}", run_context)
            mpinstall.command("#{nuxeoctl} -q mp-install #{installed_packages.join(" ")}")
            mpinstall.user(user_info.name)
            mpinstall.group(user_info.gid)
            mpinstall.umask(0077)
            mpinstall.run_action(:run)
        end
    end

    end
  end
end

