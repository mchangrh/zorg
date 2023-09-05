# universal tune
```sh
zfs set atime=off
zfs set xattr=sa
```

# media
videos + large backups
```sh
zfs set recordsize=1M
zfs set compression=lz4
```

# tank
apps storage and /home
```sh
zfs set compression=zstd
```