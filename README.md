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

## 零、出包方式：请走云端（本机已被安全管控限制）

> **本机不能编译了。** 实测：这台电脑禁止任何程序连接「刚被本机监听的端口」（连自己都不行，连接超时），
> 而 Gradle 9 编译时必须开这样一个端口与守护进程通信，所以无论怎么调参数都会在
> `Could not connect to the Gradle daemon` 处失败。这是本机安装的终端安全/防泄漏软件（hosts 里有
> `windows10.microdone.cn`）的策略，不是代码问题，也无法在不改公司策略的前提下绕过。
>
> **请直接看 [`在线打包说明.md`](在线打包说明.md)**，用 GitHub 的免费云编译出 APK（约 10 分钟，产出可直接装的 apk）。

以下「双击一键打包」流程保留给**没有此类管控的电脑**（换台电脑装好工具链即可用）。

## 零之二、在本机双击打包（仅限无管控的电脑）

1. 打开项目文件夹 `...\auto_ledger`
2. **双击 `一键打包.bat`**（会弹出黑色窗口，别关它）
3. 等 5–15 分钟，成功后 APK 会自动出现在**桌面**：`auto_ledger.apk`
4. 把这个 apk 发到手机安装即可（手机上可能需允许「安装未知来源应用」）

脚本会自动完成：配环境 → 拉依赖 → 编译 → 复制到桌面 → 打开所在文件夹。
**失败也不用你分析**：项目里会生成 `build-log.txt`，把它发我即可定位。

> ⚠️ 不要删除或移动 `C:\Users\YD\toolchain`（4 GB 工具链都在里面，脚本靠它编译）。

---

## 二、环境准备（本机已装好，无需再动手）

这套工具链已经装在这台电脑上，可直接编译：

| 组件 | 版本 | 位置 |
|---|---|---|
| Flutter / Dart | 3.50.0 / 3.14.0 | `C:\Users\YD\toolchain\flutter` |
| JDK | 17 (Microsoft) | `C:\Users\YD\toolchain\jdk-17` |
| Android SDK | API 36 + Build-Tools 36.0.0 | `C:\Users\YD\toolchain\android-sdk` |
| NDK | 28.2.13676358 | 同上 `\ndk` |
| Gradle | 9.5.0（本地包，免联网下载） | `C:\Users\YD\toolchain\gradle-9.5.0-all.zip` |
| 依赖镜像 | 阿里云 Maven + pub.flutter-io.cn | `C:\Users\YD\toolchain\gradle_home\init.gradle` |

`flutter doctor` 的 Android 项已是 √（SDK 36.0.0）。

---

## 三、脚手架与依赖（已生成，无需重复）

`android/` 下的 gradle 脚手架、`gradlew`、启动图标都已生成，依赖也已 `pub get` 完成并缓存。
若以后想手动重建（一般不需要）：

```bash
cd auto_ledger
flutter pub get
flutter analyze
```

> 注意：`android/gradle/wrapper/gradle-wrapper.properties` 指向本机的 `C:\Users\YD\toolchain\gradle-9.5.0-all.zip`（免联网下载 Gradle）。
> 若把项目拷到别的电脑，需要把该行改回 `https\://services.gradle.org/distributions/gradle-9.5.0-all.zip`。

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
