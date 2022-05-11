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
  String $account = '',
  Optional[String] $challengealias = undef,
  String $hostname = $title,
) {
  file { ["/opt/certs/${hostname}", "/opt/certs/${hostname}/${hostname}"]:
    ensure => directory,
  }

  file { "/opt/certs/${hostname}/account.conf":
    ensure  => file,
    mode    => '0400',
    content => $account,
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

  if $challenge_alias {
    file_line { "acme-${hostname}-challengealias":
      ensure => present,
      path   => "/opt/certs/${hostname}/${hostname}/${hostname}.conf",
      line   => "Le_ChallengeAlias='$challenge_alias,'",
      match  => '^Le_ChallengeAlias=',
      notify => Exec["acme-${hostname}-renew"],
    }
  }

  $b64_reloadcmd = base64('encode', $reloadcmd)

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
    command => "/opt/acme/acme.sh --config-home /opt/certs/${hostname} --renew-all --force",
    refreshonly = true,
  }

  -> exec { "acme-${hostname}-issue":
    command => "/opt/acme/acme.sh --config-home /opt/certs/${hostname} --renew-all --force",
    creates => "/opt/certs/${hostname}/${hostname}/${hostname}.cer",
  }
}
