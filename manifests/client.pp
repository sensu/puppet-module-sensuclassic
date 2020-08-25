# @summary Manages the Sensu client service
#
# @param hasrestart Value of hasrestart attribute for this service.
#
# @param log_level Sensu log level to be used Valid values: debug, info, warn,
#   error, fatal
#
# @param windows_logrotate Whether or not to use logrotate on Windows OS
#   family.
#
# @param windows_log_size The integer value for the size of log files on
#   Windows OS family. sizeThreshold in sensu-client.xml.
#
# @param windows_log_number The integer value for the number of log files to
#   keep on Windows OS family. keepFiles in sensu-client.xml.
#
class sensuclassic::client (
  Boolean $hasrestart = $sensuclassic::hasrestart,
  $client_service_enable = $sensuclassic::client_service_enable,
  $client_service_ensure = $sensuclassic::client_service_ensure,
  $log_level = $sensuclassic::log_level,
  $windows_logrotate = $sensuclassic::windows_logrotate,
  $windows_log_size = $sensuclassic::windows_log_size,
  $windows_log_number = $sensuclassic::windows_log_number,
) {

  # Service
  if $sensuclassic::manage_services {

    case $sensuclassic::client {
      true: {
        $service_ensure = $client_service_ensure
        $service_enable = $client_service_enable
        $before_install_service = Exec['install-sensu-client-service']
      }
      default: {
        $service_ensure = 'stopped'
        $service_enable = false
        $before_install_service = undef
      }
    }
    case $::osfamily {
      'windows': {
        $service_name     = 'sensu-client'
        $service_path     = undef
        $service_provider = undef
        file { 'C:/opt/sensu/bin/sensu-client.xml':
          ensure  => file,
          content => template("${module_name}/sensu-client.erb"),
        }

        if $sensuclassic::windows_service_user {
          dsc_userrightsassignment { $sensuclassic::windows_service_user['user']:
            dsc_ensure   => present,
            dsc_policy   => 'Log_on_as_a_service',
            dsc_identity => $sensuclassic::windows_service_user['user'],
            before       => $before_install_service,
          }

          acl { 'C:/opt/sensu':
            purge       => false,
            permissions => [
              {
                'identity' => $sensuclassic::windows_service_user['user'],
                'rights'   => ['full'],
              },
            ],
            before      => $before_install_service,
          }

          $service_user = $sensuclassic::windows_service_user['user']
          $service_password = $sensuclassic::windows_service_user['password']
          $sc_user_args = " obj= \"${service_user}\" password= \"${service_password}\""
        } else {
          $sc_user_args = '' # lint:ignore:empty_string_assignment
        }

        $sensu_client_exe = "C:\\opt\\sensu\\bin\\sensu-client.exe"
        if $sensuclassic::client {
          exec { 'install-sensu-client-service':
            command => "C:\\windows\\system32\\sc.exe create sensu-client start= delayed-auto binPath= ${sensu_client_exe} DisplayName= \"Sensu Client\"${sc_user_args}", # lint:ignore:140chars
            unless  => "C:\\windows\\system32\\sc.exe query sensu-client",
            require => [
              File['C:/opt/sensu/bin/sensu-client.xml'],
              Class['sensuclassic::package'],
              Sensuclassic_client_config[$::fqdn],
              Class['sensuclassic::rabbitmq::config'],
            ],
            notify  => Service['sensu-client'],
          }
        }
      }
      'Darwin': {
        $service_path     = '/Library/LaunchDaemons/org.sensuapp.sensu-client.plist'
        $service_provider = 'launchd'

        file {$service_path:
          ensure => file,
          owner  => 'root',
          group  => 'wheel',
          mode   => '0755',
          before => Service['sensu-client'],
        }
      }
      default: {
        $service_path     = undef
        $service_provider = undef
      }
    }

    service { 'sensu-client':
      ensure     => $service_ensure,
      enable     => $service_enable,
      name       => $sensuclassic::service_name,
      hasrestart => $hasrestart,
      path       => $service_path,
      provider   => $service_provider,
      subscribe  => [
        Class['sensuclassic::package'],
        Sensuclassic_client_config[$::fqdn],
        Class['sensuclassic::rabbitmq::config'],
      ],
    }
  }

  # Config
  if $sensuclassic::_purge_config and !$sensuclassic::client {
    $file_ensure = 'absent'
  } else {
    $file_ensure = 'present'
  }

  file { "${sensuclassic::conf_dir}/client.json":
    ensure => $file_ensure,
    owner  => $sensuclassic::user,
    group  => $sensuclassic::group,
    mode   => $sensuclassic::file_mode,
  }

  if $sensuclassic::client_socket_enabled {
    $socket_config = {
      bind => $sensuclassic::client_bind,
      port => $sensuclassic::client_port,
    }
  } else {
    $socket_config = {
      enabled => false,
    }
  }

  sensuclassic_client_config { $::fqdn:
    ensure         => $file_ensure,
    base_path      => $sensuclassic::conf_dir,
    client_name    => $sensuclassic::client_name,
    address        => $sensuclassic::client_address,
    socket         => $socket_config,
    subscriptions  => $sensuclassic::subscriptions,
    safe_mode      => $sensuclassic::safe_mode,
    custom         => $sensuclassic::client_custom,
    keepalive      => $sensuclassic::client_keepalive,
    redact         => $sensuclassic::redact,
    deregister     => $sensuclassic::client_deregister,
    deregistration => $sensuclassic::client_deregistration,
    registration   => $sensuclassic::client_registration,
    http_socket    => $sensuclassic::client_http_socket,
    servicenow     => $sensuclassic::client_servicenow,
    ec2            => $sensuclassic::client_ec2,
    chef           => $sensuclassic::client_chef,
    puppet         => $sensuclassic::client_puppet,
  }
}
