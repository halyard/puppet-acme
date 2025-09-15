# @summary Create a certificate
#
# @param hook_script sets the code to run after the certificate is updated
# @param aws_access_key_id sets the AWS key to use for Route53 challenge
# @param aws_secret_access_key sets the AWS secret key to use for the Route53 challenge
# @param email sets the contact address for the certificate
# @param key_type sets the public key type
# @param hostname (namevar) sets the CN of the certificate
# @param profile sets the ACME server profile to request for the certificate
define acme::certificate (
  String $hook_script,
  String $aws_access_key_id,
  String $aws_secret_access_key,
  String $email,
  String $key_type = 'ec256',
  String $hostname = $title,
  String $profile = 'tlsserver',
) {
  include acme

  $path = $acme::path

  $hook_file = "${path}/hooks/${hostname}"
  $creds_file = "${path}/creds/${hostname}"
  $renew_file = "${path}/renew/${hostname}"

  $args = [
    '/usr/bin/lego',
    "--path=${path}",
    '--dns=route53',
    "--domains=${hostname}",
    '--accept-tos',
    "--email=${email}",
    "--key-type=${key_type}",
    'run',
    "--run-hook=${hook_file}",
    "--profile=${profile}",
  ]

  file { $creds_file:
    ensure  => file,
    content => template('acme/creds.erb'),
    mode    => '0600',
  }

  -> file { $renew_file:
    ensure  => file,
    content => template('acme/renew.sh.erb'),
    mode    => '0700',
  }

  -> file { $hook_file:
    ensure  => file,
    content => $hook_script,
    mode    => '0755',
  }

  -> exec { "lego-issue-${hostname}":
    command     => $args,
    creates     => "${path}/certificates/${hostname}.crt",
    environment => ["AWS_SHARED_CREDENTIALS_FILE=${creds_file}"],
  }
}
