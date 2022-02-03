#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart

    rlPhaseStartSetup "Install keylime and its dependencies"
        # for RHEL and CentOS Stream configure Sergio's copr repo providing necessary dependencies
        if ! rlIsFedora; then
            rlRun 'cat > /etc/yum.repos.d/keylime.repo <<_EOF
[copr:copr.fedorainfracloud.org:scorreia:keylime-c9s]
name=Copr repo for keylime-c9s owned by scorreia
baseurl=https://download.copr.fedorainfracloud.org/results/scorreia/keylime-c9s/centos-stream-9-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/scorreia/keylime-c9s/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
_EOF'
            RHEL_EXTRA_PKGS="cfssl"
        fi
        rlRun "yum -y install $RHEL_EXTRA_PKGS git-core python3-pip python3-pyyaml python3-tornado python3-simplejson python3-requests python3-sqlalchemy python3-alembic python3-packaging python3-psutil python3-gnupg python3-cryptography libselinux-python3 procps-ng tpm2-abrmd tpm2-tss tpm2-tools python3-zmq patch"
        if [ -d /var/tmp/keylime_sources ]; then
            rlLogInfo "Installing keylime from /var/tmp/keylime_sources"
        else
            rlLogInfo "Installing keylime from cloned upstream repo"
            rlRun "git clone https://github.com/keylime/keylime.git /var/tmp/keylime_sources"
        fi
        rlRun "pushd /var/tmp/keylime_sources"
        # clear files that could be present from previous installation and be disruptive
        # in particular db migration files
        rlRun "rm -rf build/lib/keylime/migrations $( ls -d /usr/local/lib/python*/site-packages/keylime-*/keylime/migrations )"
        rlRun "python3 setup.py install"
        # copy keylime.conf to /etc
        rlRun "cp keylime.conf /etc"
        rlRun "popd"
    rlPhaseEnd

    rlPhaseStartTest "Test installed binaries"
        rlRun "keylime_tenant --help"
    rlPhaseEnd

rlJournalEnd
