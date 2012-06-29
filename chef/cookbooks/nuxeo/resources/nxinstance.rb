actions :create, :delete

attribute :id, :kind_of => String, :required => true, :name_attribute => true, :regex => /^[a-zA-Z0-9]+$/
attribute :user, :kind_of => String, :required => true, :regex => /^[a-zA-Z0-9]+$/
attribute :group, :kind_of => String, :required => true, :regex => /^[a-zA-Z0-9]+$/
attribute :basedir, :kind_of => String
attribute :distrib, :kind_of => String
attribute :clid, :kind_of => String, :default => nil

attribute :dbtemplate, :kind_of => String, :default => "default"
attribute :basetemplates, :kind_of => Array, :default => []
attribute :nuxeoconf, :kind_of => Hash, :default => {"JAVA_OPTS" => "-server -Xms512m -Xmx1024m -XX:MaxPermSize=512m -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -Dfile.encoding=UTF-8 -Dorg.jboss.security.SecurityAssociation.ThreadLocal=true -Djava.net.preferIPv4Stack=true -Djava.awt.headless=true", "nuxeo.force.generation" => "true"}
attribute :packages, :kind_of => Hash, :default => {}

attribute :installed, :default => false
attribute :running, :default => false
