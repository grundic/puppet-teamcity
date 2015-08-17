$shell = New-Object -COMObject WScript.Shell;
$shortcut = $shell.CreateShortcut("<%= @shortcut_path %>");
$shortcut.TargetPath = "<%= @agent_dir_win %>\bin\agent.bat";
$shortcut.Arguments = "start";
$shortcut.Description = "Standalone TeamCity agent";
$shortcut.Save();

