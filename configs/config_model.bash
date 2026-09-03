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

# Which libvirt to talk to. Some of the forms it takes:
#
#   qemu:///system                     the local one, as root. The default.
#   qemu:///session                    the local one, as your user.
#   qemu+ssh://user@host/system        a remote one, over SSH.
#   qemu+tls://host/system             a remote one, over TLS.
#
# (Optional, Default "qemu:///system")
LIBVIRT_URI='qemu:///system'

# Where libvirt should look for credentials, when the connection asks for them
# (SASL, or TLS with a password). This is libvirt's own mechanism: the file lists
# the user name and the password per service, and libvirt reads it by itself.
#
# An example of its content:
#
#   [credentials-mine]
#   authname=my_user
#   password=my_password
#
#   [auth-libvirt-my.host.name]
#   credentials=mine
#
# Leave it empty to let libvirt use its usual places
# ("$XDG_CONFIG_HOME/libvirt/auth.conf", then "/etc/libvirt/auth.conf").
#
# NOTE: An SSH connection ("qemu+ssh://") does NOT use this. It authenticates the
# way SSH always does, so an SSH key and an entry in "~/.ssh/config" are what that
# one wants.
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
