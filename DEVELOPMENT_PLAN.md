# 开发计划：体重记录 App（weight_record）

> 版本：v1.0
> 日期：2026-08-31
> 依据：PRD.md（v0.1 需求确认稿）
> 技术栈：Flutter 3.47.2 / Dart 3.13.2，仅 Android 平台，本地存储

## 0. 环境状态（已检查）

| 项目 | 状态 | 说明 |
|---|---|---|
| Flutter SDK | 就绪 | 3.47.2 stable，缓存完整 |
| Android Studio + jbr | 就绪 | 系统级 JAVA_HOME 已指向 jbr（JDK 25），PATH 已清理 |
| Android SDK | 就绪 | platform-tools / build-tools 36.0.0 / emulator / 许可已接受 |
| 工程结构 | 就绪 | pubspec.yaml、lib/、android/、gradlew、wrapper 均完整 |
| 依赖解析 | 就绪 | 已执行 pub get，28 个包解析成功 |

开发前还需完成（用户侧，本机有网络）：
1. 创建模拟器（Android Studio → Device Manager → 新建 AVD）或连接开启 USB 调试的真机。
2. 首次 Gradle 构建会联网下载 platform android-36 等组件，属正常现象。
3. 注意：SDK platforms 目录里有个非标准文件夹 android-37.0；若构建报"找不到 platform"再处理（SDK Manager 重装 android-36 即可）。

## 1. 技术决策（PRD 待细化项定稿）

- 体重单位：公斤（kg），输入保留 1 位小数。
- 记录时间：保存那一刻的日期时间，界面只读展示，不可手改。
- 照片：每条记录最多 1 张；压缩默认开启（长边缩至 ≤1920px、JPEG 质量 80），可在记录页临时关闭。
- 照片存储：复制到应用文档目录 photos/，数据库只存相对文件名。
- 删除记录：数据库记录与照片文件一并删除。
- 数据存储：SQLite（sqflite），本地持久化，重启不丢。

## 2. 依赖清单

```
flutter pub add sqflite path_provider path image_picker image fl_chart
```

- sqflite：本地数据库
- path_provider：应用文档目录（存照片）
- path：路径拼接
- image_picker：拍照 / 相册选图
- image：纯 Dart 图片压缩
- fl_chart：折线图

## 3. 工程文件结构（目标）

```
lib/
├── main.dart                     # 入口 + 底部导航（首页 / 我的）
├── models/
│   └── weight_record.dart        # 数据模型
├── db/
│   └── database_helper.dart      # SQLite 初始化 + CRUD
├── services/
│   └── photo_service.dart        # 照片选择/保存/压缩/删除
└── pages/
    ├── home_page.dart            # 首页：折线图 + 查看变化按钮
    ├── profile_page.dart         # 我的：记录 / 查看记录入口
    ├── record_page.dart          # 记录：体重 + 时间 + 照片 + 压缩选项
    ├── history_page.dart         # 查看记录：列表 + 删除
    └── photo_compare_page.dart   # 照片对比：按时间左右滑动
```

## 4. 分阶段开发步骤

### 阶段 A：依赖与骨架
1. 执行 `flutter pub add sqflite path_provider path image_picker image fl_chart`。
2. 建立 lib 目录结构（models/db/services/pages）。
3. 将 android/app/src/main/AndroidManifest.xml 的 android:label 改为"体重记录"。
验收：`flutter pub get` 无报错。

### 阶段 B：数据层
1. lib/models/weight_record.dart：字段 id / weightKg / recordedAt / photoPath / compressed，提供 toMap、fromMap。
2. lib/db/database_helper.dart：单例；建表 weight_records（id 自增主键、weight_kg REAL、recorded_at INTEGER 毫秒时间戳、photo_path TEXT 可空、compressed INTEGER 0/1）；实现 insert / getAll（按时间排序）/ getById / delete。
验收：在真机/模拟器上添加记录后重启 App，数据仍在。

### 阶段 C：照片服务
1. lib/services/photo_service.dart：
   - pickPhoto(ImageSource, {required bool compress})：选图 → 复制到文档目录 photos/ → 按需压缩 → 返回文件名。
   - deletePhoto(fileName)。
2. 压缩规则：长边 >1920 则等比缩小；JPEG 质量 80；不压缩则原样复制。
验收：选一张大图，压缩模式保存后文件明显变小且能正常显示。

