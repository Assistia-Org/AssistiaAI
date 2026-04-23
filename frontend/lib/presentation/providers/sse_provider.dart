import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/sse/sse_client.dart';
import 'invitation_provider.dart';

// Provides the raw SSEClient instance
final sseClientProvider = Provider<SSEClient>((ref) {
  final client = SSEClient();
  ref.onDispose(() {
    client.disconnect();
  });
  return client;
});

// A service that listens to the SSEClient stream and updates state
class SSEService {
  final Ref ref;
  final SSEClient client;

  SSEService(this.ref, this.client) {
    client.stream.listen(_handleEvent);
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'];
    if (type == 'new_invitation') {
      // Refresh incoming requests
      ref.invalidate(myInvitationsProvider);
    }
  }

  void connect(String token) {
    client.connect(token);
  }

  void disconnect() {
    client.disconnect();
  }
}

final sseServiceProvider = Provider<SSEService>((ref) {
  final client = ref.watch(sseClientProvider);
  return SSEService(ref, client);
});
