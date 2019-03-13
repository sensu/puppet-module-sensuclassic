# @summary Sets the Sensu rabbitmq config
#
# Sets the Sensu rabbitmq config
#
class sensuclassic::rabbitmq::config {

  if $sensuclassic::_purge_config and !$sensuclassic::server and !$sensuclassic::client and !$sensuclassic::enterprise and $sensuclassic::transport_type != 'rabbitmq' {
    $ensure = 'absent'
  } else {
    $ensure = 'present'
  }

  $ssl_dir = "${sensuclassic::etc_dir}/ssl"

  if $sensuclassic::rabbitmq_ssl_cert_chain or $sensuclassic::rabbitmq_ssl_private_key {
    file { $ssl_dir:
      ensure  => directory,
      owner   => $sensuclassic::user,
      group   => $sensuclassic::group,
      mode    => $sensuclassic::dir_mode,
      require => Package[$sensuclassic::package::pkg_title],
    }

    # if provided a cert chain, and its a puppet:// URI, source file form the
    # the URI provided
    if $sensuclassic::rabbitmq_ssl_cert_chain and $sensuclassic::rabbitmq_ssl_cert_chain =~ /^puppet:\/\// {
      file { "${ssl_dir}/cert.pem":
        ensure  => file,
        source  => $sensuclassic::rabbitmq_ssl_cert_chain,
        owner   => $sensuclassic::user,
        group   => $sensuclassic::group,
        mode    => $sensuclassic::file_mode,
        require => File[$ssl_dir],
        before  => Sensuclassic_rabbitmq_config[$::fqdn],
      }

      $ssl_cert_chain = "${ssl_dir}/cert.pem"
    # else provided a cert chain, and the variable actually contains the cert,
    # create the file with conents of the variable
    } elsif $sensuclassic::rabbitmq_ssl_cert_chain and  $sensuclassic::rabbitmq_ssl_cert_chain =~ /BEGIN CERTIFICATE/ {
      file { "${ssl_dir}/cert.pem":
        ensure  => file,
        content => $sensuclassic::rabbitmq_ssl_cert_chain,
        owner   => $sensuclassic::user,
        group   => $sensuclassic::group,
        mode    => $sensuclassic::file_mode,
        require => File[$ssl_dir],
        before  => Sensuclassic_rabbitmq_config[$::fqdn],
      }

      $ssl_cert_chain = "${ssl_dir}/cert.pem"
    # else set the cert to value passed in wholesale, usually this is
    # a raw file path
    } else {
      $ssl_cert_chain = $sensuclassic::rabbitmq_ssl_cert_chain
    }

    # if provided private key, and its a puppet:// URI, source file from the
    # URI provided
    if $sensuclassic::rabbitmq_ssl_private_key and $sensuclassic::rabbitmq_ssl_private_key =~ /^puppet:\/\// {
      file { "${ssl_dir}/key.pem":
        ensure    => file,
        source    => $sensuclassic::rabbitmq_ssl_private_key,
        owner     => $sensuclassic::user,
        group     => $sensuclassic::group,
        mode      => $sensuclassic::file_mode,
        show_diff => false,
        require   => File[$ssl_dir],
        before    => Sensuclassic_rabbitmq_config[$::fqdn],
      }

      $ssl_private_key = "${ssl_dir}/key.pem"
    # else provided private key, and the variable actually contains the key,
    # create file with contents of the variable
    } elsif $sensuclassic::rabbitmq_ssl_private_key and $sensuclassic::rabbitmq_ssl_private_key =~ /BEGIN RSA PRIVATE KEY/ {
      file { "${ssl_dir}/key.pem":
        ensure    => file,
        content   => $sensuclassic::rabbitmq_ssl_private_key,
        owner     => $sensuclassic::user,
        group     => $sensuclassic::group,
        mode      => $sensuclassic::file_mode,
        show_diff => false,
        require   => File[$ssl_dir],
        before    => Sensuclassic_rabbitmq_config[$::fqdn],
      }

      $ssl_private_key = "${ssl_dir}/key.pem"
    # else set the private key to value passed in wholesale, usually this is
    # a raw file path
    } else {
      $ssl_private_key = $sensuclassic::rabbitmq_ssl_private_key
    }
  } else {
    $ssl_cert_chain = undef
    $ssl_private_key = undef
  }

  if ($ssl_cert_chain and $ssl_cert_chain != '') or ($ssl_private_key and $ssl_private_key != '') {
    $enable_ssl = true
  } else {
    $enable_ssl = $sensuclassic::rabbitmq_ssl
  }

  file { "${sensuclassic::conf_dir}/rabbitmq.json":
    ensure => $ensure,
    owner  => $sensuclassic::user,
    group  => $sensuclassic::group,
    mode   => $sensuclassic::file_mode,
    before => Sensuclassic_rabbitmq_config[$::fqdn],
  }

  $has_cluster = !($sensuclassic::rabbitmq_cluster == undef or $sensuclassic::rabbitmq_cluster == [])
  $host = $has_cluster ? { false => $sensuclassic::rabbitmq_host, true => undef, }
  $port = $has_cluster ? { false => $sensuclassic::rabbitmq_port, true => undef, }
  $user = $has_cluster ? { false => $sensuclassic::rabbitmq_user, true => undef, }
  $password = $has_cluster ? { false => $sensuclassic::rabbitmq_password, true => undef, }
  $vhost = $has_cluster ? { false => $sensuclassic::rabbitmq_vhost, true => undef, }
  $ssl_transport = $has_cluster ? { false => $enable_ssl, true => undef, }
  $cert_chain = $has_cluster ? { false => $ssl_cert_chain, true => undef, }
  $private_key = $has_cluster ? { false => $ssl_private_key, true => undef, }
  $prefetch = $has_cluster ? { false => $sensuclassic::rabbitmq_prefetch, true => undef, }
  $base_path = $sensuclassic::conf_dir
  $cluster = $has_cluster ? { true => $sensuclassic::rabbitmq_cluster, false => undef, }
  $heartbeat = $has_cluster ? { false => $sensuclassic::rabbitmq_heartbeat, true => undef, }

  sensuclassic_rabbitmq_config { $::fqdn:
    ensure          => $ensure,
    base_path       => $base_path,
    port            => $port,
    host            => $host,
    user            => $user,
    password        => $password,
    vhost           => $vhost,
    heartbeat       => $heartbeat,
    ssl_transport   => $enable_ssl,
    ssl_cert_chain  => $ssl_cert_chain,
    ssl_private_key => $ssl_private_key,
    prefetch        => $prefetch,
    cluster         => $cluster,
  }
}
