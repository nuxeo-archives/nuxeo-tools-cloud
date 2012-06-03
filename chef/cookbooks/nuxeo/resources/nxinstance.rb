actions :create, :delete

attribute :id, :kind_of => String, :required => true, :name_attribute => true, :regex => /^[a-zA-Z0-9]+$/
attribute :user, :kind_of => String, :required => true, :regex => /^[a-zA-Z0-9]+$/
attribute :group, :kind_of => String, :required => true, :regex => /^[a-zA-Z0-9]+$/
attribute :basedir, :kind_of => String
attribute :platform, :kind_of => String, :default => "cap-5.5"
attribute :localdist, :kind_of => String, :default => nil

attribute :installed, :default => false
attribute :running, :default => false
