# 随手账 · V1 打包与安装指南

一款「支付后自动提醒、点通知选分类」的安卓记账 App。账单只存本机，不联网、不上传。

---

## 一、这个 App 现在能做什么（V1）

1. 你授权「通知读取权限」后，App 会在后台监听微信、支付宝的支付成功通知。
2. 检测到支付 → 自动解析金额 → 通知栏弹窗「检测到一笔支出 ¥XX，花在哪了？」。
3. 你点通知 → 弹出小窗，金额已预填（可改），选一级/二级分类 → 保存。
4. 首页看本月总额和分类占比，账单页按天分组可编辑/删除，统计页看明细。
5. 右下角「+」可随时手动补记。

> 说明：金额来源有两条路——支付通知里自动解析（预填），最终由你确认。这是「自动+手动确认」的组合，保证金额不会记错。

---

## 二、环境准备（一次性）

> 本机当前未安装 Flutter，需要先装。以下以 Windows 为例。

1. **装 Flutter SDK**
   - 去官网 https://docs.flutter.dev/get-started/install/windows 下载最新稳定版。
   - 解压到例如 `C:\flutter`，并把 `C:\flutter\bin` 加到系统环境变量 `Path`。
   - 验证：打开新的命令行窗口，运行 `flutter --version`，能看到版本号即成功。

2. **装 Android Studio**
   - 下载安装 https://developer.android.com/studio
   - 安装时勾选 **Android SDK**、**Android SDK Platform**（选 Android 14 / API 34）、**Android Studio 自带的 JDK**。
   - 打开一次 Android Studio，按提示完成 SDK 初始化。

3. **装 Android SDK Command-line Tools**
   - Android Studio → Settings → SDK Manager → SDK Tools → 勾选 **Android SDK Command-line Tools (latest)** → Apply。
   - 验证：`flutter doctor`，确保 Android 相关项都打勾（黄色/红色的项按提示处理）。

---

## 三、把项目补齐成完整工程

本目录只提供了 V1 的核心源码（`lib/`、安卓原生代码、`pubspec.yaml`、Manifest）。
gradle 等脚手架文件请用 Flutter 命令自动生成，避免版本不匹配：

```bash
# 1. 进入本项目目录
cd auto_ledger

# 2. 生成平台脚手架（已存在的文件不会被覆盖）
flutter create . --org com.example --platforms android

# 3. 拉取依赖
flutter pub get

# 4. 检查连接与配置
flutter doctor
flutter analyze
```

> `flutter create .` 会补齐 `android/app/build.gradle`、`settings.gradle`、
> `gradlew`、启动图标等文件，并把 `AndroidManifest.xml` 保留为你现有的版本。

---

## 四、调试运行（先真机验证）

用数据线连接安卓手机，开启「开发者选项」→「USB 调试」：

```bash
flutter devices          # 确认能看到你的手机
flutter run              # 安装并启动到手机
```

首次打开 App 会显示引导页 → 点「去授权」→ 在系统设置里打开「随手账-支付提醒」的通知使用权 → 返回 App → 点「我已开启，进入 App」。
然后用微信/支付宝随便支付一笔（或让朋友发个带金额的支付通知）测试弹窗和选分类。

---

## 五、打包正式 APK（可发给别人安装）

### 1. 生成签名密钥（只需一次）

```bash
keytool -genkey -v -keystore C:\flutter\auto-ledger.jks -keyalg RSA -keysize 2048 -validity 10000 -alias autokey
```

按提示设置密码和基本信息。**务必记住密码和 alias**，后面要用。

### 2. 配置签名

在 `android/` 根目录新建 `key.properties`：

```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=autokey
storeFile=C:\\flutter\\auto-ledger.jks
```

注意：Windows 路径里的反斜杠要写成两个（`\\`）。

然后把下面这段加入到 `android/app/build.gradle` 的 `android { ... }` 代码块里（如果文件里已有同名配置就替换）：

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

同时在 `android/app/build.gradle` 顶部确认有这行 import（通常已有）：

