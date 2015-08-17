$shell = New-Object -COMObject Shell.Application;
$zipfile = $shell.NameSpace("<%= @temp_dir_win %>\<%= @archive_name %>");
foreach($item in $zipfile.Items()){$shell.NameSpace("<%= @agent_dir_win %>").CopyHere($item, "20")};

