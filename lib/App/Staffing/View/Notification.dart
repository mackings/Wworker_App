import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wworker/App/Staffing/Api/noificatonservice.dart';
import 'package:wworker/App/Staffing/Model/NotificationModel.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  bool hasMore = true;
  int currentPage = 1;
  int unreadCount = 0;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoading && hasMore) {
        _loadMoreNotifications();
      }
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => isLoading = true);

    try {
      final response = await _notificationService.getNotifications(
        page: 1,
        limit: 20,
      );

      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          notifications = (data['notifications'] as List)
              .map((n) => NotificationModel.fromJson(n))
              .toList();
          currentPage = data['pagination']['page'];
          hasMore = currentPage < data['pagination']['pages'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showError(response['message'] ?? 'Failed to load notifications');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Error loading notifications: $e');
    }
  }

  Future<void> _loadMoreNotifications() async {
    try {
      final response = await _notificationService.getNotifications(
        page: currentPage + 1,
        limit: 20,
      );

      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          notifications.addAll(
            (data['notifications'] as List)
                .map((n) => NotificationModel.fromJson(n))
                .toList()
          );
          currentPage = data['pagination']['page'];
          hasMore = currentPage < data['pagination']['pages'];
        });
      }
    } catch (e) {
      _showError('Error loading more notifications: $e');
    }
  }

  Future<void> _loadUnreadCount() async {
    final response = await _notificationService.getUnreadCount();
    if (response['success'] == true) {
      setState(() {
        unreadCount = response['data']['count'] ?? 0;
      });
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    final response = await _notificationService.markAsRead(
      notificationId: notification.id,
    );

    if (response['success'] == true) {
      setState(() {
        final index = notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          notifications[index] = NotificationModel(
            id: notification.id,
            userId: notification.userId,
            companyName: notification.companyName,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            isRead: true,
            performedBy: notification.performedBy,
            performedByName: notification.performedByName,
            createdAt: notification.createdAt,
          );
          if (unreadCount > 0) unreadCount--;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final response = await _notificationService.markAllAsRead();

    if (response['success'] == true) {
      setState(() {
        notifications = notifications.map((n) => NotificationModel(
          id: n.id,
          userId: n.userId,
          companyName: n.companyName,
          type: n.type,
          title: n.title,
          message: n.message,
          isRead: true,
          performedBy: n.performedBy,
          performedByName: n.performedByName,
          createdAt: n.createdAt,
        )).toList();
        unreadCount = 0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showError(response['message'] ?? 'Failed to mark all as read');
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final response = await _notificationService.deleteNotification(
      notificationId: notification.id,
    );

    if (response['success'] == true) {
      setState(() {
        notifications.removeWhere((n) => n.id == notification.id);
        if (!notification.isRead && unreadCount > 0) {
          unreadCount--;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notification deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showError(response['message'] ?? 'Failed to delete notification');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'permissions_updated':
      case 'permission_granted':
      case 'permission_revoked':
        return Icons.security;
      case 'staff_invited':
        return Icons.person_add;
      case 'staff_removed':
        return Icons.person_remove;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'permission_granted':
        return Colors.green;
      case 'permission_revoked':
        return Colors.orange;
      case 'permissions_updated':
        return Colors.blue;
      case 'staff_removed':
        return Colors.red;
      default:
        return const Color(0xFF8B4513);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF302E2E),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadNotifications();
          await _loadUnreadCount();
        },
        child: isLoading && notifications.isEmpty
            ? const Center(child: CircularProgressIndicator(
                color: Color(0xFF8B4513),
              ))
            : notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length + (hasMore ? 1 : 0),
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == notifications.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: Color(0xFF8B4513),
                            ),
                          ),
                        );
                      }

                      final notification = notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (direction) {
                          _deleteNotification(notification);
                        },
                        child: InkWell(
                          onTap: () => _markAsRead(notification),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: notification.isRead 
                                  ? Colors.white 
                                  : const Color(0xFF8B4513).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(notification.type)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getNotificationIcon(notification.type),
                                    color: _getNotificationColor(notification.type),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification.title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: notification.isRead 
                                                    ? FontWeight.w500 
                                                    : FontWeight.w600,
                                                color: const Color(0xFF302E2E),
                                              ),
                                            ),
                                          ),
                                          if (!notification.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF8B4513),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification.message,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        timeago.format(notification.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}