import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrscan_app/models/app_notification.dart';
import 'package:qrscan_app/services/notification_inbox_controller.dart';
import 'package:qrscan_app/utils/theme_colors.dart';
import 'package:qrscan_app/utils/vn_datetime.dart';
import 'package:qrscan_app/views/Notifications/phieu_approve_page.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationInboxController>().refresh();
    });
  }

  Future<void> _openItem(AppNotification item) async {
    final inbox = context.read<NotificationInboxController>();
    if (!item.isRead) {
      try {
        await inbox.markRead(item.id);
      } catch (_) {}
    }

    if (!item.isPhieuApprove || item.phieuToken == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(item.message)),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhieuApprovePage(phieuToken: item.phieuToken!),
      ),
    );
    if (mounted) await inbox.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationInboxController>(
      builder: (context, inbox, _) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => inbox.refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Thông báo',
                            style: ThemeColors.getTitleStyle(context),
                          ),
                        ),
                        if (inbox.unreadCount > 0)
                          TextButton(
                            onPressed: inbox.loading
                                ? null
                                : () async {
                                    try {
                                      await inbox.markAllRead();
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e
                                                .toString()
                                                .replaceFirst('Exception: ', ''),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: const Text('Đọc tất cả'),
                          ),
                        IconButton(
                          onPressed:
                              inbox.loading ? null : () => inbox.refresh(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                ),
                if (inbox.loading && inbox.items.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (inbox.error != null && inbox.items.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline,
                                size: 48, color: Colors.orange[700]),
                            const SizedBox(height: 12),
                            Text(
                              inbox.error!,
                              textAlign: TextAlign.center,
                              style: ThemeColors.getCardSubtitleStyle(context),
                            ),
                            if (inbox.statusHint != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                inbox.statusHint!,
                                textAlign: TextAlign.center,
                                style: ThemeColors.getCardSubtitleStyle(context)
                                    .copyWith(fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => inbox.refresh(),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (inbox.items.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Không có thông báo',
                              style: ThemeColors.getCardSubtitleStyle(context),
                            ),
                            if (inbox.statusHint != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                inbox.statusHint!,
                                textAlign: TextAlign.center,
                                style: ThemeColors.getCardSubtitleStyle(context)
                                    .copyWith(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = inbox.items[index];
                        return _NotificationTile(
                          item: item,
                          onTap: () => _openItem(item),
                        );
                      },
                      childCount: inbox.items.length,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeText = VnDateTime.format(item.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: item.isRead
          ? null
          : const Color(0xFFFF6B35).withOpacity(0.08),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isPhieuApprove
              ? const Color(0xFFFF6B35)
              : Colors.blueGrey,
          child: Icon(
            item.isPhieuApprove
                ? Icons.approval
                : Icons.notifications,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          item.displayTitle,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.message, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              timeText,
              style: TextStyle(
                fontSize: 12,
                color: ThemeColors.getHintColor(context),
              ),
            ),
          ],
        ),
        trailing: item.isPhieuApprove
            ? const Icon(Icons.chevron_right)
            : (!item.isRead
                ? const Icon(Icons.circle, size: 10, color: Color(0xFFFF6B35))
                : null),
        onTap: onTap,
      ),
    );
  }
}
