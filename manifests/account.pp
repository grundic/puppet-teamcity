# PRIVATE CLASS: do not call directly
class teamcity::account {
  if $::teamcity::manage_group {
    if !defined(Group[$::teamcity::agent_group]) {
      group { $::teamcity::agent_group: ensure => 'present' }
    }
  }

  if $::teamcity::manage_user {
    $group_require = $::teamcity::manage_group ? {
      true    => Group[$::teamcity::agent_group],
      default => undef,
    }

    if !defined(User[$::teamcity::agent_user]) {
      $_agent_user_home_real = $::teamcity::agent_user_home ? {
        undef   => $::teamcity::agent_dir,
        default => $::teamcity::agent_user_home,
      }

      user { $::teamcity::agent_user:
        ensure     => 'present',
        home       => $_agent_user_home_real,
        managehome => $::teamcity::manage_agent_user_home,
        gid        => $::teamcity::agent_group,
        shell      => '/bin/sh',
        require    => $group_require,
      }
    }
  }
}
