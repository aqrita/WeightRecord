# 体重记录 WeightRecord

一个**个人自用**的体重记录 App：只在本机运行，数据全部保存在本机，不联网、不上云、无账号体系。基于 Flutter 开发，支持 Android。

## ✨ 功能特性

- ⚖️ **记录体重**：输入公斤（kg，保留 1 位小数），自动记录当时的日期与时间
- 📷 **可选照片**：记录时可选拍照或从相册选择一张照片，并**可选是否压缩**（默认压缩）
- 📋 **历史记录**：按时间列表查看全部记录，支持删除（照片一并删除）
- 📈 **折线图**：首页展示体重-时间折线图（X 轴时间、Y 轴体重 kg），随记录增删实时刷新
- 🖼️ **照片对比**：带照片的记录按时间顺序排列，可左右滑动播放对比
- 🗂️ **底部导航**：首页 / 我的 双页切换
- 💾 **本地持久化**：SQLite 数据库保存记录，重启、关闭后数据不丢失

## 🧱 技术栈

| 类别 | 技术 |
| --- | --- |
| 框架 | Flutter 3.47.2 / Dart 3.13.2 |
| 平台 | Android（Android Studio 构建） |
| 数据库 | sqflite（SQLite，本地持久化） |
| 折线图 | fl_chart |
| 图片 | image_picker（拍照/相册）、image（纯 Dart 压缩） |
| 文件路径 | path_provider、path |

## 📱 页面结构

- **首页**：折线图 + “查看变化”入口
- **我的**：记录、查看记录 两个入口
- **记录页**：体重输入 + 时间自动记录 + 照片选择（拍照/相册）+ 压缩开关
- **历史页**：全部记录列表 + 删除
- **照片对比页**：照片按时间滑动播放

## 📁 目录结构

```
lib/
├── main.dart                  # 入口 + 底部导航（首页 / 我的）
├── models/
│   └── weight_record.dart     # 数据模型
├── db/
│   ├── database_helper.dart   # SQLite 初始化
│   └── weight_record_repository.dart  # 数据访问
├── charts/
│   └── weight_chart.dart      # 体重折线图
├── pages/
│   ├── home_page.dart         # 首页
│   ├── profile_page.dart      # 我的
│   ├── record_page.dart       # 记录
│   ├── history_page.dart      # 查看记录
│   └── photo_compare_page.dart# 照片对比
├── services/
│   ├── record_service.dart    # 记录业务
│   ├── photo_service.dart     # 照片保存/压缩/删除
│   ├── photo_picker.dart      # 拍照/相册选择
│   └── photo_store.dart       # 照片文件存储
└── utils/
    └── format.dart            # 格式化工具
```

## 🚀 快速开始

环境要求：Flutter 3.47+、Android SDK、Android Studio（自带 JDK）。

```bash
# 1. 安装依赖
flutter pub get

# 2. 运行（连接开启 USB 调试的真机，或启动模拟器）
flutter run

# 3. 运行全部测试
flutter test

# 4. 打包 Release APK（自用安装）
flutter build apk
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

## 🧪 测试

`test/` 目录共 12 个测试文件，覆盖数据层、服务层、模型、图表与各页面组件，运行 `flutter test` 一键执行。

## 🔒 数据与隐私

- 所有记录与照片仅保存在**本机 App 私有目录**（SQLite + 应用文档目录 `photos/`），无任何网络请求。
- 卸载 App 会删除全部本地数据；当前版本不含导出/备份功能。
- 删除记录时对应照片文件会一并删除。

## 📄 相关文档

- [PRD.md](PRD.md) —— 产品需求文档（功能范围、验收口径）
- [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) —— 开发计划与阶段说明

---

> 本项目为个人自用项目，仅支持 Android 平台。数据安全请自行做好本机备份。
