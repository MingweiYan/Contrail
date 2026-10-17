# Web deployment

Contrail Web remains local-first. Habit data is stored at runtime in the
browser's IndexedDB and is never stored by the Contrail web service. There are
two deployment modes:

- **Static site**: GitHub Pages or any static server. WebDAV is browser-direct
  and therefore depends on the provider's CORS policy.
- **Integrated service**: one Contrail process serves the Flutter application
  and `/api/webdav`. Users can switch between direct access and the stateless
  compatibility gateway without deploying a second service.

The gateway does not persist credentials or WebDAV payloads. In compatibility
mode it necessarily handles them in memory while forwarding each request, so
the service operator must still be trusted with data in transit.

## Static build

For a domain root:

```sh
flutter build web --release --no-wasm-dry-run
```

For a repository subpath such as GitHub Pages:

```sh
flutter build web --release --no-wasm-dry-run --base-href /Contrail/
```

Publish the contents of `build/web`. Contrail uses hash-based routes, so direct
links such as `/#/statistics` survive reloads without a server-side rewrite.
Static builds do not show compatibility mode unless a gateway URL is supplied
explicitly at build time.

### GitHub Pages demo

The repository publishes a static demonstration build at
<https://mingweiyan.github.io/Contrail/>. The demo is the real Flutter Web
application rather than a screenshot: visitors can create habits, record
sessions, generate their own data, and navigate every Web-compatible page.

Each visitor's demo data stays in that browser's IndexedDB and preferences.
There is no shared demo account or Contrail data backend, so one visitor cannot
see another visitor's data. Clearing site data, using a private window, or
changing the deployment origin removes or isolates that local dataset.

GitHub Pages cannot run the bundled compatibility gateway. Direct WebDAV works
only when the provider permits CORS from the Pages origin; providers such as
Jianguoyun require the integrated self-hosted service for WebDAV access. The
Pages deployment is therefore intended primarily as a safe product demo.

## Integrated service

Build the application with the same-origin gateway endpoint and start the
bundled server:

### One-click local deployment

Contrail supports both prebuilt release bundles for regular users and source
builds for developers. Both modes start the same integrated Web application
and WebDAV gateway, verify `/healthz`, and open the application in the default
browser.

Both modes default to `127.0.0.1:27831` and allow only
`dav.jianguoyun.com` as the upstream WebDAV host. Port `27831` is a fixed,
uncommon high port selected to reduce collisions with development services
that often use `8080`. It intentionally remains stable between launches
because IndexedDB and credential storage are origin-scoped.

If an earlier source deployment already stored browser data on port `8080`,
continue launching that copy with `--port 8080` / `-Port 8080` until the data
has been exported or intentionally migrated. Browsers cannot automatically
move IndexedDB or local credentials between two origins with different ports.

#### Prebuilt release bundles (recommended)

