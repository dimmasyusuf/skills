# Dev Tunnels Workflow Guide

This guide details how the AI should handle user requests to "activate tunnel" or "update env to tunnel" during local development.

## 1. Checking Active Tunnels
If the user asks to use a tunnel, check if one is already active.
If the user is using VS Code, they might have a tunnel active via Port Forwarding, which they will typically provide the URL for (e.g., `https://0qlmfnc2-3000.asse.devtunnels.ms/`).

Alternatively, use the `devtunnel` CLI if installed:
```bash
devtunnel list
```

## 2. Activating Tunnels
If no tunnel is active and the user asks you to activate one, you should use the `devtunnel` CLI.

1. **Verify Installation**: Ensure `devtunnel` is installed (`command -v devtunnel`). If not, install it via `brew install --cask devtunnel` (or the `curl` installer).
2. **Login**: Ask the user to run `devtunnel user login` if they aren't logged in.
3. **Host Public Tunnels**: The user has explicitly requested that tunnels be **PUBLIC**. Run the following command to host both the frontend (3000) and backend (8080) ports:
   ```bash
   devtunnel host -p 3000 -p 8080 --allow-anonymous
   ```
   *(Note: This runs persistently, so you may need to run it in a background task or advise the user to run it in a separate terminal tab).*

## 3. Patching Environment Variables
Once the tunnel is active and you have a valid Tunnel URL, you must patch the local environment files. The `lib/project.sh` script provides a helper for this:

```bash
source scripts/lib/project.sh
work_env_patch_tunnel ".env.local" ".env" "https://0qlmfnc2-3000.asse.devtunnels.ms/"
```
- The function will automatically extract the base ID (`0qlmfnc2`) and region (`asse`).
- It rewrites both the `3000` (frontend) and `8080` (backend) URLs into `.env.local` and `.env` respectively.
