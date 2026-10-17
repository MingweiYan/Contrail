Contrail prebuilt Web service
=============================

This bundle contains the compiled Contrail Web application and its integrated
WebDAV gateway. Flutter and Dart are not required.

macOS:
  Double-click "Start Contrail.command".

Windows:
  Double-click "Start Contrail.cmd".

Contrail opens http://127.0.0.1:27831 by default. Keep the complete extracted
folder together. The default gateway allowlist contains only
dav.jianguoyun.com.

The launchers accept the same bind-address, port, and WebDAV-host options as
the source deployment scripts. See docs/web-deployment.md in the source
repository for details:
https://github.com/MingweiYan/Contrail/blob/main/docs/web-deployment.md

These community release bundles are currently unsigned. macOS Gatekeeper or
Windows SmartScreen may require explicit first-run approval after download.
