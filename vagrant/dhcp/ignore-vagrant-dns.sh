if ! which chattr >& /dev/null
then
    echo 'Installing Filesystem Utilities.'
    if which yum >& /dev/null
    then
        yum --assumeyes --quiet --errorlevel=0 --nogpgcheck install e2fsprogs || exit 2
    elif which apt-get >& /dev/null
    then
        apt-get --yes --quiet=2 --no-install-recommend install e2fsprogs || exit 2
    elif which pacman >& /dev/null
    then
        pacman --sync --noconfirm --noprogressbar --needed --quiet e2fsprogs || exit 2
    else
        echo 'No supported package manager found.' 1>&2
        exit 3
    fi
else
    echo 'Filesystem Utilities already installed.'
fi

if [[ -L /etc/resolv.conf ]]
then
    rm /etc/resolv.conf
fi

cat <<EOF > /etc/resolv.conf
search $VAGRANT_DHCP_DOMAIN
nameserver $VAGRANT_DHCP_IP
EOF

chown root:root /etc/resolv.conf
chmod 644 /etc/resolv.conf
chattr +i /etc/resolv.conf
