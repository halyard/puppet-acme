# @summary Create a certificate
#
# @param reloadcmd defines how to reload services after the certificate is updated
# @param keypath defines where to install the key file
# @param fullchainpath defines where to install the full cert chain
# @param account defines the credentials file contents
# @param challengealias defines an alias domain to use for the validation
# @param hostname (namevar) sets the CN of the certificate
define acme::certificate (
  String $reloadcmd,
  String $keypath,
  String $fullchainpath,
  Optional[String] $account = undef,
  Optional[String] $challengealias = undef,
  String $hostname = $title,
) {
  include acme

  file { ["/opt/certs/${hostname}", "/opt/certs/${hostname}/${hostname}"]:
    ensure => directory,
  }

  file { "/opt/certs/${hostname}/account.conf":
    ensure  => file,
    mode    => '0400',
    content => $account,
    notify  => Exec["acme-${hostname}-renew"],
  }

  file { "/opt/certs/${hostname}/${hostname}/${hostname}.conf":
    ensure => file,
  }

  file_line { "acme-${hostname}-api":
    ensure => present,
    path   => "/opt/certs/${hostname}/${hostname}/${hostname}.conf",
    line   => "Le_API='https://acme-v02.api.letsencrypt.org/directory'",
    match  => '^Le_API=',
    notify => Exec["acme-${hostname}-renew"],
  }

  file_line { "acme-${hostname}-orderfinalize":
    ensure => present,
    path   => "/opt/certs/${hostname}/${hostname}/${hostname}.conf",
    line   => "Le_OrderFinalize='https://acme-v02.api.letsencrypt.org/acme/finalize/554069336/90785049486'",
    match  => '^Le_OrderFinalize=',
    notify => Exec["acme-${hostname}-renew"],
  }

  file_line { "acme-${hostname}-linkorder":
    ensure => present,
    path   => "/opt/certs/${hostname}/${hostname}/${hostname}.conf",
    line   => "Le_LinkOrder='https://acme-v02.api.letsencrypt.org/acme/order/554069336/90785049486'",
    match  => '^Le_LinkOrder=',
    notify => Exec["acme-${hostname}-renew"],
  }

  file_line { "acme-${hostname}-linkcert":
    ensure => present,
    path   => "/opt/certs/${hostname}/${hostname}/${hostname}.conf",
    line   => "Le_LinkCert='https://acme-v02.api.letsencrypt.org/acme/cert/03a896fa7cc0f374caacf403e2baca1bc7a5'",
    match  => '^Le_LinkCert=',
    notify => Exec["acme-${hostname}-renew"],
  }

  file_line { "acme-${hostname}-domain":
    ensure => present,
    path   => "/opt/certs/${hostname}/${hostname}/${hostname}.conf",
    line   => "Le_Domain='${hostname}'",
    match  => '^Le_Domain=',
    notify => Exec["acme-${hostname}-renew"],
  }

  file_line { "acme-${hostname}-alt":
    ensure => present,
    path   => "/opt/certs/${hostname}/${hostname}/${hostname}.conf",
    line   => "Le_Alt='no'",
    match  => '^Le_Alt=',
    notify => Exec["acme-${hostname}-renew"],
  }

  file_line { "acme-${hostname}-webroot":
    ensure => present,
    path   => "/opt/certs/${hostname}/${hostname}/${hostname}.conf",
    line   => "Le_Webroot='dns_aws'",
    match  => '^Le_Webroot=',
    notify => Exec["acme-${hostname}-renew"],
  }

  if $challengealias {
    file_line { "acme-${hostname}-challengealias":
      ensure => present,
      path   => "/opt/certs/${hostname}/${hostname}/${hostname}.conf",
      line   => "Le_ChallengeAlias='${challengealias},'",
      match  => '^Le_ChallengeAlias=',
      notify => Exec["acme-${hostname}-renew"],
    }
  }

  $b64_reloadcmd = chomp(base64('encode', $reloadcmd))

  file_line { "acme-${hostname}-reloadcmd":
    ensure => present,
    path   => "/opt/certs/${hostname}/${hostname}/${hostname}.conf",
    line   => "Le_ReloadCmd='__ACME_BASE64__START_${b64_reloadcmd}__ACME_BASE64__END_'",
    match  => '^Le_ReloadCmd=',
    notify => Exec["acme-${hostname}-renew"],
  }

  file_line { "acme-${hostname}-realkeypath":
    ensure => present,
    path   => "/opt/certs/${hostname}/${hostname}/${hostname}.conf",
    line   => "Le_RealKeyPath='${keypath}'",
    match  => '^Le_RealKeyPath=',
    notify => Exec["acme-${hostname}-renew"],
  }

  file_line { "acme-${hostname}-realfullchainpath":
    ensure => present,
    path   => "/opt/certs/${hostname}/${hostname}/${hostname}.conf",
    line   => "Le_RealFullChainPath=${fullchainpath}",
    match  => '^Le_RealFullChainPath=',
    notify => Exec["acme-${hostname}-renew"],
  }

  exec { "acme-${hostname}-renew":
    command     => "/opt/acme/acme.sh --config-home /opt/certs/${hostname} --renew-all",
    path        => '/usr/bin',
    refreshonly => true,
  }

  -> exec { "acme-${hostname}-issue":
    command => "/opt/acme/acme.sh --config-home /opt/certs/${hostname} --renew-all",
    path    => '/usr/bin',
    creates => "/opt/certs/${hostname}/${hostname}/${hostname}.cer",
  }
}
