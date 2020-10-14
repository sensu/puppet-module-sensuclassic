# @summary Adds the Sensu YUM repo support
#
# Adds the Sensu YUM repo support
#
class sensuclassic::repo::yum {

  if $sensuclassic::install_repo  {
    if $sensuclassic::repo_source {
      $url = $sensuclassic::repo_source
    } else {
      $major = $facts.dig('os', 'release', 'major')
      $family = $facts.dig('os', 'family')
      if $::operatingsystem == 'Amazon' {
        # Match all versions like 2018.2
        if $major =~ /^201\d$/ {
          $releasever = '6'
        } else {
          $releasever = '7'
        }
      # el8 packages do not exist, so use el7 packages
      } elsif $family == 'RedHat' and $major == '8' {
        $releasever = '7'
      } else {
        $releasever = '$releasever'
      }
      $url = $sensuclassic::repo ? {
        'unstable'  => "https://sensu.global.ssl.fastly.net/yum-unstable/${releasever}/\$basearch/",
        default     => "https://sensu.global.ssl.fastly.net/yum/${releasever}/\$basearch/"
      }
    }

    yumrepo { 'sensu':
      enabled  => 1,
      baseurl  => $url,
      gpgcheck => 0,
      name     => 'sensu',
      descr    => 'sensu',
      before   => Package[$sensuclassic::package::pkg_title],
    }

    # prep for Enterprise repos
    $se_user = $sensuclassic::enterprise_user
    $se_pass = $sensuclassic::enterprise_pass

    if $sensuclassic::enterprise {
      $se_url  = "http://${se_user}:${se_pass}@enterprise.sensuapp.com/yum/noarch/"

      yumrepo { 'sensu-enterprise':
        enabled  => 1,
        baseurl  => $se_url,
        gpgcheck => 0,
        name     => 'sensu-enterprise',
        descr    => 'sensu-enterprise',
        before   => Package['sensu-enterprise'],
      }
    }

    if $sensuclassic::enterprise_dashboard {
      $dashboard_url = "http://${se_user}:${se_pass}@enterprise.sensuapp.com/yum/\$basearch/"

      yumrepo { 'sensu-enterprise-dashboard':
        enabled  => 1,
        baseurl  => $dashboard_url,
        gpgcheck => 0,
        name     => 'sensu-enterprise-dashboard',
        descr    => 'sensu-enterprise-dashboard',
        before   => Package['sensu-enterprise-dashboard'],
      }
    }
  }
}
