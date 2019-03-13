# @summary Manages the Sensu server service
#
# Manages the Sensu server service
#
# @param hasrestart Value of hasrestart attribute for this service.
#
class sensuclassic::server::service (
  Boolean $hasrestart = $sensuclassic::hasrestart,
  $server_service_enable = $sensuclassic::server_service_enable,
  $server_service_ensure = $sensuclassic::server_service_ensure,
) {

  if $sensuclassic::manage_services {

    case $sensuclassic::server {
      true: {
        $ensure = $server_service_ensure
        $enable = $server_service_enable
      }
      default: {
        $ensure = 'stopped'
        $enable = false
      }
    }

    # The server is only supported on Linux
    if $::kernel == 'Linux' {
      service { 'sensu-server':
        ensure     => $ensure,
        enable     => $enable,
        hasrestart => $hasrestart,
        subscribe  => [
          Class['sensuclassic::package'],
          Sensuclassic_api_config[$::fqdn],
          Class['sensuclassic::redis::config'],
          Class['sensuclassic::rabbitmq::config'],
        ],
      }
    }
  }
}
