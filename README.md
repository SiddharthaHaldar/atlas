# Atlas

Atlas is a suite of enterprise applications supporting document management, collaboration, and content governance workflows.

## Codespaces: Fix Docker Networking

> [!IMPORTANT]
> If Docker networking is not working in Codespaces, run:
>
> ```sh
> sudo iptables-legacy -I FORWARD -i br+ -o br+ -j ACCEPT
> ```

## Applications

| Application | Description |
|---|---|
| [**nuxeo**](./nuxeo/README.md) | Document management platform (Nuxeo ECM) |
