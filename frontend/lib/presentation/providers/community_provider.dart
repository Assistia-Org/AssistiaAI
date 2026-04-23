import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../data/datasources/community/community_remote_data_source.dart';
import '../../data/repositories/community/community_repository_impl.dart';
import '../../domain/entities/community/community.dart';
import '../../domain/usecases/community/create_community_usecase.dart';
import '../../domain/usecases/community/get_my_communities_usecase.dart';
import '../../domain/usecases/community/get_community_by_id_usecase.dart';
import '../../domain/usecases/community/update_community_usecase.dart';
import '../../domain/usecases/community/delete_community_usecase.dart';
import '../../domain/usecases/community/leave_community_usecase.dart';
import '../../domain/usecases/community/remove_community_member_usecase.dart';

// --- Dependency Injection ---

final communityRemoteDataSourceProvider =
    FutureProvider<CommunityRemoteDataSource>((ref) async {
      final prefs = await ref.watch(sharedPrefsProvider.future);
      final client = ref.watch(httpClientProvider);
      return CommunityRemoteDataSource(
        client: client,
        sharedPreferences: prefs,
      );
    });

final communityRepositoryProvider = FutureProvider<CommunityRepositoryImpl>((
  ref,
) async {
  final remoteDataSource = await ref.watch(
    communityRemoteDataSourceProvider.future,
  );
  return CommunityRepositoryImpl(remoteDataSource: remoteDataSource);
});

final createCommunityUseCaseProvider = FutureProvider<CreateCommunityUseCase>((
  ref,
) async {
  final repository = await ref.watch(communityRepositoryProvider.future);
  return CreateCommunityUseCase(repository);
});

final getMyCommunitiesUseCaseProvider = FutureProvider<GetMyCommunitiesUseCase>(
  (ref) async {
    final repository = await ref.watch(communityRepositoryProvider.future);
    return GetMyCommunitiesUseCase(repository);
  },
);

final getCommunityByIdUseCaseProvider = FutureProvider<GetCommunityByIdUseCase>(
  (ref) async {
    final repository = await ref.watch(communityRepositoryProvider.future);
    return GetCommunityByIdUseCase(repository);
  },
);

final updateCommunityUseCaseProvider = FutureProvider<UpdateCommunityUseCase>((
  ref,
) async {
  final repository = await ref.watch(communityRepositoryProvider.future);
  return UpdateCommunityUseCase(repository);
});

final deleteCommunityUseCaseProvider = FutureProvider<DeleteCommunityUseCase>((
  ref,
) async {
  final repository = await ref.watch(communityRepositoryProvider.future);
  return DeleteCommunityUseCase(repository);
});

final leaveCommunityUseCaseProvider = FutureProvider<LeaveCommunityUseCase>((
  ref,
) async {
  final repository = await ref.watch(communityRepositoryProvider.future);
  return LeaveCommunityUseCase(repository);
});

final removeCommunityMemberUseCaseProvider = FutureProvider<RemoveCommunityMemberUseCase>((
  ref,
) async {
  final repository = await ref.watch(communityRepositoryProvider.future);
  return RemoveCommunityMemberUseCase(repository);
});

// --- State Management ---

class CommunityLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool val) {
    state = val;
  }
}

final communityLoadingProvider =
    NotifierProvider<CommunityLoadingNotifier, bool>(() {
      return CommunityLoadingNotifier();
    });

class CommunityController {
  final Ref ref;

  CommunityController(this.ref);

  Future<Community> createCommunity({
    required String name,
    required String type,
  }) async {
    ref.read(communityLoadingProvider.notifier).setLoading(true);
    try {
      final useCase = await ref.read(createCommunityUseCaseProvider.future);
      return await useCase.call(name: name, type: type);
    } finally {
      ref.read(communityLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<List<Community>> getMyCommunities() async {
    final useCase = await ref.read(getMyCommunitiesUseCaseProvider.future);
    return await useCase.call();
  }

  Future<Community> getCommunityById(String id) async {
    final useCase = await ref.read(getCommunityByIdUseCaseProvider.future);
    return await useCase.call(id);
  }

  Future<Community> updateCommunity({
    required String id,
    String? name,
    String? type,
    List<CommunityMember>? members,
  }) async {
    ref.read(communityLoadingProvider.notifier).setLoading(true);
    try {
      final useCase = await ref.read(updateCommunityUseCaseProvider.future);
      return await useCase.call(
        id: id,
        name: name,
        type: type,
        members: members,
      );
    } finally {
      ref.read(communityLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> deleteCommunity(String id) async {
    ref.read(communityLoadingProvider.notifier).setLoading(true);
    try {
      final useCase = await ref.read(deleteCommunityUseCaseProvider.future);
      await useCase.call(id);
    } finally {
      ref.read(communityLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> leaveCommunity(String id) async {
    ref.read(communityLoadingProvider.notifier).setLoading(true);
    try {
      final useCase = await ref.read(leaveCommunityUseCaseProvider.future);
      await useCase.call(id);
    } finally {
      ref.read(communityLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> removeCommunityMember(String communityId, String userId) async {
    ref.read(communityLoadingProvider.notifier).setLoading(true);
    try {
      final useCase = await ref.read(removeCommunityMemberUseCaseProvider.future);
      await useCase.call(communityId, userId);
    } finally {
      ref.read(communityLoadingProvider.notifier).setLoading(false);
    }
  }
}

final communityControllerProvider = Provider<CommunityController>((ref) {
  return CommunityController(ref);
});

final myCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  final useCase = await ref.watch(getMyCommunitiesUseCaseProvider.future);
  final List<Community> rawResult = await useCase.call();
  // Create a new list copy to break the inheritance chain at runtime
  return List<Community>.from(rawResult.map((e) => e));
});
