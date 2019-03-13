# @summary Installs Sensu packages
#
# Installs the Sensu packages
#
# @param conf_dir The default configuration directory.
#
# @param confd_dir Additional directories to load configuration
#   snippets from.
#
# @param heap_size Value of the HEAP_SIZE environment variable.
#   Note: This has no effect on sensu-core.
#
# @param config_file Value of the CONFIG_FILE environment variable.
#
# @param deregister_handler The handler to use when deregistering a client on stop.
#
# @param deregister_on_stop Whether the sensu client should deregister from the API on service stop
#
# @param gem_path Paths to add to GEM_PATH if we need to look for different dirs.
#
# @param init_stop_max_wait Number of seconds to wait for the init stop script to run
#
# @param log_dir Sensu log directory to be used
#   Valid values: Any valid log directory path, accessible by the sensu user
#
# @param log_level Sensu log level to be used
#   Valid values: debug, info, warn, error, fatal
#
# @param path Used to set PATH in /etc/default/sensu
#
# @param env_vars Additional environment variables for /etc/default/sensu
#
# @param rubyopt Ruby opts to be passed to the sensu services
#
# @param use_embedded_ruby If the embedded ruby should be used, e.g. to install the
#   sensu-plugin gem. This value is overridden by a defined
#   sensu_plugin_provider. Note, the embedded ruby should always be used to
#   provide full compatibility. Using other ruby runtimes, e.g. the system
#   ruby, is not recommended.
#
class sensuclassic::package (
  Optional[String] $conf_dir = $sensuclassic::conf_dir,
  Variant[String,Array,Undef] $confd_dir = $sensuclassic::confd_dir,
  Variant[Undef,Integer,Pattern[/^(\d+)/]] $heap_size = $sensuclassic::heap_size,
  Variant[Stdlib::Absolutepath,Undef] $config_file = $sensuclassic::config_file,
  Optional[String] $deregister_handler = $sensuclassic::deregister_handler,
  Optional[Boolean] $deregister_on_stop = $sensuclassic::deregister_on_stop,
  Optional[String] $gem_path = $sensuclassic::gem_path,
  Variant[Undef,Integer,Pattern[/^(\d+)$/]] $init_stop_max_wait = $sensuclassic::init_stop_max_wait,
  Optional[String] $log_dir = $sensuclassic::log_dir,
  Optional[String] $log_level = $sensuclassic::log_level,
  Optional[String] $path = $sensuclassic::path,
  Optional[Hash[String[1], Variant[String, Boolean, Integer]]] $env_vars = $sensuclassic::env_vars,
  Optional[String] $rubyopt = $sensuclassic::rubyopt,
  Optional[Boolean] $use_embedded_ruby = $sensuclassic::use_embedded_ruby,
) {

  case $::osfamily {
    'Darwin': {
      $pkg_provider = 'pkgdmg'
      $pkg_source   = '/tmp/sensu-installer.dmg'
      $pkg_require  = "Remote_file[${pkg_source}]"
      $pkg_title    = 'sensu'
      $pkg_version  = $sensuclassic::version
      $service_name = 'org.sensuapp.sensu-client'

      remote_file { $pkg_source:
        ensure => present,
        source => "https://repositories.sensuapp.org/osx/${::macosx_productversion_major}/x86_64/sensu-${pkg_version}.dmg",
      }
    }

    'Debian': {
      $pkg_title    = 'sensu'
      $pkg_name     = 'sensu'
      $pkg_version  = $sensuclassic::version
      $pkg_source   = undef
      $pkg_provider = undef
      $service_name = 'sensu-client'

      if $sensuclassic::manage_repo {
        class { 'sensuclassic::repo::apt': }
      }
      if $sensuclassic::manage_repo and $sensuclassic::install_repo {
        include ::apt
        $pkg_require = Class['apt::update']
      }
      else {
        $pkg_require = undef
      }
    }

    'RedHat': {
      $pkg_title = 'sensu'
      $pkg_name = 'sensu'
      $pkg_version = $sensuclassic::version
      $pkg_source = undef
      $pkg_provider = undef
      $service_name = 'sensu-client'

      if $sensuclassic::manage_repo {
        class { 'sensuclassic::repo::yum': }
      }

      $pkg_require = undef
    }

    'windows': {
      $repo_require = undef

      # $pkg_version is passed to Package[sensu] { ensure }. The Windows MSI
      # provider translates hyphens to dots, e.g. '0.29.0-11' maps to
      # '0.29.0.11' on the system. This mapping is necessary to converge.
      $pkg_version = regsubst($sensuclassic::version, '-', '.')
      # The version used to construct the download URL.
      $pkg_url_version = $sensuclassic::version ? {
        'installed' => 'latest',
        default     => $sensuclassic::version,
      }
      # The title used for consistent relationships in the Puppet catalog
      $pkg_title = $sensuclassic::windows_package_title
      # The name used by the provider to compare to Windows Add/Remove programs.
      $pkg_name = $sensuclassic::windows_package_name
      $service_name = 'sensu-client'

      # The user can override the computation of the source URL. This URL is
      # used with the remote_file resource, it is not used with the chocolatey
      # package provider.
      if $sensuclassic::windows_pkg_url {
        $pkg_url = $sensuclassic::windows_pkg_url
      } else {
        # The OS Release specific sub-folder
        $os_release = $facts['os']['release']['major']
        # e.g. '2012 R2' => '2012r2'
        $pkg_url_dir = regsubst($os_release, '^(\d+)\s*[rR](\d+)', '\\1r\\2')
        $pkg_arch = $facts['os']['architecture']
        $pkg_url = "${sensuclassic::windows_repo_prefix}/${pkg_url_dir}/sensu-${pkg_url_version}-${pkg_arch}.msi"
      }

      if $sensuclassic::windows_package_provider == 'chocolatey' {
        $pkg_provider = 'chocolatey'
        if $sensuclassic::windows_choco_repo {
          $pkg_source = $sensuclassic::windows_choco_repo
        } else {
          $pkg_source = undef
        }
        $pkg_require = undef
      } else {
        # Use Puppet's default package provider
        $pkg_provider = undef
        # Where the MSI is downloaded to and installed from.
        $pkg_source = "C:\\Windows\\Temp\\sensu-${pkg_url_version}.msi"
        $pkg_require = "Remote_file[${pkg_title}]"

        # path matches Package[sensu] { source => $pkg_source }
        remote_file { $pkg_title:
          ensure   => present,
          path     => $pkg_source,
          source   => $pkg_url,
          checksum => $sensuclassic::package_checksum,
        }
      }
    }

    default: { fail("${::osfamily} not supported yet") }

  }

  case $::osfamily {
    'Darwin': {
      package { $pkg_title:
        ensure   => present,
        source   => $pkg_source,
        require  => $pkg_require,
        provider => $pkg_provider,
      }
    }
    default: {
      package { $pkg_title:
        ensure   => $pkg_version,
        name     => $pkg_name,
        source   => $pkg_source,
        require  => $pkg_require,
        provider => $pkg_provider,
      }
    }
  }

  if $sensuclassic::sensu_plugin_provider {
    $plugin_provider = $sensuclassic::sensu_plugin_provider
  } else {
    $plugin_provider = $sensuclassic::use_embedded_ruby ? {
      true    => 'sensuclassic_gem',
      default => 'gem',
    }
  }

  if $plugin_provider =~ /gem/ and $sensuclassic::gem_install_options {
    package { $sensuclassic::sensu_plugin_name :
      ensure          => $sensuclassic::sensu_plugin_version,
      provider        => $plugin_provider,
      install_options => $sensuclassic::gem_install_options,
    }
  } else {
    package { $sensuclassic::sensu_plugin_name :
      ensure   => $sensuclassic::sensu_plugin_version,
      provider => $plugin_provider,
    }
  }

  if $::osfamily != 'windows' {
    $template_content = $::osfamily ? {
      'Darwin' => 'EMBEDDED_RUBY=true',
      default  => template("${module_name}/sensu.erb")
    }
    file { '/etc/default/sensu':
      ensure  => file,
      content => $template_content,
      owner   => '0',
      group   => '0',
      mode    => '0444',
      require => Package[$pkg_title],
    }
  }

  file { [ $conf_dir, "${conf_dir}/handlers", "${conf_dir}/checks", "${conf_dir}/filters", "${conf_dir}/extensions", "${conf_dir}/mutators", "${conf_dir}/contacts" ]:
    ensure  => directory,
    owner   => $sensuclassic::user,
    group   => $sensuclassic::group,
    mode    => $sensuclassic::dir_mode,
    purge   => $sensuclassic::_purge_config,
    recurse => true,
    force   => true,
    require => Package[$pkg_title],
  }

  if $sensuclassic::manage_handlers_dir {
    file { "${sensuclassic::etc_dir}/handlers":
      ensure  => directory,
      mode    => $sensuclassic::dir_mode,
      owner   => $sensuclassic::user,
      group   => $sensuclassic::group,
      purge   => $sensuclassic::_purge_handlers,
      recurse => true,
      force   => true,
      require => Package[$pkg_title],
    }
  }

  file { ["${sensuclassic::etc_dir}/extensions", "${sensuclassic::etc_dir}/extensions/handlers"]:
    ensure  => directory,
    mode    => $sensuclassic::dir_mode,
    owner   => $sensuclassic::user,
    group   => $sensuclassic::group,
    purge   => $sensuclassic::_purge_extensions,
    recurse => true,
    force   => true,
    require => Package[$pkg_title],
  }

  if $sensuclassic::manage_mutators_dir {
    file { "${sensuclassic::etc_dir}/mutators":
      ensure  => directory,
      mode    => $sensuclassic::dir_mode,
      owner   => $sensuclassic::user,
      group   => $sensuclassic::group,
      purge   => $sensuclassic::_purge_mutators,
      recurse => true,
      force   => true,
      require => Package[$pkg_title],
    }
  }

  if $sensuclassic::_manage_plugins_dir {
    file { "${sensuclassic::etc_dir}/plugins":
      ensure  => directory,
      mode    => $sensuclassic::dir_mode,
      owner   => $sensuclassic::user,
      group   => $sensuclassic::group,
      purge   => $sensuclassic::_purge_plugins,
      recurse => true,
      force   => true,
      require => Package[$pkg_title],
    }
  }

  if $sensuclassic::spawn_limit {
    $spawn_config = { 'sensu' => { 'spawn' => { 'limit' => $sensuclassic::spawn_limit } } }
    $spawn_template = '<%= require "json"; JSON.pretty_generate(@spawn_config) + $/ %>'
    $spawn_ensure = 'file'
    $spawn_content = inline_template($spawn_template)
    if $sensuclassic::client and $sensuclassic::manage_services {
      $spawn_notify = [
        Service[$service_name],
        Class['sensuclassic::server::service'],
      ]
    } elsif $sensuclassic::manage_services {
      $spawn_notify = [ Class['sensuclassic::server::service'] ]
    } else {
      $spawn_notify = undef
    }
  } else {
    $spawn_ensure = undef
    $spawn_content = undef
    $spawn_notify = undef
  }

  file { "${sensuclassic::etc_dir}/conf.d/spawn.json":
    ensure  => $spawn_ensure,
    content => $spawn_content,
    mode    => $sensuclassic::dir_mode,
    owner   => $sensuclassic::user,
    group   => $sensuclassic::group,
    require => Package[$pkg_title],
    notify  => $spawn_notify,
  }

  if $sensuclassic::manage_user and $::osfamily != 'windows' {
    user { $sensuclassic::user:
      ensure  => 'present',
      system  => true,
      home    => $sensuclassic::home_dir,
      shell   => $sensuclassic::shell,
      require => Group[$sensuclassic::group],
      comment => 'Sensu Monitoring Framework',
    }

    group { $sensuclassic::group:
      ensure => 'present',
      system => true,
    }
  } elsif $sensuclassic::manage_user and $::osfamily == 'windows' {
    notice('Managing a local windows user is not implemented on windows')
  }

  file { "${sensuclassic::etc_dir}/config.json": ensure => absent }
}
