actions :create, :delete

attribute :id, :kind_of => String, :required => true, :name_attribute => true, :regex => /^[a-zA-Z0-9]+$/
attribute :user, :kind_of => String, :default => nil, :regex => /^[a-zA-Z0-9]+$/
attribute :home, :kind_of => String, :required => true
attribute :platform, :kind_of => String, :default => "cap-5.5"

attribute :installed, :default => false
attribute :running, :default => false
