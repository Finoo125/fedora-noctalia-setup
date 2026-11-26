# Fedora 45 Minimal Install, unattended, as the README expects: btrfs, UEFI, online.
# Since F45 the "Minimal Install" environment is custom-environment ("Fedora Custom Operating System").
# Used by tests/vm/vm.sh; @SSHKEY@ is filled in there.
cmdline
url --url=https://download.fedoraproject.org/pub/fedora/linux/releases/45/Everything/x86_64/os/
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f45&arch=x86_64

lang de_DE.UTF-8
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
timezone Europe/Berlin --utc
network --bootproto=dhcp --hostname=noctalia-test --activate

zerombr
clearpart --all --initlabel --disklabel=gpt
autopart --type=btrfs
bootloader

rootpw --lock
# A normal user with password sudo, like a real install (password: tester).
user --name=tester --groups=wheel --password=tester --plaintext
sshkey --username=tester "@SSHKEY@"
services --enabled=sshd
firstboot --disable
poweroff

%packages
@^custom-environment
%end
