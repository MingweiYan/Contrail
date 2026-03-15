 # 排查 release 端 error log 为空的方案
 
 ## 目标
 - 定位 release 安装包里 Debug 工具栏的 error log 为空的根因
 - 明确与 Android Studio debug 运行有差异的配置点
 - 给出可验证的修复与验证步骤
 
 ## 实施步骤
 1. 梳理日志链路与读取入口
    - 核对日志写入端（AppLogger）对级别过滤与落盘路径的逻辑
    - 核对 Debug 工具栏日志查看器读取的文件路径与过滤行为
    - 明确 release 与 debug 在日志级别、写入时机上的差异点
 
 2. 复核 release 构建与运行环境差异
    - 检查 Android release 构建配置中是否存在混淆/压缩/裁剪影响日志的设置
    - 对比 debug 与 release 的初始化路径，确认文件日志是否在 release 被启用
 
 3. 形成问题根因与修复方案
    - 给出“为何 release 为空、debug 有数据”的具体原因
    - 提出修复选项（例如调整落盘级别、确保工具栏读取正确文件、保留 debug 入口状态等）
 
 4. 输出验证步骤
    - 列出在 release 包内验证日志生成与读取的步骤
    - 若需要改动，补充最小化验证（如触发 error/fatal 并检查 error.log）
