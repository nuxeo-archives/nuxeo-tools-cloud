
# Right now those are discrete calls

# The goal is to to use data bags (pretty much a key -> dictionary store)
# to create/delete stuff depending on the target licecyle
# The data bag would provide all the currently hardcoded parameters


# Lifecycle: create

nuxeo_nxinstance "new instance" do
    username    "nxtest"
    home        "/home/nxtest"
    variant     "cap"
    version     "5.5"
    http_port   "8888"
    tomcat_admin_port "8555"
    action      :create
end

# Lifecycle: restore

# Lifecycle: start

# Lifecycle: stop

# Lifecycle: backup

# Lifecycle: delete

nuxeo_nxinstance "same one" do
    username    "nxtest"
    action      :delete
end
