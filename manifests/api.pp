# @summary Manages the Sensu API
#
# @param hasrestart
#   Value of hasrestart attribute for this service.
#
class sensuclassic::api (
  Boolean $hasrestart = $sensuclassic::hasrestart,
) {

  case $::osfamily {
    'Darwin': {
      $service_path     = '/Library/LaunchDaemons/org.sensuapp.sensu-api.plist'
      $service_provider = 'launchd'
    }
    default: {
      $service_path     = undef
      $service_provider = undef
    }
  }

  if $sensuclassic::manage_services {

    case $sensuclassic::api {
      true: {
        $service_ensure = 'running'
        $service_enable = true
      }
      default: {
        $service_ensure = 'stopped'
        $service_enable = false
      }
    }

    if $::osfamily != 'windows' {
      service { $sensuclassic::api_service_name:
        ensure     => $service_ensure,
        enable     => $service_enable,
        hasrestart => $hasrestart,
        path       => $service_path,
        provider   => $service_provider,
        subscribe  => [
          Class['sensuclassic::package'],
          Sensuclassic_api_config[$::fqdn],
          Class['sensuclassic::redis::config'],
          Class['sensuclassic::rabbitmq::config'],
        ],
      }
    }
  }

  if $sensuclassic::_purge_config and !$sensuclassic::server and !$sensuclassic::api and !$sensuclassic::enterprise {
    $file_ensure = 'absent'
  } else {
    $file_ensure = 'present'
  }

  file { "${sensuclassic::etc_dir}/conf.d/api.json":
    ensure => $file_ensure,
    owner  => $sensuclassic::user,
    group  => $sensuclassic::group,
    mode   => $sensuclassic::file_mode,
  }

  sensuclassic_api_config { $::fqdn:
    ensure                => $file_ensure,
    base_path             => "${sensuclassic::etc_dir}/conf.d",
    bind                  => $sensuclassic::api_bind,
    host                  => $sensuclassic::api_host,
    port                  => $sensuclassic::api_port,
    user                  => $sensuclassic::api_user,
    password              => $sensuclassic::api_password,
    ssl_port              => $sensuclassic::api_ssl_port,
    ssl_keystore_file     => $sensuclassic::api_ssl_keystore_file,
    ssl_keystore_password => $sensuclassic::api_ssl_keystore_password,
  }
}
