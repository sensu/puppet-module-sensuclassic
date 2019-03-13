# @summary Installs the Sensu Enterprise Dashboard
#
# Installs the Sensu Enterprise Dashboard
class sensuclassic::enterprise::dashboard (
  Boolean $hasrestart = $sensuclassic::hasrestart,
) {

  # Package
  if $sensuclassic::enterprise_dashboard {
    package { 'sensu-enterprise-dashboard':
      ensure => $sensuclassic::enterprise_dashboard_version,
    }
  }

  # Config
  if $sensuclassic::enterprise_dashboard {
    $ensure = 'present'
  } elsif $sensuclassic::purge =~ Hash {
    if $sensuclassic::purge['config'] {
      $ensure = 'absent'
    } else {
      $ensure = undef
    }
  } elsif $sensuclassic::purge {
    $ensure = 'absent'
  } else {
    $ensure = undef
  }

  if $ensure != undef {
    if $ensure == 'present' {
      $file_ensure = 'file'
    } else {
      $file_ensure = $ensure
    }

    $file_notify = $sensuclassic::manage_services ? {
      true  => $sensuclassic::enterprise_dashboard ? {
        true => $::osfamily ? {
          'windows' => undef,
          default   => Service['sensu-enterprise-dashboard'],
        },
        false => undef,
      },
      false => undef,
    }

    file { "${sensuclassic::etc_dir}/dashboard.json":
      ensure => $file_ensure,
      owner  => 'sensu',
      group  => 'sensu',
      mode   => '0440',
      notify => $file_notify,
    }

    sensuclassic_enterprise_dashboard_config { $::fqdn:
      ensure    => $ensure,
      base_path => $sensuclassic::enterprise_dashboard_base_path,
      host      => $sensuclassic::enterprise_dashboard_host,
      port      => $sensuclassic::enterprise_dashboard_port,
      refresh   => $sensuclassic::enterprise_dashboard_refresh,
      user      => $sensuclassic::enterprise_dashboard_user,
      pass      => $sensuclassic::enterprise_dashboard_pass,
      auth      => $sensuclassic::enterprise_dashboard_auth,
      ssl       => $sensuclassic::enterprise_dashboard_ssl,
      audit     => $sensuclassic::enterprise_dashboard_audit,
      github    => $sensuclassic::enterprise_dashboard_github,
      gitlab    => $sensuclassic::enterprise_dashboard_gitlab,
      ldap      => $sensuclassic::enterprise_dashboard_ldap,
      oidc      => $sensuclassic::enterprise_dashboard_oidc,
      custom    => $sensuclassic::enterprise_dashboard_custom,
      notify    => $file_notify,
    }

    sensuclassic_enterprise_dashboard_api_config { 'api1.example.com':
      ensure => absent,
      notify => $file_notify,
    }

    sensuclassic_enterprise_dashboard_api_config { 'api2.example.com':
      ensure => absent,
      notify => $file_notify,
    }
  }

  # Service
  if $sensuclassic::manage_services and $sensuclassic::enterprise_dashboard {

    $service_ensure = $sensuclassic::enterprise_dashboard ? {
      true  => 'running',
      false => 'stopped',
    }

    if $::osfamily != 'windows' {
      service { 'sensu-enterprise-dashboard':
        ensure     => $service_ensure,
        enable     => $sensuclassic::enterprise_dashboard,
        hasrestart => $hasrestart,
        subscribe  => [
          Package['sensu-enterprise-dashboard'],
          Class['sensuclassic::redis::config'],
        ],
      }
    }
  }
}
