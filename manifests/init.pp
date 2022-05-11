# @summary Configure x509 certificates with ACME
#
# @param certificates sets the certificates to create
class acme (
  Hash[String, Hash] $certificates = {},
) {
  vcsrepo { '/opt/acme':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/akerl/acme.sh',
    revision => 'master',
  }

  file { '/opt/certs':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
  }

  file { '/opt/certs/renew_all':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/acme/renew_all',
  }

  file { '/etc/systemd/system/acme_renew.service':
    ensure => file,
    source => 'puppet:///modules/acme/acme_renew.service',
    notify => Service['acme_renew.timer'],
  }

  file { '/etc/systemd/system/acme_renew.timer':
    ensure => file,
    source => 'puppet:///modules/acme/acme_renew.timer',
    notify => Service['acme_renew.timer'],
  }

  service { 'acme_renew.timer':
    ensure => running,
    enable => true,
  }

  $acme::certificates.each | String $name, Hash $options | {
    acme::certificate { $name:
      * => $options,
    }
  }
}
