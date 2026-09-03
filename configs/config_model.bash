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

# < -----------------------------------------

# vcon "inverted (c)" BSD-3-Clause
# Eduardo Lucio Amorim Costa
# Brazil-DF
# https://www.linkedin.com/in/eduardo-software-livre/
