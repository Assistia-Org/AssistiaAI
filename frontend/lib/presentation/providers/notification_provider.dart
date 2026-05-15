import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/notification/notification_remote_datasource.dart';
import '../../data/models/notification/notification_model.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

// ── Bildirim Toggle (Açık/Kapalı) ──────────────────────────────────────────────────

/// Bildirim toggle durumunu currentUserProvider.personalSettings.notifications
/// alanından okur. toggle() çağrıldığında backend'e PATCH atar ve
/// currentUserProvider'u güncellenince build() otomatik yenilenir.
class NotificationsEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // currentUserProvider değişince bu notifier yeniden build edilir.
    final user = ref.watch(currentUserProvider);
    return user?.personalSettings?.notifications ?? true;
  }

  Future<void> toggle() async {
    final current = await future;
    // isLoading = true → UI'daki onTap null olur, çifte basma engellenir.
    state = const AsyncLoading();
    try {
      final settings =
          ref.read(personalSettingsProvider).copyWith(notifications: !current);
      // updateSettings, currentUserProvider'u günceller → build() tekrar çalışır.
      await ref.read(userControllerProvider).updateSettings(settings);
    } catch (e, st) {
      // Hata durumunda önceki değere geri dön.
      state = AsyncData(current);
    }
  }
}

final notificationsEnabledProvider =
    AsyncNotifierProvider<NotificationsEnabledNotifier, bool>(
  NotificationsEnabledNotifier.new,
);

// ── datasource provider ──────────────────────────────────────────────────────

final notificationDataSourceProvider = FutureProvider<NotificationRemoteDataSource>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return NotificationRemoteDataSource(
    client: http.Client(),
    sharedPreferences: prefs,
  );
});

// ── state notifier ────────────────────────────────────────────────────────────

class NotificationNotifier extends AsyncNotifier<NotificationListModel> {
  @override
  Future<NotificationListModel> build() async {
    return _fetch();
  }

  Future<NotificationListModel> _fetch() async {
    final ds = await ref.read(notificationDataSourceProvider.future);
    return ds.getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> markAsRead(String id) async {
    final ds = await ref.read(notificationDataSourceProvider.future);
    await ds.markAsRead(id);
    // Update local state without full refetch
    state.whenData((data) {
      final updated = data.notifications.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList();
      final newUnread = updated.where((n) => !n.isRead).length;
      state = AsyncData(
        NotificationListModel(notifications: updated, unreadCount: newUnread),
      );
    });
  }

  Future<void> markAllAsRead() async {
    final ds = await ref.read(notificationDataSourceProvider.future);
    await ds.markAllAsRead();
    state.whenData((data) {
      final updated = data.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = AsyncData(
        NotificationListModel(notifications: updated, unreadCount: 0),
      );
    });
  }

  Future<void> delete(String id) async {
    final ds = await ref.read(notificationDataSourceProvider.future);
    await ds.deleteNotification(id);
    state.whenData((data) {
      final updated = data.notifications.where((n) => n.id != id).toList();
      final newUnread = updated.where((n) => !n.isRead).length;
      state = AsyncData(
        NotificationListModel(notifications: updated, unreadCount: newUnread),
      );
    });
  }
}

final notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, NotificationListModel>(
  NotificationNotifier.new,
);

// Convenience provider for just the unread count (for badge)
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).whenOrNull(
        data: (data) => data.unreadCount,
      ) ??
      0;
});

/// Toggle kapalıysa boş NotificationListModel döndürür,
/// açıksa gerçek backend verisini olduğu gibi geçirir.
final filteredNotificationProvider = Provider<AsyncValue<NotificationListModel>>((ref) {
  final enabledAsync = ref.watch(notificationsEnabledProvider);
  final notificationsAsync = ref.watch(notificationProvider);

  return enabledAsync.when(
    data: (enabled) {
      if (!enabled) {
        // Kapalı: boş liste döndür, backend'e istek atmaya devam et
        return const AsyncData(
          NotificationListModel(notifications: [], unreadCount: 0),
        );
      }
      return notificationsAsync;
    },
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

/// Toggle durumuna göre filtrelenmiş unread count
final filteredUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(filteredNotificationProvider).whenOrNull(
        data: (data) => data.unreadCount,
      ) ??
      0;
});
