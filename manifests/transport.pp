# @summary Configures Sensu transport
#
# Configure Sensu Transport
#
class sensuclassic::transport {

  case $::osfamily {
    'Darwin': {
      $ensure = present
    }
    default: {
      if $sensuclassic::transport_type == 'redis'
      or $sensuclassic::transport_type == 'rabbitmq' {
        $ensure = 'present'
      } else {
        $ensure = 'absent'
      }
    }
  }

  $transport_type_hash = {
    'transport' => {
      'name'               => $sensuclassic::transport_type,
      'reconnect_on_error' => $sensuclassic::transport_reconnect_on_error,
    },
  }

  $file_mode = $::osfamily ? {
    'windows' => undef,
    default   => '0440',
  }

  file { "${sensuclassic::conf_dir}/transport.json":
    ensure  => $ensure,
    owner   => $sensuclassic::user,
    group   => $sensuclassic::group,
    mode    => $file_mode,
    content => inline_template('<%= JSON.pretty_generate(@transport_type_hash) %>'),
    notify  => $sensuclassic::check_notify,
  }
}
