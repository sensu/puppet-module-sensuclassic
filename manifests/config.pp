# @summary Defines Sensu check configurations
#
# This define manages Sensu check configurations.
#
# @param ensure Whether the check should be present or not Valid values:
#   present, absent
#
# @param config Check configuration for the client to use
#
# @param event Configuration to send with the event to handlers
#
define sensuclassic::config (
  Enum['present','absent'] $ensure = 'present',
  Optional[Hash] $config = undef,
  Optional[Hash] $event  = undef,
) {

  include sensuclassic

  file { "${sensuclassic::conf_dir}/checks/config_${name}.json":
    ensure => $ensure,
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0444',
    before => Sensuclassic_check[$name],
  }

  sensuclassic_check_config { $name:
    ensure => $ensure,
    config => $config,
    event  => $event,
    notify => $sensuclassic::client_service,
  }
}