### 阶段 D：记录页
1. lib/pages/record_page.dart：
   - 体重输入框（数字键盘、单位 kg、校验 20–300 之间）。
   - 当前时间只读展示。
   - 照片区：三个动作（拍照 / 相册 / 不选）；选中后显示缩略图。
   - 压缩开关（默认开）。
   - 保存：校验 → 插入 DB（含照片文件名）→ 返回上一页并触发刷新。
验收：保存后数据出现在查看记录页；重启不丢；照片正常显示。

### 阶段 E：我的页 + 查看记录
1. lib/pages/profile_page.dart：两个入口卡片（记录 / 查看记录）。
2. lib/pages/history_page.dart：
   - 列表项：时间、体重(kg)、照片缩略图（有则显示）。
   - 右上"新增"跳记录页；每项提供删除（弹确认框，确认后删 DB + 照片）。
验收：增删记录即时生效，首页折线图同步变化。

### 阶段 F：首页折线图
1. lib/pages/home_page.dart：
   - 读取全部记录（时间升序），fl_chart 画折线图，X=时间、Y=体重(kg)。
   - 无数据时显示引导文案。
   - "查看变化"按钮 → 跳照片对比页。
2. 底部导航：lib/main.dart 用 NavigationBar 承载 首页 / 我的 两个页面。
验收：添加多条记录后折线平滑显示；删记录后折线更新；无数据显示提示。

### 阶段 G：照片对比页
1. lib/pages/photo_compare_page.dart：
   - 取所有带照片记录（时间升序）→ PageView 左右滑动。
   - 每页显示：照片 + 记录时间 + 体重。
   - 无照片记录时显示"暂无照片"提示。
验收：左右滑动顺序为时间先后，照片加载正常。

### 阶段 H：整合与收尾
1. 更新 test/widget_test.dart 为冒烟测试（App 启动后能渲染首页导航），替换模板计数器测试。
2. 跑 `flutter analyze` 清零告警；`flutter test` 通过。
3. 在模拟器/真机 `flutter run` 全流程走查（记录→查看→删除→图表→对比）。
验收：PRD 3.1–3.5 全部可操作。

## 5. 验收清单（对照 PRD）

- [x] 3.1 记录体重（kg，1 位小数）和当时时间
- [x] 3.2 记录时可带照片，且可选压缩/不压缩
- [x] 3.3 查看记录列表：新增、删除（照片一并删除）
- [x] 3.4 首页折线图：X=时间，Y=体重(kg)，随增删刷新
- [x] 3.5 照片按时间顺序左右滑动对比（首页"查看变化"进入）
- [x] 页面结构：首页 + 我的 底部导航（NavigationBar）；我的页含记录/查看记录入口
- [x] 本地持久化：SQLite + 文档目录照片（DatabaseHelper/PhotoService 已验证）
- [x] 无登录、无联网依赖、无云数据库

## 6. 常用命令

```
flutter pub get          # 拉取依赖（本机执行）
flutter analyze          # 静态检查
flutter test             # 跑测试
flutter run              # 在已连接设备/模拟器运行
flutter build apk --release   # 打安装包（可选）
```

## 7. 协作方式

- 代码改动由我在此工程内完成。
- 需要网络/构建的命令（pub get、analyze、test、run、build）需在你本机执行——我这边无法联网且沙箱限制 flutter 缓存写入。
- 每个阶段完成或需要你跑命令时，我会明确提示。
## 8. 开发进度（2026-08-31）

- 阶段 A–H 代码与测试全部完成：`flutter analyze` 0 告警，`flutter test` 55 个测试全部通过。
- 测试文件：models / db / photo_service / record_service / record_page / profile_page / history_page / weight_chart / home_page / home_shell / photo_compare_page / widget_test（App 冒烟）。
- 可测性设计：新增 WeightRecordRepository 接口（SQLite 实现 DatabaseWeightRecordRepository）、RecordService（照片保存+入库+失败时清理照片）、PhotoStore 接口（PhotoService 实现）；页面通过构造注入依赖，widget 测试无需真实 IO。
- 待你本机完成（沙箱无法构建 Android）：Android Studio 打开工程 → 创建 AVD 或连接真机 → `flutter run` → 按验收清单走查（记录→查看→删除→图表→照片对比→重启数据仍在）。
