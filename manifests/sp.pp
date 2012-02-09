/*

= Class: shibboleth::sp

Installs shibboleth's service provider, and allow it's apache module get loaded
with apache::module.

== Parameters
$shibboleth2_xml_template:: the template apth for your shibboleth2.xml.erb (optional)
$shibboleth2_xml_template:: the template apth for your shibboleth2.xml.erb (optional)

== Requires:
- Class[apache]

== Limitations:
- currently RedHat/CentOS only.

*/
class shibboleth::sp (
    $shibboleth2_xml_template=undef
    ) {

  yumrepo { "security_shibboleth":
    descr    => "Shibboleth-RHEL_${lsbmajdistrelease}",
    baseurl  => "http://download.opensuse.org/repositories/security://shibboleth/RHEL_${lsbmajdistrelease}",
    gpgkey   => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-shibboleth",
    enabled  => 1,
    gpgcheck => 1,
    require  => Exec["download shibboleth repo key"],
  }

  # ensure file is managed in case we want to purge /etc/yum.repos.d/
  # http://projects.puppetlabs.com/issues/3152
  file { "/etc/yum.repos.d/security_shibboleth.repo":
    ensure  => present,
    mode    => 0644,
    owner   => "root",
    require => Yumrepo["security_shibboleth"],
  }

  exec { "download shibboleth repo key":
    command => "curl -s http://download.opensuse.org/repositories/security:/shibboleth/RHEL_${lsbmajdistrelease}/repodata/repomd.xml.key -o /etc/pki/rpm-gpg/RPM-GPG-KEY-shibboleth",
    creates => "/etc/pki/rpm-gpg/RPM-GPG-KEY-shibboleth",
  }

  package { "shibboleth":
    ensure  => "present",
    name    => "shibboleth.${architecture}",
    require => Yumrepo["security_shibboleth"],
  }

  $shibpath = $architecture ? {
    x86_64 => "/usr/lib64/shibboleth/mod_shib_22.so",
    i386   => "/usr/lib/shibboleth/mod_shib_22.so",
  }

  file { "/etc/httpd/mods-available/shib.load":
    ensure  => present,
    content => "# file managed by puppet\nLoadModule mod_shib ${shibpath}\n",
  }

  file { "/etc/httpd/conf.d/shib.conf":
    ensure  => absent,
    require => Package["shibboleth"],
    notify  => Service["apache"],
  }

  if $shibboleth2_xml_template != undef {
    file { "/etc/shibboleth/shibboleth2.xml":
      ensure  => present,
      require => Package["shibboleth"],
      notify  => Service["apache"],
      content => template($shibboleth2_xml_template),
    }
  }

# TODO
##
## Used for example logo and style sheet in error templates.
##
#<IfModule mod_alias.c>
#  <Location /shibboleth-sp>
#    Allow from all
#  </Location>
#  Alias /shibboleth-sp/main.css /usr/share/doc/shibboleth/main.css
#  Alias /shibboleth-sp/logo.jpg /usr/share/doc/shibboleth/logo.jpg
#</IfModule>

}
