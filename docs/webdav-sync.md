# WebDAV 双向同步

Contrail 的同步采用 local-first 模式。应用运行数据始终先写入设备本地；Web 端由 Hive 使用浏览器 IndexedDB。同步支持两种连接方式：隐私直连模式由浏览器直接访问用户配置的 WebDAV；兼容模式由与 Web 应用一起部署的无状态 Gateway 转发，用于兼容不开放浏览器 CORS 的服务。

## 远端文件

- 当前数据：`contrail_sync.json`
- 冲突快照：`contrail_sync_snapshot_<UTC 毫秒>_<校验和前 12 位>.json`
- 文档包含 schema 版本、设备 ID、单调递增 revision、更新时间、业务 payload、payload SHA-256 和整份文档 SHA-256。
- WebDAV 密码不进入同步 payload 或备份文件。Web 端密码只在当前页面会话的内存中保留，刷新后需要重新输入。
- 兼容模式不会在 Gateway 持久化密码或业务数据，但 Gateway 会在单次请求期间处理凭据与请求/响应正文；部署者仍需被信任。

## 合并规则

同步检查点记录上次成功同步的远端版本、payload hash 与 revision：

1. 远端不存在且没有检查点：使用 `If-None-Match: *` 首次上传。
2. 只有本地变化：先保存远端快照，再使用远端 ETag 和 `If-Match` 条件更新。
3. 只有远端变化：先确认同步期间本地未再次变化，再原子替换本地习惯和设置，成功后提交检查点。
4. 本地与远端同时变化或首次同步内容不同：不自动覆盖，由用户选择本地或远端。被替换的数据先写入远端快照。
5. 已同步的远端文件被删除：默认报告冲突；用户可明确选择用本地数据重新创建。
6. HTTP 408、425、429 与 5xx 等瞬时失败使用指数退避重试。

远端服务器必须返回 ETag 才能安全更新已有同步文件。没有 ETag 时，Contrail 会报告冲突，而不会退化为可能覆盖并发修改的无条件 PUT。

## 浏览器限制

静态 Web 部署（包括 GitHub Pages）直连 WebDAV 时，服务端必须：

- 使用 HTTPS；HTTPS 页面不能访问 HTTP WebDAV（mixed content）；
- 允许部署站点 Origin 的 CORS；
- 放行 `GET`、`PUT`、`MKCOL`，以及 `Authorization`、`Content-Type`、`If-Match`、`If-None-Match` 请求头；
- 暴露 `ETag` 响应头。

坚果云等不允许浏览器跨域直连的服务，可以使用 Contrail 集成服务中的同源 Gateway。用户只需在 WebDAV 配置中选择“兼容模式”，不再额外部署一个 Gateway。纯 GitHub Pages 等静态部署仍没有服务端执行环境，因此只能直连，或在构建时配置一个外部 Gateway URL。

Gateway 是字节转发层，不解析或修改同步文档，并原样保留 ETag 条件请求。因此三方合并、校验和、冲突快照与“无 ETag 时失败关闭”的语义和直连模式一致。
