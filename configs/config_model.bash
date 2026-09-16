#!/bin/bash

# VCON - Configuration model.
#
# THIS FILE IS OPTIONAL. The defaults below are what a local libvirt wants, which
# is the common case, and "vcon" runs without any configuration at all. Copy it
# only when yours differs:
#
#   cp configs/config_model.bash configs/config.bash
#
# The copy is ignored by git, so the addresses and paths of your machine never end
# up in a commit.
#
# SYNTAX WARNING:
#  There must be NO spaces around the "=" sign. In Bash "VAR = value" is not an
# assignment, it is an attempt to run a command named "VAR".

# > -----------------------------------------
# VCON CONFIGURATION

# Which libvirt to talk to. The scheme picks BOTH where to connect and how the
# connection is authenticated -- there is no single "libvirt login":
#
#   qemu:///system              local, as root. Authenticated by POLKIT, on the
#                               uid of the caller. Being in the "libvirt" group
#                               is what grants it. The default.
#   qemu:///session             local, as your own user. Your own VMs only.
#   qemu+ssh://user@host/system remote, over SSH. Authenticated BY SSH: a key, or
#                               the password SSH itself asks for. libvirt runs the
#                               "ssh" binary here, so it cannot feed a password to
#                               it -- see the note under LIBVIRT_AUTH_FILE.
#   qemu+libssh2://user@host/system  remote, over SSH, using the libssh2 library
#                               instead of the "ssh" binary. This one goes through
#                               the libvirt authentication callback, so a password
#                               CAN come from the auth file.
#   qemu+libssh://user@host/system   the same, with libssh.
#   qemu+tcp://host/system      remote, plain TCP. Authenticated by SASL, with a
#                               user name and a password of libvirt's own
#                               ("saslpasswd2"), unrelated to system accounts.
#   qemu+tls://host/system      remote, over TLS with x509 certificates, and SASL
#                               on top of it when the server asks for it.
#
# (Optional, Default "qemu:///system")
LIBVIRT_URI='qemu:///system'

# Where libvirt should look for credentials, for the connections that ask for
# them. This is libvirt's own mechanism, not one of ours: the file lists the
# credentials per service and libvirt reads it by itself. Its content:
#
#   [credentials-mine]
#   authname=my_user          # for SASL
#   username=my_user          # for SSH and the ESX family
#   password=my_password
#
#   [auth-libvirt-my.host.name]
#   credentials=mine
#
# Leave it empty to let libvirt use its usual places, in this order: the
# "authfile=" parameter of the URI, then "$XDG_CONFIG_HOME/libvirt/auth.conf",
# then "/etc/libvirt/auth.conf".
#
# IMPORTANT: "qemu+ssh://" does NOT use this file. That transport runs the "ssh"
# binary, which reads a password from the terminal, and libvirt has no way of
# handing one over. A password in a file only reaches SSH through
# "qemu+libssh2://" or "qemu+libssh://", which speak the protocol in process.
# For "qemu+ssh://" the answers are an SSH KEY, which asks nothing, or SSH's own
# "ControlMaster", which asks once and reuses the connection.
#
# WHY THIS MATTERS MORE THAN IT LOOKS: building the list opens a connection per
# question -- four per VM. Left to prompt, that is four passwords per machine
# just to draw a menu. Any of the three ways out above turns it into none, or one.
#
# (Optional, Default empty)
LIBVIRT_AUTH_FILE=''

# How long to wait, in seconds, for the console of a VM that was just started. The
# pty comes up a moment after the machine does, and attaching before it exists
# gets you an error instead of a console.
# (Optional, Default 90)
START_TIMEOUT=90

# How long to wait, in seconds, for a VM that was just started to have an address.
# It has to boot far enough to ask for one, which takes longer than the machine
# itself takes to come up. Only used for SSH.
# (Optional, Default 60)
IP_TIMEOUT=60

# --- SSH ---
# SSH is what a plain number connects with, since it is a terminal citizen:
# scrollback, resizing, your keys, scp, port forwarding. The serial console is
# behind a "t" for when the network is what broke.

# User name for the SSH connections, for the machines that have nothing said about
# them below.
#
# Leaving it empty is fine, and is what most people should do: nothing is guessed,
# and you are asked at most ONCE per machine -- the answer is kept and used from
# then on. It is not asked at all when ssh already gets into that host on its own,
# with a key and whatever "~/.ssh/config" says.
#
# (Optional, Default empty)
SSH_USER=''

# How long to wait, in seconds, while finding out whether ssh gets in on its own.
# That check runs before asking anything, and only when nothing else named a user.
# (Optional, Default 5)
SSH_PROBE_TIMEOUT=5

# User name per machine, keyed by the name of the domain. This is what a lab of
# mixed guests wants: one of them answers to "root", another to your own name,
# and neither should have to be typed twice.
#
#   declare -A SSH_USERS=(
#       [CentOS_7.X_AMD64_LBRAD]='root'
#       [dev-box]='eduardolac'
#   )
#
# (Optional, Default empty)
declare -A SSH_USERS=()

# NOTE: "~/.ssh/config" is read here as it is everywhere else, and is the better
# place for anything ssh already knows how to express -- a jump host, a
# particular key, a port:
#
#   Host 192.168.122.*
#       User root
#       IdentityFile ~/.ssh/id_lab
#
# Leaving SSH_USER and SSH_USERS empty and answering the question with an empty
# line hands the choice entirely to ssh, "User" lines included.
#
# WHAT IS REMEMBERED: the answer to that question is kept per machine, in
# "$XDG_STATE_HOME/vcon/ssh-users" ("~/.local/state/vcon/ssh-users" by default).
# It lives there and not here because it is written by the program, not by you --
# and this folder is a git working tree. To change one, connect once with
# "vcon -u OTHER_USER NAME"; to forget them all, delete that file.

# Port, when it is not 22.
# (Optional, Default empty)
SSH_PORT=''

# Anything else to hand to ssh, as an array. An array and not a string, so that a
# value with a space in it survives.
#
#   SSH_OPTS=(-o StrictHostKeyChecking=accept-new)
#
# (Optional, Default empty)
SSH_OPTS=()

# < -----------------------------------------

# vcon "inverted (c)" BSD-3-Clause
# Eduardo Lucio Amorim Costa
# Brazil-DF
# https://www.linkedin.com/in/eduardo-software-livre/
