require 'chef/provider'
require 'chef/mixin/command'
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
        rubyzip = Chef::Resource::ChefGem.new("rubyzip", run_context)
        rubyzip.run_action(:install)
        json = Chef::Resource::ChefGem.new("json", run_context)
        json.run_action(:install)
        Gem.clear_paths()
        require 'zip/zip'
        require 'json'
    end

    def load_current_resource
        @current_resource = Chef::Resource::NuxeoNxinstance.new(@new_resource.name)
        @current_resource.basedir(@new_resource.basedir)
        if ::File.exists?(::File.join(@current_resource.basedir, "server")) then
            stat = ::File.stat(@current_resource.basedir)
            @current_resource.user(Etc.getpwuid(stat.uid).name)
            @current_resource.group(Etc.getgrgid(stat.gid).name)
            # Get current resource from deployed distribution's "showconf"
            begin
                path = ENV["PATH"] + ":" + @current_resource.basedir
                command = ["altnuxeoctl", "--json", "showconf"]
                args = {}
                args[:cwd] = @current_resource.basedir
                args[:user] = @current_resource.user
                args[:group] = @current_resource.group
                args[:environment] = {"PATH" => path}
                status, stdout, stderr = Chef::Mixin::Command.output_of_command(command, args)
                current_config = JSON.parse(stdout)["instance"]
                Chef::Log.info("ShowConf: " + current_config.to_s()) # DEBUG
                @current_resource.distrib(current_config["distribution"]["name"] + "-" + current_config["distribution"]["version"])
                @current_resource.clid(current_config["clid"])
                nuxeoconf = {}
                current_config["configuration"]["keyvals"]["keyval"].each do |keypair|
                    nuxeoconf[keypair["key"]] = keypair["value"]
                end
                @current_resource.nuxeoconf(nuxeoconf)
                # TODO: templates, packages

            rescue
                Chef::Log.error("Could not parse values for current distribution")
            end

        end
        puts "Current resource: " + @current_resource.inspect() # DEBUG
    end

    def action_create
        Chef::Log.info("ACTION: create")
        user_info = get_or_create_user
        instance_base = @new_resource.basedir || ::File.join(user_info.dir, "nxinstance-#{@new_resource.id}")
        unzip_distribution(user_info, instance_base)
        add_new_launcher(user_info, instance_base)
        setup_nuxeo(user_info, instance_base)
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

    def unzip_file(source, destination)
        Zip::ZipFile.open(source) do |zip_file|
            zip_file.each do |f|
                file_path = ::File.join(destination, f.name)
                FileUtils.mkdir_p(::File.dirname(file_path))
                zip_file.extract(f, file_path) unless ::File.exist?(file_path)
            end
        end
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
                if node["distributions"].has_key?(@new_resource.distrib) then
                    url = "#{node["distributions"]["#{@new_resource.distrib}"]["url"]}"
                    filename = ::File.join(Dir.tmpdir, "#{node["distributions"]["#{@new_resource.distrib}"]["filename"]}")
                    sha256sum = "#{node["distributions"]["#{@new_resource.distrib}"]["sha256sum"]}"
                    source = url
                else
                    # Fallback on maven
                    platform_name = @new_resource.distrib.split('-', 2)[0]
                    platform_version = @new_resource.distrib.split('-', 2)[1]
                    if platform_version.include?("SNAPSHOT") then
                        url = node["site"]["snapshot-search-pattern"].gsub("@VERSION@", platform_version).gsub("@NAME@", platform_name)
                    else
                        url = node["site"]["release-search-pattern"].gsub("@VERSION@", platform_version).gsub("@NAME@", platform_name)
                    end
                    filename = ::File.join(Dir.tmpdir, "nuxeo-#{platform_name}-#{platform_version}-tomcat.zip")
                    sha256sum = nil
                    source = url
                end
            end
            if distrib_source == "remote" then
                # Don't cache SNAPSHOTs
                if filename.include? "SNAPSHOT" then
                    FileUtils.rm_f(filename)
                end
                remote_file = Chef::Resource::RemoteFile.new("distrib-#{@new_resource.id}", run_context)
                remote_file.source(url)
                remote_file.path(filename)
                remote_file.checksum(sha256sum)
                remote_file.mode("0644")
                remote_file.run_action(:create_if_missing)
            end
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

        FileUtils.mkdir_p(instance_base, :mode => 0700)

        if distrib_source == "dir" then
            FileUtils.cp_r(filename, instance_base)
        else
            unzip_file(filename, instance_base)
        end

        FileUtils.ln_sf(nuxeo_home_dir, ::File.join(instance_base, "server"))

        FileUtils.chown_R(user_info.uid, user_info.gid, instance_base)

        Find.find(instance_base) do |entry|
            if ::File.basename(entry) == '.' or ::File.basename(entry) == '..' then
                Find.prune()
            else
                mode = ::File.stat(entry).mode & 0700
                FileUtils.chmod(mode, entry)
            end
        end

        # No dereference for Ruby chown -> use system chown
        chownlink = Chef::Resource::Execute.new("chownlink-#{@new_resource.id}", run_context)
        chownlink.command("chown -h #{user_info.uid}:#{user_info.gid} server")
        chownlink.cwd(instance_base)
        chownlink.run_action(:run)

        if ::File.exists?(nuxeo_conf_file) then
            Chef::Log.info("Removing default nuxeo.conf")
            FileUtils.rm(nuxeo_conf_file)
        else
            Chef::Log.info("No nuxeo.conf to remove")
        end
    end

    def add_new_launcher(user_info, instance_base)
        # Download current artifacts for launcher and distribution-resources
        launcher_tmp = ::File.join(Dir.tmpdir, "nuxeo-launcher.jar")
        resources_tmp = ::File.join(Dir.tmpdir, "nuxeo-resources.zip")
        # Don't cache SNAPSHOTs
        if node["launcher"]["url"].include? "SNAPSHOT" then
            FileUtils.rm_f(launcher_tmp)
        end
        if node["resources"]["url"].include? "SNAPSHOT" then
            FileUtils.rm_f(resources_tmp)
        end
        remote_launcher = Chef::Resource::RemoteFile.new("launcher-#{@new_resource.id}", run_context)
        remote_launcher.source(node["launcher"]["url"])
        remote_launcher.path(launcher_tmp)
        remote_launcher.mode("0644")
        remote_launcher.run_action(:create_if_missing)
        remote_resources = Chef::Resource::RemoteFile.new("resources-#{@new_resource.id}", run_context)
        remote_resources.source(node["resources"]["url"])
        remote_resources.path(resources_tmp)
        remote_resources.mode("0644")
        remote_resources.run_action(:create_if_missing)

        # Add new nuxeo launcher
        nuxeo_launcher = ::File.join(instance_base, "server", "bin", "alt-nuxeo-launcher.jar")
        FileUtils.rm_f(nuxeo_launcher)
        FileUtils.cp(launcher_tmp, nuxeo_launcher)
        FileUtils.chown(user_info.uid, user_info.gid, nuxeo_launcher)
        FileUtils.chmod(0600, nuxeo_launcher)

        # Add new nuxeoctl
        nuxeoctl = ::File.join(instance_base, "server", "bin", "alt-nuxeoctl")
        nuxeoctl_bat = ::File.join(instance_base, "server", "bin", "alt-nuxeoctl.bat")
        FileUtils.rm_f(nuxeoctl)
        FileUtils.rm_f(nuxeoctl_bat)
        Zip::ZipFile.open(resources_tmp) do |zip_file|
            zip_file.each do |f|
                if f.name == "nuxeoctl" or f.name == "nuxeoctl.bat" then
                    file_path = ::File.join(instance_base, "server", "bin", "alt-" + f.name)
                    FileUtils.mkdir_p(::File.dirname(file_path))
                    zip_file.extract(f, file_path) unless ::File.exist?(file_path)
                end
            end
        end
        newctl = ::File.read(nuxeoctl)
        newctl.gsub!("nuxeo-launcher.jar", "alt-nuxeo-launcher.jar")
        ::File.open(nuxeoctl, 'w') do |ctl|
            ctl.puts(newctl)
        end
        newctl_bat = ::File.read(nuxeoctl_bat)
        newctl_bat.gsub!("nuxeo-launcher.jar", "alt-nuxeo-launcher.jar")
        ::File.open(nuxeoctl_bat, 'w') do |ctl|
            ctl.puts(newctl_bat)
        end
        FileUtils.chown(user_info.uid, user_info.gid, nuxeoctl)
        FileUtils.chmod(0700, nuxeoctl)
        FileUtils.chown(user_info.uid, user_info.gid, nuxeoctl_bat)
        FileUtils.chmod(0700, nuxeoctl_bat)

    end

    def setup_nuxeo(user_info, instance_base)
        nuxeo_home_dir = ::File.join(instance_base, "server")
        nuxeo_conf_dir = ::File.join(instance_base, "conf")
        nuxeo_conf_file = ::File.join(nuxeo_conf_dir, "nuxeo.conf")
        nuxeo_data_dir = ::File.join(nuxeo_home_dir, "nxserver", "data")
        realnuxeoctl = ::File.join(nuxeo_home_dir, "bin", "nuxeoctl")
        realaltnuxeoctl = ::File.join(nuxeo_home_dir, "bin", "alt-nuxeoctl")
        nuxeoctl = ::File.join(instance_base, "nuxeoctl")
        altnuxeoctl = ::File.join(instance_base, "altnuxeoctl")

        # Get version from deployed nuxeo.distribution
        distrib_props = ::File.join(nuxeo_home_dir, "templates", "common", "config", "distribution.properties")
        version_all = nil
        ::File.open(distrib_props, 'r') do | propsfile|
            while (line = propsfile.gets()) do
                key = line.split('=')[0].strip()
                value = line.split('=')[1]
                if key == "org.nuxeo.distribution.version" then
                    version_all = value.strip()
                    break
                end
            end
        end
        version_main = version_all.split('-', 2)[0] # 5.6
        version_qualifier = version_all.split('-', 2)[1] # SNAPSHOT
        version_components = version_main.split('.') # 5, 6
        while version_components.length() < 3 do
            version_components << "0"
        end # 5, 6, 0
        version_int = version_components[0].to_i() * 1000 * 1000 + version_components[1].to_i() * 1000 + version_components[2].to_i() # 5006000
        if version_qualifier == nil then
            version_full = version_components.join('.') # 5.4.2
        else
            version_full = version_components.join('.') + '-' + version_qualifier # 5.6.0-SNAPSHOT
        end

        # nuxeo.conf
        FileUtils.mkdir_p(nuxeo_conf_dir, :mode => 0700)
        FileUtils.chown(user_info.uid, user_info.gid, nuxeo_conf_dir)
        ::File.open(nuxeo_conf_file, 'w') do |conf|
            conf.puts("JAVA_OPTS=#{@new_resource.nuxeoconf["JAVA_OPTS"]}\n")
            @new_resource.nuxeoconf.delete("JAVA_OPTS")
            templates = @new_resource.basetemplates.insert(0, @new_resource.dbtemplate).join(",")
            conf.puts("nuxeo.templates=#{templates}\n")
            @new_resource.nuxeoconf.delete("nuxeo.templates")
            # Obsolete / non-applicable keys
            if version_int >= 5006000 then
                @new_resource.nuxeoconf.delete("nuxeo.loopback.url")
            end
            @new_resource.nuxeoconf.delete("nuxeo.installer.lastinstalledversion")
            @new_resource.nuxeoconf.delete("nuxeo.installer.useautopg")
            @new_resource.nuxeoconf.delete("nuxeo.debconf.pgsqldb")
            # Fill up nuxeo.conf
            @new_resource.nuxeoconf.each do |key, value|
                if key == "nuxeo.data.dir" then
                    nuxeo_data_dir = value
                end
                conf.puts("#{key}=#{value}\n")
            end
        end
        FileUtils.chown(user_info.uid, user_info.gid, nuxeo_conf_file)
        FileUtils.chmod(0600, nuxeo_conf_file)
        # instance.clid
        if @new_resource.clid != nil then
            FileUtils.mkdir_p(nuxeo_data_dir, :mode => 0700)
            clidfile = ::File.join(nuxeo_data_dir, "instance.clid")
            ::File.open(clidfile, 'w') do |clid|
                @new_resource.clid.split('--').each do |clidpart|
                    clid.puts(clidpart)
                end
                clid.puts(@new_resource.id)
            end
            FileUtils.chown_R(user_info.uid, user_info.gid, nuxeo_data_dir)
            FileUtils.chmod(0600, clidfile)
        end
        # Add fake nuxeoctl that includes env vars
        ::File.open(nuxeoctl, 'w') do |ctl|
            ctl.puts("#!/bin/bash\n")
            ctl.puts("export NUXEO_CONF=#{nuxeo_conf_file}\n")
            ctl.puts("export NUXEO_HOME=#{nuxeo_home_dir}\n")
            if version_int < 5004001 then
                ctl.puts("#{realnuxeoctl} $@\n")
            elsif version_int < 5006000 then
                ctl.puts("#{realnuxeoctl} nogui $@\n")
            else
                ctl.puts("#{realnuxeoctl} --gui=false $@\n")
            end
        end
        FileUtils.chown(user_info.uid, user_info.gid, nuxeoctl)
        FileUtils.chmod(0700, realnuxeoctl)
        FileUtils.chmod(0700, nuxeoctl)
        ::File.open(altnuxeoctl, 'w') do |ctl|
            ctl.puts("#!/bin/bash\n")
            ctl.puts("export NUXEO_CONF=#{nuxeo_conf_file}\n")
            ctl.puts("export NUXEO_HOME=#{nuxeo_home_dir}\n")
            ctl.puts("#{realaltnuxeoctl} --gui=false $@ | grep -v 'is deprecated'\n")
        end
        FileUtils.chown(user_info.uid, user_info.gid, altnuxeoctl)
        FileUtils.chmod(0700, altnuxeoctl)

        # install packages
        installed_packages = []
        @new_resource.packages.each do |name, id_state|
            id = id_state[0]
            state = id_state[1]
            # nil id is not imported in the array when parsing json
            if state == nil then
                state = id
                id = ''
            end
            # nil id => use the name
            if id.empty? then
                id = name
            end
            if Integer(state) > 2 then
                if version_int >= 5005000 then
                    installed_packages << id
                else
                    # Pre-5.5 doesn't have base packages
                    if id.include?("nuxeo-content-browser") or
                       id.include?("nuxeo-dm") or
                       id.include?("nuxeo-dam") or
                       id.include?("nuxeo-social-collaboration") or
                       id.include?("nuxeo-cmf") then
                        Chef::Log.warn("Ignoring package #{id} for Nuxeo < 5.5")
                    else
                        installed_packages << id
                    end
                end
            end
        end

        if installed_packages.count() > 0 then
            if version_int >= 5005000 then
                # Pre-5.5 doesn't have base packages
                mpinit = Chef::Resource::Execute.new("mpinit-#{@new_resource.id}", run_context)
                mpinit.command("#{altnuxeoctl} -q mp-init")
                mpinit.user(user_info.name)
                mpinit.group(user_info.gid)
                mpinit.umask(0077)
                mpinit.run_action(:run)
            end
            mpinstall = Chef::Resource::Execute.new("mpinstall-#{@new_resource.id}", run_context)
            mpinstall.command("#{altnuxeoctl} -q --accept=true --relax=true mp-install #{installed_packages.join(" ")}")
            mpinstall.user(user_info.name)
            mpinstall.group(user_info.gid)
            mpinstall.umask(0077)
            mpinstall.run_action(:run)
        end
    end

    end
  end
end

