if ! which python >& /dev/null
then
    echo 'Installing Python.'
    if which yum >& /dev/null
    then
        yum --assumeyes --quiet --errorlevel=0 --nogpgcheck install python || exit 2
    elif which apt-get >& /dev/null
    then
        apt-get --yes --quiet=2 --no-install-recommend install python || exit 2
    elif which pacman >& /dev/null
    then
        pacman --sync --noconfirm --noprogressbar --needed --quiet python || exit 2
    else
        echo 'No supported package manager found.' 1>&2
        exit 3
    fi
else
    echo 'Python already installed.'
fi
