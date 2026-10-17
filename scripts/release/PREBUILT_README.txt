Contrail prebuilt Web service
=============================

This bundle contains the compiled Contrail Web application and its integrated
WebDAV gateway. Flutter and Dart are not required.

macOS:
  Double-click "Start Contrail.command".
  Double-click "Stop Contrail.command" to stop it.

Windows:
  Double-click "Start Contrail.cmd".
  Double-click "Stop Contrail.cmd" to stop it.

Contrail opens http://127.0.0.1:27831 by default. Keep the complete extracted
folder together. The default gateway allowlist contains only
dav.jianguoyun.com.

The service runs in the background. Its rotating log is runtime/contrail.log;
the default limit is 10 MB per file with 3 backups. The launchers accept the
same bind-address, port, WebDAV-host, and logging options as the source
deployment scripts. See docs/web-deployment.md in the source repository for
details:
https://github.com/MingweiYan/Contrail/blob/main/docs/web-deployment.md

These community release bundles are currently unsigned. macOS Gatekeeper or
Windows SmartScreen may require explicit first-run approval after download.
