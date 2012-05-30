actions :create, :delete

attribute :username, :kind_of => String, :required => true, :name_attribute => true, :regex => /^[a-zA-Z0-9]+$/
attribute :home, :kind_of => String, :required => true
