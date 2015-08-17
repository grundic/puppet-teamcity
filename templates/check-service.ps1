if (Get-WmiObject -Class Win32_Service -Filter "Name='TCBuildAgent'") {
  exit 1;
} else {
  exit 0;
}
