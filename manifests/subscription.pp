# @summary Manages Sensu subscriptions
#
# This define manages Sensu subscriptions
#
# @param ensure Whether the check should be present or not
#
# @param custom Custom client variables
#
define sensuclassic::subscription (
  Enum['present','absent'] $ensure = 'present',
  Hash $custom = {},
) {

  include sensuclassic

  # Remove any from title any char which is not a letter, a number
  # or the . and - chars. Needed for safe path names.
  $sanitized_name=regsubst($name, '[^0-9A-Za-z.-]', '_', 'G')

  file { "${sensuclassic::conf_dir}/subscription_${sanitized_name}.json":
    ensure => $ensure,
    owner  => $sensuclassic::user,
    group  => $sensuclassic::group,
    mode   => $sensuclassic::file_mode,
    before => Sensuclassic_client_subscription[$name],
  }

  sensuclassic_client_subscription { $name:
    ensure    => $ensure,
    base_path => $sensuclassic::conf_dir,
    file_name => "subscription_${sanitized_name}.json",
    custom    => $custom,
    notify    => $sensuclassic::client_service,
  }
}