```groovy
import java.util.Properties
import java.io.FileInputStream
```

### 3. 执行打包

```bash
flutter clean
flutter pub get
flutter build apk --release
```

产物位置：`build/app/outputs/flutter-apk/app-release.apk`
把这个文件发到手机上安装即可（安卓允许安装未知来源 APK，安装时按提示授权）。

如果想打更小的分包（按 CPU 架构）：`flutter build apk --release --split-per-abi`，产物在
`build/app/outputs/flutter-apk/` 下会有多个 apk，选 `arm64-v8a` 那个一般就够（较新的手机）。

---

## 六、常见报错排查

| 报错 | 原因 | 解决办法 |
|---|---|---|
| `cmdline-tools component is missing` | 没装命令行工具 | Android Studio → SDK Manager → SDK Tools 勾选 Android SDK Command-line Tools |
| `Gradle build failed` / 卡在下载 | Gradle 网络问题 | 关掉再看；或用国内镜像；`flutter clean` 后重试 |
| `CocoaPods not installed` | iOS 才需要 | 本项目 V1 只打安卓，忽略即可 |
| 签名报 `keystore password was incorrect` | 密码/路径写错 | 核对 `key.properties`，路径用双反斜杠 |
| App 里点了「去授权」但没反应 | 跳转设置失败 | 手动进手机「设置 → 通知 → 通知使用权」打开「随手账」 |
| 支付后没有弹通知 | 权限没开 / 通知文案不含关键词 | 确认已授权；微信/支付宝部分通知文案若不含"支付/元"等词会被过滤，属正常 |
| `flutter analyze` 报过期 API | Flutter 版本差异 | 按提示替换 `withOpacity` 为 `withValues(alpha:)` 等（新版弃用提示，不影响运行） |

---

## 七、边界与提醒

- **后台保活**：V1 的支付感知依赖 App 的监听服务在后台运行。请在系统设置里把「随手账」加入**自启动 / 后台运行白名单**，并允许后台通知，否则 App 被彻底杀掉后可能收不到支付提醒。这是安卓系统的限制，非本 App 缺陷。部分国产 ROM（小米/华为/OPPO 等）需要手动锁定后台。
- **通知内容差异**：微信/支付宝的支付通知文案可能随版本变化。若某次支付没弹提醒，多半是文案里不含"支付/元"等关键词，被过滤了；可用右下角「+」手动补记，V2 会优化识别规则。
- **iOS（苹果）**：本专家 V1 只交付安卓 APK。苹果系统不允许读取其他 App 的通知，做不到"支付后自动抓金额"，若以后要做 iOS 需改成手动记账或快捷指令方案。
- **应用商店上架**：本指南只做本地打包，不承诺上架审核、资质办理等。
- **隐私**：账单数据全部在本机 SQLite（`auto_ledger.db`），卸载 App 会一并删除；重要数据请用账单页自行记录留存。
- **分类自定义、云同步、AI 归类、图表增强**：规划在 V2/V3，本版不含。

---

## 八、项目结构速览

```
auto_ledger/
├── pubspec.yaml                      # 依赖配置
├── lib/
│   ├── main.dart                     # 入口：初始化通知、监听支付
│   ├── app.dart                      # 根组件、主题
│   ├── models/transaction.dart       # 账单模型
│   ├── data/
│   │   ├── categories.dart           # 预置支出分类
│   │   └── db_helper.dart            # SQLite 本地存储
│   ├── services/
│   │   ├── amount_parser.dart        # 从通知文本解析金额
│   │   ├── notification_service.dart # 通知栏弹窗
│   │   └── payment_monitor.dart      # 与原生通信、待归类中转
│   ├── providers/ledger_provider.dart# 状态管理
│   ├── pages/                        # 引导/首页/账单/统计/设置
│   ├── widgets/category_picker_sheet.dart # 选用途小窗
│   └── utils/format.dart             # 格式化
└── android/app/src/main/
    ├── AndroidManifest.xml           # 权限+服务注册
    └── kotlin/.../                   # 通知监听服务、通道实现
```
