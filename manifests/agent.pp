
class teamcity::agent(
    $agentname,
    $username = $teamcity::params::username,
    $server_url = $teamcity::params::server_url,
    $archive_name = $teamcity::params::archive_name,
    $download_url = $teamcity::params::download_url,
    $agent_dir = $teamcity::params::agent_dir,
    $destination_dir = $teamcity::params::destination_dir,
    $priority =  $teamcity::params::priority,
    ) inherits teamcity::params {

    include users::people
    realize( Useraccount["$username"])

    wget::fetch { "teamcity-buildagent":
        source => "$download_url",
        destination => "/root/$archive_name",
        timeout => 0,
    }

    file { "$destination_dir":
        ensure => "directory",
        require => [ Wget::Fetch["teamcity-buildagent"] ],
    }

    exec { "exctract-build-agent":
        command => "unzip -d $destination_dir/$agent_dir /root/$archive_name && cp $destination_dir/$agent_dir/conf/buildAgent.dist.properties $destination_dir/$agent_dir/conf/buildAgent.properties && chown $username:$username $destination_dir/$agent_dir -R",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin:/opt/local/bin",
        creates => "$destination_dir/$agent_dir",
        require => [ File["$destination_dir"], Useraccount["$username"] ],
        logoutput => "on_failure",
    }

    # make 'bin' folder executable
    file { "$destination_dir/$agent_dir/bin/":
        mode => 755,
        recurse => true,
        require => Exec["exctract-build-agent"],
    }

    augeas { "buildAgent.properties":
        lens    => "Properties.lns",
        incl    => "$destination_dir/$agent_dir/conf/buildAgent.properties",
        changes => [
            "set name $agentname",
            "set serverUrl $server_url",
        ],
        require => Exec["exctract-build-agent"],
    } 

    # init.d script
    file { "/etc/init.d/build-agent":
        owner   => "root",
        group   => "root",
        mode    => 755,
        content => template("teamcity/build-agent.erb"),
        require => File["$destination_dir/$agent_dir/bin/"],
    }

    file { "/etc/profile.d/${priority}-teamcity.sh":
        owner   => "root",
        group   => "root",
        mode    => 755,
        content => template("${module_name}/teamcity-profile.erb"),
    }


    # init.d autostart
    exec { "update-rc.d build-agent defaults":
        cwd => "/etc/init.d/",
        creates => ["/etc/rc0.d/K20build-agent",
                    "/etc/rc1.d/K20build-agent",
                    "/etc/rc2.d/S20build-agent",
                    "/etc/rc3.d/S20build-agent",
                    "/etc/rc4.d/S20build-agent",
                    "/etc/rc5.d/S20build-agent",
                    "/etc/rc6.d/K20build-agent"
                   ],
        require => [ File["/etc/init.d/build-agent"], File["/etc/profile.d/${priority}-teamcity.sh"] ],
    }

    service { "build-agent":
        ensure => running,
        enable => true,
        hasstatus => false,
        require => Exec ["update-rc.d build-agent defaults"],
    }
}
