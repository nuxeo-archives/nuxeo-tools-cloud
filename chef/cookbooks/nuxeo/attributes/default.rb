# This one is internal to Nuxeo - change to maven.nuxeo.org or your local maven repository

default["site"]["snapshot-search-pattern"] = "http://maven.in.nuxeo.com/nexus/service/local/artifact/maven/redirect?r=internal-snapshots&g=org.nuxeo.ecm.distribution&a=nuxeo-distribution-tomcat&v=@VERSION@&e=zip&c=nuxeo-@NAME@"
default["site"]["release-search-pattern"] = "http://maven.in.nuxeo.com/nexus/service/local/artifact/maven/redirect?r=internal-releases&g=org.nuxeo.ecm.distribution&a=nuxeo-distribution-tomcat&v=@VERSION@&e=zip&c=nuxeo-@NAME@"

default["distributions"]["cap-5.5"]["filename"] = "nuxeo-cap-5.5-tomcat.zip"
default["distributions"]["cap-5.5"]["url"] = "http://cdn.nuxeo.com/nuxeo-5.5/nuxeo-cap-5.5-tomcat-offline.zip"
default["distributions"]["cap-5.5"]["sha256sum"] = "6890844643cb6076132eb4a0716e6264af0ae6cc62aa204035ab1f69f6e1d3ac"

default["distributions"]["dm-5.4.2"]["filename"] = "nuxeo-dm-5.4.2-tomcat.zip"
default["distributions"]["dm-5.4.2"]["url"] = "http://cdn.nuxeo.com/nuxeo-5.4.2/nuxeo-dm-5.4.2-tomcat.zip"
default["distributions"]["dm-5.4.2"]["sha256sum"] = "e65194a4716dbb2214d928c263e30cf4802f041aab8b989716b7d503870a5368"

default["distributions"]["dam-1.3"]["filename"] = "nuxeo-dam-distribution-1.3-tomcat.zip"
default["distributions"]["dam-1.3"]["url"] = "http://cdn.nuxeo.com/nuxeo-dam-1.3/nuxeo-dam-distribution-1.3-tomcat.zip"
default["distributions"]["dam-1.3"]["sha256sum"] = "00aa745306f1c080b8b0899adbf6a2ebb9615d446c8020e0e5a2b9799efd6f4a"

default["distributions"]["cmf-1.8"]["filename"] = "nuxeo-case-management-distribution-1.8-tomcat-cmf.zip"
default["distributions"]["cmf-1.8"]["url"] = "http://cdn.nuxeo.com/cmf-1.8/nuxeo-case-management-distribution-1.8-tomcat-cmf.zip"
default["distributions"]["cmf-1.8"]["sha256sum"] = "9e2dc0d41056807b66625b1922c563b17b5d98d311cc71aada7abfe5fb43f40e"

