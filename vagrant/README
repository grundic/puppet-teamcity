Install dependent modules
========================
Run this from root:
```
puppet module install badgerious-windows_env
puppet module install maestrodev-wget
puppet module install puppet-download_file
puppet module install puppetlabs-stdlib --force
puppet module install puppetlabs-inifile
```

Also it's worth to update packages:
```apt-get update```

Install Java
============
You can install Java package whatever way you like. In order to make things simpler
in Vagrant environment we will use Puppet.

In Linux add 'puppetlabs/java' module:
```puppet module install puppetlabs-java```

In Windows add 'counsyl/windows' module:
```puppet module install counsyl-windows```

Apply manifest
==============
Run this command on Linux to apply sample manifest:
```puppet apply /etc/puppet/manifests/site.pp```

On Windows you have to add shared folder in Virtulal Box and set it automount to true.
Next, create symbolic link for teamcity module:
```mklink /D C:\ProgramData\PuppetLabs\puppet\etc\modules\teamcity \\VBOXSVR\<SHARE-NAME>```

And apply manifest:
```puppet apply \\VBOXSVR\<SHARE-NAME>\vagrant\manifests\site.pp```
