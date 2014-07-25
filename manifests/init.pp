# Class: logical_volume
#
# This class installs and manages a logical volume using the lvcreate command.
#
# Parameters:
#
# *$lv_name* - The name of the new logical volume.
# *$lv_size* - Size of the logical volume as understood by lvcreate(8), defaults to 1G.
# *$vg_name* - Name of volume group. Defaults to vg00.
# *$fstype*  - Filesystem type as understood by mkfs(8). Defaults to ext3.
# *$owner*   - Owner of the directory. Defaults to root.
# *$group*   - Group of the directory. Defaults to root.
# *$mode*    - Mode of the directory. Defaults to '755'
#
# Actions:
#
# 1. lvcreate -L ${lv_size} -n ${lv_name} /dev/${vg_name}
# 2. mkfs -ff -t ${vg_name} /dev/${vg_name}-${lv_name}
# 3. Creates a directory $name
# 4. Mounts the logical volume
#
# Requires: see Modulefile
#
# Sample Usage:
#  logical_volume { '/opt/servers/factfinder':
#    lv_name => 'lvoloptfactfinder',
#    lv_size => '20MB',
#    fstype  => 'reiserfs',
#    vg_name => 'mapper/vg00',
#  }
#
define logical_volume (
  $lv_name,
  $lv_size = '1GB',
  $vg_name = 'vg00',
  $fstype = 'ext3',
  $owner  = 'root',
  $group  = 'root',
  $mode   = '755' )
{

  file { $name:
    ensure => directory,
    owner  => $owner,
    group  => $group,
    mode   => $mode,
  }

  exec { "lvcreate-${vg_name}-${lv_name}":
    path      => [ '/sbin', '/bin', '/usr/sbin', '/usr/bin' ],
    command   => "lvcreate -L ${lv_size} -n ${lv_name} /dev/${vg_name}\
 && mkfs -ff -t ${vg_name} /dev/${vg_name}-${lv_name}",
    unless    => "lvs | grep -q '${lv_name}.*${vg_name}'",
    logoutput => false,
    subscribe => File[ $name ],
  }

  mount { $name:
    ensure  => mounted,
    atboot  => true,
    device  => "/dev/${vg_name}/${lv_name}",
    fstype  => $fstype,
    options => 'defaults',
    dump    => '0',
    pass    => '1',
    require => [ Exec["lvcreate-${vg_name}-${lv_name}"], File[$name] ],
  }
}
