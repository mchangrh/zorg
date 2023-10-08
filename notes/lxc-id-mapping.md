`/etc/pve/LXCID.conf`

# actual idmap
`lxc.idmap: u 0 995 1`
# supplement

lxc.idmap = g 0 100000 65535
lxc.idmap = u 1 100000 65535

/etc/subuid
root:995:1

# adding users
useradd -MNr username
- no home, no group, system account

set no home
`usermod -d /nonexistent username`

set no login shell
`usermod -s /usr/sbin/nologin username`