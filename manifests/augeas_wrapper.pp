define teamcity::augeas_wrapper ($key, $value) {
  augeas{ "some_file":
    changes => [ "set $key $val" ]
  }
}
