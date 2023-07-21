# @summary Create a certificate
#
# @param hook_script sets the code to run after the certificate is updated
# @param aws_access_key_id sets the AWS key to use for Route53 challenge
# @param aws_secret_access_key sets the AWS secret key to use for the Route53 challenge
# @param email sets the contact address for the certificate
# @param hostname (namevar) sets the CN of the certificate
define acme::certificate (
  String $hook_script,
  String $aws_access_key_id,
  String $aws_secret_access_key,
  String $email,
  String $hostname = $title,
) {
  include acme

  $hook_file = "${acme::path}/hook-${hostname}"

  $args = [
    '/usr/bin/lego',
    "--path=${acme::path}",
    '--dns=route53',
    "--domains=${hostname}",
    '--accept-tos',
    "--email=${email}",
    'run',
    "--run-hook=${hook_file}",
  ]

  file { $hook_file:
    ensure  => file,
    content => $hook_script,
    mode    => '0755',
  }

  -> exec { "lego-issue-${hostname}":
    command => $args,
    creates => "${acme::path}/${hostname}.crt",
  }
}
