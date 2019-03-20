class { 'sensuclassic':
  rabbitmq_password     => 'correct-horse-battery-staple',
  rabbitmq_host         => '192.168.156.10',
  rabbitmq_vhost        => '/sensu',
  subscriptions         => 'all',
  client_address        => $::ipaddress_eth1,
  sensu_plugin_provider => 'sensuclassic_gem',
}
