# @summary Adds the Sensu repo to Apt
#
# Adds the Sensu repo to Apt
#
class sensuclassic::repo::apt {

  if defined(apt::source) {

    $ensure = $sensuclassic::install_repo ? {
      true    => 'present',
      default => 'absent'
    }

    if $sensuclassic::repo_source {
      $url = $sensuclassic::repo_source
    } else {
      $url = 'https://sensu.global.ssl.fastly.net/apt'
    }

    # ignoring the puppet-lint plugin because of a bug that warns on the next
    # line.
    if $sensuclassic::repo_release == undef { #lint:ignore:undef_in_function
      $release = $::facts['os']['distro']['codename']
    } else {
      $release = $sensuclassic::repo_release
    }

    apt::source { 'sensu':
      ensure   => $ensure,
      location => $url,
      release  => $release,
      repos    => $sensuclassic::repo,
      include  => {
        'src' => false,
      },
      key      => {
        'id'     => $sensuclassic::repo_key_id,
        'source' => $sensuclassic::repo_key_source,
      },
      before   => Package[$sensuclassic::package::pkg_title],
      notify   => Exec['apt-update'],
    }

    exec {
      'apt-update':
        refreshonly => true,
        command     => '/usr/bin/apt-get update';
    }

    if $sensuclassic::enterprise {
      $se_user = $sensuclassic::enterprise_user
      $se_pass = $sensuclassic::enterprise_pass
      $se_url  = "http://${se_user}:${se_pass}@enterprise.sensuapp.com/apt"
      $include = { 'src' => false, }
      $key     = {
        'id'      => $sensuclassic::enterprise_repo_key_id,
        # TODO: this is not ideal, but the apt module doesn't currently support
        # HTTP auth for the source URI
        'content' => template('sensuclassic/pubkey.gpg'),
      }

      apt::source { 'sensu-enterprise':
        ensure   => $ensure,
        location => $se_url,
        release  => 'sensu-enterprise',
        repos    => $sensuclassic::repo,
        include  => $include,
        key      => $key,
        before   => Package['sensu-enterprise'],
      }
    }

  } else {
    fail('This class requires puppetlabs-apt module')
  }
}
