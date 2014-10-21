# PRIVATE CLASS: do not call directly
class teamcity::account {
  $agent_dir               = $teamcity::agent::agent_dir

  $agent_user              = $teamcity::agent::agent_user
  $agent_user_home         = $teamcity::agent::agent_user_home
  $manage_agent_user_home  = $teamcity::agent::manage_agent_user_home
  $agent_group             = $teamcity::agent::agent_group
  $manage_user             = $teamcity::agent::manage_user
  $manage_group            = $teamcity::agent::manage_group

  if $manage_group {
    if !defined(Group[$agent_group]) {
      group { $agent_group: ensure => 'present', }
    }
  }

  if $manage_user {
    $group_require = $manage_group ? {
      true    => Group[$agent_group],
      default => undef,
    }

    if !defined(User[$agent_user]) {
      $_agent_user_home_real = $agent_user_home ? {
        undef   => $agent_dir,
        default => $agent_user_home,
      }

      user { $agent_user:
        ensure     => 'present',
        home       => $_agent_user_home_real,
        managehome => $manage_agent_user_home,
        gid        => $agent_group,
        shell      => '/bin/sh',
        require    => $group_require,
      }
    }
  }
}
