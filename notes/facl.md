```sh
# set sticky bit to enforce group
chmod -R g+s FOLDER
# set default ACL
setfacl -d -m u:name:rwx FOLDER
# set group ACL
setfacl -d -m g:name:rx FOLDER
```