Download and extract the bundle for the current machine from
[GitHub Releases](https://github.com/MingweiYan/Contrail/releases):

- `Contrail-macOS-arm64.zip` for Apple Silicon Macs.
- `Contrail-macOS-x64.zip` for Intel Macs.
- `Contrail-Windows-x64.zip` for 64-bit Windows.

On macOS, double-click `Start Contrail.command`; use `Stop Contrail.command`
when finished. On Windows, use `Start Contrail.cmd` and `Stop Contrail.cmd`.
The service runs in the background, so closing the terminal window does not
stop it. Flutter and Dart are not required. Keep the extracted directory
together because the launchers, runtime state, Web assets, and native server
are a single bundle.

Release bundles are built and smoke-tested on their native GitHub runners.
Version tags publish the three archives plus `SHA256SUMS.txt`; the existing
Android release workflow also dispatches this Web bundle workflow for the same
release tag.

The bundles are currently unsigned. macOS Gatekeeper or Windows SmartScreen
may require explicit first-run approval. This does not affect source builds,
and no WebDAV credential or user data is embedded in any bundle.

#### Build from source

Building and running are separate operations. The deployment launcher reuses
an existing `build/web` and native server. If either artifact is missing, it
automatically invokes the build script; use `--rebuild` / `-Rebuild` after a
source update when an older build already exists. Flutter must be installed and
available on `PATH` only when a build is needed. CI pins Flutter `3.41.9`, which
is the recommended local version.

To build without starting the service, use:

```sh
./scripts/build_web_macos.command
```

```powershell
scripts\build_web_windows.cmd
```

On macOS, double-click `scripts/deploy_web_macos.command` in Finder or run:

```sh
./scripts/deploy_web_macos.command
```

On Windows, double-click `scripts\deploy_web_windows.cmd` in Explorer. The
wrapper uses Windows PowerShell with a process-local execution-policy bypass;
it does not change the machine's PowerShell policy. The underlying script can
also be run directly:

```powershell
.\scripts\deploy_web.ps1
```

Both launchers return after `/healthz` succeeds while Contrail continues in the
background. Stop the exact recorded Contrail process with the companion script:

```sh
./scripts/stop_web_macos.command
```

```powershell
scripts\stop_web_windows.cmd
```

The stop script validates that the recorded PID still belongs to the expected
Contrail executable before terminating it, so a stale PID file cannot kill an
unrelated process.

Command-line options can change the bind address, port, or allowlist:

```sh
./scripts/deploy_web.sh \
  --bind 127.0.0.1 \
  --port 27832 \
  --allowed-hosts dav.jianguoyun.com
```

```powershell
.\scripts\deploy_web.ps1 `
  -BindAddress 127.0.0.1 `
  -Port 27832 `
  -AllowedHosts dav.jianguoyun.com
```

Use `--no-open` / `-NoOpen` to suppress browser launch and `--skip-build` /
`-SkipBuild` to require pre-existing artifacts without invoking Flutter. The
`--smoke-test` / `-SmokeTest` option is intended for automation: it stops the
temporary background process after the health check succeeds. GitHub Actions
exercises separate build, background start, stop, and prebuilt bundle paths on
native macOS and Windows runners for relevant pull requests.

#### Local service logs

Background deployments write service logs to `runtime/contrail.log` by
default. Logs are bounded rather than append-only forever: each file is limited
to 10 MB and 3 rotated backups are retained (`contrail.log.1` through `.3`), so
the normal maximum is about 40 MB. The small `contrail-launch*.log` files only
capture early process startup failures and are truncated on every launch.

The default `info` level records lifecycle and failures. Per-request method,
path, status, and timing are recorded only at `debug`; request headers, WebDAV
credentials, bodies, and query strings are never included. Available controls:

| macOS/Linux | Windows | Environment | Purpose |
| --- | --- | --- | --- |
| `--log-level debug` | `-LogLevel debug` | `CONTRAIL_LOG_LEVEL` | `debug`, `info`, `warn`, `error`, or `off` |
| `--log-file path` | `-LogFile path` | `CONTRAIL_LOG_FILE` | Change the rotating log destination |
| `--log-max-mb 20` | `-LogMaxMegabytes 20` | `CONTRAIL_LOG_MAX_BYTES` | Change the per-file size limit |
| `--log-backups 5` | `-LogBackups 5` | `CONTRAIL_LOG_BACKUP_COUNT` | Change retained rotated files (0-100) |
| `--open-log` | `-OpenLog` | — | Open the current log after startup |

For example:

```sh
./scripts/deploy_web.sh --log-level debug --open-log
```

```powershell
.\scripts\deploy_web.ps1 -LogLevel debug -OpenLog
```

The active file is rotated while the service is running, not only at restart.
A single unusually large record can briefly exceed the per-file limit, but
normal request and lifecycle entries remain within the configured bound.

The service has no built-in edge authentication. Keep the default loopback
binding for single-machine use. Before binding to `0.0.0.0` or exposing the
service outside the machine, put HTTPS, authentication, and rate limiting in
front of it.

### Manual deployment

The equivalent manual commands are:

```sh
flutter pub get --enforce-lockfile
flutter build web --release --no-wasm-dry-run \
  --dart-define=WEBDAV_GATEWAY_URL=/api/webdav
WEBDAV_GATEWAY_ALLOWED_HOSTS=dav.jianguoyun.com \
  dart run server/bin/contrail_server.dart
```

The process listens on `0.0.0.0:27831`, serves `build/web`, exposes
`GET /healthz`, and handles WebDAV forwarding at `/api/webdav`. Put TLS in front
of it for non-local use. A production image can compile the entry point first:

```sh
dart compile exe server/bin/contrail_server.dart -o build/contrail-server
WEBDAV_GATEWAY_ALLOWED_HOSTS=dav.jianguoyun.com \
  ./build/contrail-server
```

## Gateway security policy

The gateway starts only after an explicit target policy is configured. Prefer
an allowlist, especially for an Internet-facing deployment:

| Variable | Default | Purpose |
| --- | --- | --- |
| `WEBDAV_GATEWAY_ALLOWED_HOSTS` | empty | Comma-separated exact hosts or `*.example.com` patterns |
| `WEBDAV_GATEWAY_ALLOW_ANY_PUBLIC_HOST` | `false` | Allow arbitrary public targets; intended for controlled self-hosting |
| `WEBDAV_GATEWAY_ALLOWED_ORIGINS` | same origin | Additional browser origins allowed to call the gateway |
| `WEBDAV_GATEWAY_ALLOWED_PORTS` | `443` | Comma-separated upstream ports |
| `WEBDAV_GATEWAY_ALLOW_HTTP` | `false` | Permit non-TLS upstream WebDAV |
| `WEBDAV_GATEWAY_ALLOW_PRIVATE_TARGETS` | `false` | Permit loopback, LAN, or reserved target addresses |
| `WEBDAV_GATEWAY_MAX_REQUEST_BYTES` | `10485760` | Maximum request body size |
| `WEBDAV_GATEWAY_MAX_RESPONSE_BYTES` | `10485760` | Maximum response body size |
| `WEBDAV_GATEWAY_TIMEOUT_SECONDS` | `20` | Upstream connect and request timeout |
| `CONTRAIL_BIND_ADDRESS` | `0.0.0.0` | Service bind address |
| `CONTRAIL_WEB_ROOT` | `build/web` | Flutter build directory |
| `PORT` | `27831` | Service port |
| `CONTRAIL_LOG_LEVEL` | `info` | `debug`, `info`, `warn`, `error`, or `off` |
| `CONTRAIL_LOG_FILE` | stdout/stderr | Optional rotating server log file |
| `CONTRAIL_LOG_MAX_BYTES` | `10485760` | Per-file log rotation threshold |
| `CONTRAIL_LOG_BACKUP_COUNT` | `3` | Rotated log files to retain |

For a private NAS or a local OpenList instance, the operator may also need to
enable private targets, HTTP, and its non-standard port. Those options should
only be used on a trusted, access-controlled deployment. The gateway validates
DNS results, pins the outbound connection to the validated address, rejects
redirects, accepts only the WebDAV methods Contrail uses, limits payload sizes,
and forwards only the required headers. `ETag`, `If-Match`, and
`If-None-Match` are preserved so optimistic concurrency is unchanged.

If the gateway is exposed publicly, keep the host allowlist narrow and add
edge authentication and rate limiting. Do not log the two
`X-Contrail-WebDAV-*` request headers because one carries the upstream Basic
credential.

See [Web data lifecycle](web-data-lifecycle.md) and
[WebDAV synchronization](webdav-sync.md) for the storage and conflict model.
