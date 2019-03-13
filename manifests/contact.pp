# @summary Manages contact routing
#
# Manage [Contact
# Routing](https://sensuapp.org/docs/latest/enterprise/contact-routing.html)
# configuration with Sensu Enterprise.
#
# Note:  If the `sensu::purge_config` class parameter is `true`, unmanaged
# sensu::contact resources located in /etc/sensu/conf.d/contacts will be purged.
#
# @param ensure Whether the check should be present or not.
#
# @param base_path Where to place the contact JSON configuration file. Defaults
#   to `undef` which defers to the behavior of the underlying sensuclassic_contact type.
#
# @param config The configuration data for the contact. This is an arbitrary hash to
#   accommodate the various communication channels. For example, `{ "email": {
#   "to": "support@example.com" } }`.
#
define sensuclassic::contact (
  Enum['present','absent'] $ensure = 'present',
  Optional[String] $base_path = undef,
  Hash $config = {},
) {

  include sensuclassic

  $file_ensure = $ensure ? {
    'absent' => 'absent',
    default  => 'file'
  }

  # handler configuration may contain "secrets"
  file { "${sensuclassic::conf_dir}/contacts/${name}.json":
    ensure => $file_ensure,
    owner  => $sensuclassic::user,
    group  => $sensuclassic::group,
    mode   => $sensuclassic::config_file_mode,
    before => Sensuclassic_contact[$name],
  }

  sensuclassic_contact { $name:
    ensure    => $ensure,
    config    => $config,
    base_path => $base_path,
    require   => File["${sensuclassic::conf_dir}/contacts/${name}.json"],
  }
}
