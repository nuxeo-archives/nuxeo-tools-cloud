actions :create, :delete

attribute :username, :kind_of => String, :required => true, :name_attribute => true, :regex => /^[a-zA-Z0-9]+$/
attribute :home, :kind_of => String, :required => true
attribute :variant, :kind_of => String, :default => "cap", :equal_to => ["cap", "dm","dam","cmf"]
attribute :version, :kind_of => String, :required => true
attribute :http_port, :kind_of => String, :required => true, :regex => /^[0-9]+$/
attribute :tomcat_admin_port, :kind_of => String, :required => true, :regex => /^[0-9]+$/

