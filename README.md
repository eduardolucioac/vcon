# vcon

Opens the **serial console** of a libvirt/KVM virtual machine and puts the name of
that machine on the **terminal tab title**, so you can tell your terminals apart.
With no argument it lists what you can connect to — running or not — and **starts
the one you pick** if it is switched off.

**IMPORTANT:** My life, my work and my passion is free software. Corrections, tweaks and improvements are very welcome (**pull requests** 😉)! Please consider giving us a ⭐, fork, support this project or even visit our professional profile (see [About](#about)). **Thanks!** 🤗

**Support free software and my work!** ❤️🐧

## Table of Contents

- [Why](#why)
- [How it works](#how-it-works)
- [Requirements](#requirements)
   * [On the host](#on-the-host)
   * [On the guest](#on-the-guest)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Why a serial console and not SSH](#why-a-serial-console-and-not-ssh)
- [Troubleshooting](#troubleshooting)
   * [The console is blank](#the-console-is-blank)
   * [My VM is not listed](#my-vm-is-not-listed)
   * [The tab title does not change](#the-tab-title-does-not-change)
   * [I am stuck inside the console](#i-am-stuck-inside-the-console)
- [About](#about)

---

## Why

`virsh console` works, but it tells you nothing about where you are. Every tab
reads `~ : virsh`, and with three of them open you are guessing.

Konsole does solve this for SSH — it recognizes the command, reads its arguments
and switches to the "remote tab title format", which is why an SSH tab shows
`(root) 192.168.122.240`. That recognition lives in a hardcoded `SSHProcessInfo`
class, though, and there is no equivalent for `virsh`. No setting adds one.

So `vcon` fills the title in itself, and puts it back when you leave.

---

## How it works

1. It lists every machine that has a **console device in its domain XML**,
   marked `[running]` or `[shutoff]`, with the IP each running one got from the
   DHCP of the `default` network;
2. You pick one;
3. If it is switched off, it is **started**, and the script waits for the console
   to come up — the pty appears a moment after the machine does, and attaching
   before it exists gets you an error instead of a console;
4. It sets the tab title to `(console) VM_NAME IP`;
5. It hands over to `virsh console`;
6. On exit, the original title comes back.

The listing reads the domain XML rather than asking `virsh ttyconsole`, which
only answers for a machine that is already running — and the stopped ones are
exactly what this needs to show.

The title is set through the D-Bus interface of Konsole when there is one, and
through the OSC escape sequences otherwise, so other terminals are covered too.

---

## Requirements

### On the host

- `libvirt` (`virsh`), obviously;
- `qdbus6` for the tab title on Konsole. Without it the script still runs, it just
  cannot rename the tab.

### On the guest

**This is the part that is easy to miss.** The `<console type='pty'>` device comes
by default in the domain XML, so `virsh console` connects — but it shows a **blank
screen** until the guest speaks on that serial port and runs a `getty` on it.

On a systemd guest (Debian, RHEL, CentOS, Ubuntu...):

```sh
grubby --update-kernel=ALL --args="console=tty0 console=ttyS0,115200n8"
systemctl enable serial-getty@ttyS0.service
```

Then reboot the guest.

**TIP:** Keep `console=tty0` beside `console=ttyS0`. In Linux the **last**
`console=` wins for `/dev/console`, but declaring both sends the boot messages to
both places — you gain the serial console without losing the graphical one.

On a guest that is switched off, the same thing can be done offline with
`virt-customize` from `libguestfs`, no boot needed:

```sh
virt-customize -a disk.qcow2 \
    --run-command 'grubby --update-kernel=ALL --args="console=tty0 console=ttyS0,115200n8"' \
    --run-command 'systemctl enable serial-getty@ttyS0.service'
```

**NOTE:** Windows guests have no serial `getty`. The console connects and stays
blank. What they do have is EMS/SAC, enabled with `bcdedit`, which is a much
poorer shell — but better than nothing in an emergency.

---

## Installation

Clone it and link it into a folder that is in your `PATH`:

```sh
git clone https://github.com/eduardolucioac/vcon.git
cd vcon
chmod a+x vcon
mkdir -p ~/.local/bin
ln -s "$(pwd)/vcon" ~/.local/bin/vcon
```

**NOTE:** `~/.local/bin` is the usual place for a user's own commands, but not
every distribution puts it in the `PATH` by default. Check with
`echo "$PATH" | tr ':' '\n' | grep local/bin` and, if nothing comes out, add this
to your `~/.bashrc`:

```sh
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
```

---

## Configuration

**Optional.** The defaults are what a local libvirt wants, and `vcon` runs with no
configuration at all. Copy the model only when yours differs:

```sh
cp configs/config_model.bash configs/config.bash
```

| Parameter | Purpose |
|---|---|
| `LIBVIRT_URI` | Which libvirt to talk to. Default `qemu:///system` |
| `LIBVIRT_AUTH_FILE` | Where libvirt should look for credentials, when the connection asks for them |
| `START_TIMEOUT` | Seconds to wait for the console of a machine that was just started. Default `90` |

A remote host is a matter of the URI:

```sh
LIBVIRT_URI='qemu+ssh://user@host/system'
```

**NOTE:** Credentials are libvirt's business, not this script's. `LIBVIRT_AUTH_FILE`
points at the file libvirt already knows how to read — user name and password per
service — instead of a scheme of our own. An SSH connection does not use it at
all: that one authenticates the way SSH always does, with a key and an entry in
`~/.ssh/config`.

**NOTE:** `configs/config.bash` is ignored by git, so the addresses of your
machine never end up in a commit.

---

## Usage

```sh
vcon                       # lists what you can connect to and asks
vcon my-vm-name            # goes straight to that one, starting it if needed
```

```
VMs with a console available:
   1) CentOS_7.X_AMD64_ANEEL                   192.168.122.59     [running]
   2) CentOS_7.X_AMD64_LB                                         [shutoff]
   3) CentOS_7.X_AMD64_LBRAD                   192.168.122.240    [running]
Number to (run and) connect or 0/quit:
```

Picking a `[shutoff]` one starts it and waits for its console. `0` or `quit`
leaves without picking anything.

**To leave the console, press `Ctrl + ]`.** Without it you stay in there.

**TIP:** Once you are connected, the screen often comes up empty. The `getty`
prints its banner once and you arrived after it — press **Enter** to get the
prompt.

---

## Why a serial console and not SSH

SSH is nicer for everyday work. The serial console is what you have left when SSH
is not an option:

| | Needs the network | Needs an agent in the guest | Works in an emergency |
|---|---|---|---|
| SSH | yes | no | no, not if the network is down |
| SPICE clipboard | no | yes, plus a running X session | no on a text-only server |
| **Serial console** | **no** | **no** | **yes** |

It is the equivalent of a serial cable on a physical server: it keeps working with
the interface down, the firewall shut or `sshd` dead. And because it lands in your
own terminal, pasting into it is your desktop's ordinary paste — no clipboard
sharing, no agent, no X inside the guest.

---

## Troubleshooting

### The console is blank

The console device is there, but nothing in the guest is listening on it. See
[On the guest](#on-the-guest). If you already did that, press **Enter** — the
banner may simply have been printed before you connected.

### My VM is not listed

Being switched off is not a reason — those are listed too. What is required is a
console device in the domain XML:

```sh
virsh -c qemu:///system dumpxml MY_VM | grep console
```

Nothing there means the machine has no serial console. Add one with
`virsh edit`:

```xml
<console type='pty'>
  <target type='serial' port='0'/>
</console>
```

### The tab title does not change

- Outside Konsole, it depends on the terminal honouring the OSC sequences;
- On Konsole, it needs `qdbus6`, from the `qt6-tools` package.

Either way the console itself works — the title is the only thing you lose.

### I am stuck inside the console

`Ctrl + ]`. That is the escape character of `virsh console`, and it is printed on
the line right after you connect.

---

## About

vcon 🄯 BSD-3-Clause  
Eduardo Lúcio Amorim Costa  
Brazil-DF  
https://www.linkedin.com/in/eduardo-software-livre/

![Brazil](./images/brazil.png)
