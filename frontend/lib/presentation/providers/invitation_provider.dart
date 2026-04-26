import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/invitation/invitation_remote_data_source.dart';
import '../../data/repositories/invitation/invitation_repository_impl.dart';
import '../../domain/entities/invitation/community_invitation.dart';
import '../../domain/usecases/invitation/accept_invitation_usecase.dart';
import '../../domain/usecases/invitation/get_my_invitations_usecase.dart';
import '../../domain/usecases/invitation/reject_invitation_usecase.dart';
import '../../domain/usecases/invitation/send_invitation_usecase.dart';
import 'auth_provider.dart';
import 'community_provider.dart';

// --- Data Source & Repository Providers ---
// Uses sharedPrefsProvider and httpClientProvider from auth_provider.dart

final invitationRemoteDataSourceProvider =
    FutureProvider<InvitationRemoteDataSource>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  final client = ref.watch(httpClientProvider);
  return InvitationRemoteDataSource(
    client: client,
    sharedPreferences: prefs,
  );
});

final invitationRepositoryProvider =
    FutureProvider<InvitationRepositoryImpl>((ref) async {
  final remoteDataSource =
      await ref.watch(invitationRemoteDataSourceProvider.future);
  return InvitationRepositoryImpl(remoteDataSource: remoteDataSource);
});

// --- Use Case Providers ---

final sendInvitationUseCaseProvider =
    FutureProvider<SendInvitationUseCase>((ref) async {
  final repo = await ref.watch(invitationRepositoryProvider.future);
  return SendInvitationUseCase(repo);
});

final getMyInvitationsUseCaseProvider =
    FutureProvider<GetMyInvitationsUseCase>((ref) async {
  final repo = await ref.watch(invitationRepositoryProvider.future);
  return GetMyInvitationsUseCase(repo);
});

final acceptInvitationUseCaseProvider =
    FutureProvider<AcceptInvitationUseCase>((ref) async {
  final repo = await ref.watch(invitationRepositoryProvider.future);
  return AcceptInvitationUseCase(repo);
});

final rejectInvitationUseCaseProvider =
    FutureProvider<RejectInvitationUseCase>((ref) async {
  final repo = await ref.watch(invitationRepositoryProvider.future);
  return RejectInvitationUseCase(repo);
});

// --- State Providers ---

final myInvitationsProvider =
    FutureProvider<List<CommunityInvitation>>((ref) async {
  final useCase = await ref.watch(getMyInvitationsUseCaseProvider.future);
  return await useCase();
});

// --- Controller ---

class InvitationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendInvitation({
    required String communityId,
    required String inviteeEmail,
  }) async {
    state = const AsyncLoading();
    try {
      final useCase = await ref.read(sendInvitationUseCaseProvider.future);
      await useCase(communityId: communityId, inviteeEmail: inviteeEmail);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow; // propagate to UI catch block
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    state = const AsyncLoading();
    try {
      final useCase = await ref.read(acceptInvitationUseCaseProvider.future);
      await useCase(invitationId);
      ref.invalidate(myInvitationsProvider);
      ref.invalidate(myCommunitiesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> rejectInvitation(String invitationId) async {
    state = const AsyncLoading();
    try {
      final useCase = await ref.read(rejectInvitationUseCaseProvider.future);
      await useCase(invitationId);
      ref.invalidate(myInvitationsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final invitationControllerProvider =
    AsyncNotifierProvider<InvitationController, void>(
  InvitationController.new,
);
