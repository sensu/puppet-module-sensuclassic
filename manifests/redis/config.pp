# @summary Sets the Sensu redis config
#
# Sets the Sensu redis config
#
class sensuclassic::redis::config {

  if $sensuclassic::_purge_config and !$sensuclassic::server and !$sensuclassic::api and !$sensuclassic::enterprise and $sensuclassic::transport_type != 'redis' {
    $ensure = 'absent'
  } else {
    $ensure = 'present'
  }

  # redis configuration may contain "secrets"
  file { "${sensuclassic::etc_dir}/conf.d/redis.json":
    ensure => $ensure,
    owner  => $sensuclassic::user,
    group  => $sensuclassic::group,
    mode   => $sensuclassic::file_mode,
    before => Sensuclassic_redis_config[$::fqdn],
  }

  $has_sentinels = !($sensuclassic::redis_sentinels == undef or $sensuclassic::redis_sentinels == [])
  $host = $has_sentinels ? { false => $sensuclassic::redis_host, true  => undef, }
  $port = $has_sentinels ? { false => $sensuclassic::redis_port, true  => undef, }
  $sentinels = $has_sentinels ? { true  => $sensuclassic::redis_sentinels, false => undef, }
  $master = $has_sentinels ? { true => $sensuclassic::redis_master, false => undef, }

  sensuclassic_redis_config { $::fqdn:
    ensure             => $ensure,
    base_path          => "${sensuclassic::etc_dir}/conf.d",
    host               => $host,
    port               => $port,
    password           => $sensuclassic::redis_password,
    reconnect_on_error => $sensuclassic::redis_reconnect_on_error,
    db                 => $sensuclassic::redis_db,
    auto_reconnect     => $sensuclassic::redis_auto_reconnect,
    sentinels          => $sentinels,
    master             => $master,
    tls                => $sensuclassic::redis_tls,
  }
}
