package com.example.auto_ledger

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * 安卓通知监听服务：系统会把其他 App 发出的通知推送到这里。
 *
 * 我们只关心微信、支付宝的支付通知，提取 title/text 后通过
 * EventSink 转发给 Flutter 层去做金额解析。用户必须手动授予
 * 「通知使用权」这个服务才会被系统回调。
 */
class PaymentNotificationListener : NotificationListenerService() {

    companion object {
        // Flutter 层注册的接收器；App 在前台时才有值。
        var eventSink: io.flutter.plugin.common.EventChannel.EventSink? = null

        private const val TAG = "PayNotiListener"
        private const val PKG_WECHAT = "com.tencent.mm"
        private const val PKG_ALIPAY = "com.eg.android.AlipayGphone"
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val notification = sbn ?: return
        val pkg = notification.packageName ?: return

        // 只处理微信和支付宝，避免把其他通知也当支付。
        if (pkg != PKG_WECHAT && pkg != PKG_ALIPAY) return

        val extras = notification.notification?.extras ?: return
        val title = extras.getCharSequence(android.app.Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(android.app.Notification.EXTRA_TEXT)?.toString() ?: ""

        // 过滤明显不是支付的通知（如普通聊天消息）。
        val combined = "$title $text"
        if (!looksLikePayment(combined)) return

        Log.d(TAG, "支付通知: pkg=$pkg title=$title text=$text")

        val data = mapOf(
            "package" to pkg,
            "title" to title,
            "text" to text,
            "time" to System.currentTimeMillis()
        )
        eventSink?.success(data)
    }

    /** 简单判断：文案里带「支付/付款/收款/¥/￥/元/转账」等关键词才认为是支付。 */
    private fun looksLikePayment(text: String): Boolean {
        val keywords = listOf("支付", "付款", "收款", "已付", "转账", "¥", "￥", "元", "消费")
        return keywords.any { text.contains(it) }
    }
}
