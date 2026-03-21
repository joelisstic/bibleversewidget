import 'package:bible_verse_widget/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:get_it/get_it.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/promise_box/data/repositories/bible_repository_impl.dart';
import 'features/promise_box/domain/repositories/bible_repository.dart';
import 'features/promise_box/domain/usecases/get_verses.dart';
import 'features/promise_box/presentation/bloc/promise_bloc.dart';
import 'features/promise_box_online/data/repositories/bible_online_repository_impl.dart';
import 'features/promise_box_online/domain/repositories/bible_online_repository.dart';
import 'features/promise_box_online/presentation/bloc/promise_online_bloc.dart';
import 'features/promise_box_group/presentation/bloc/promise_group_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoC
  sl.registerFactory(()=>AuthBloc(authRepository: sl()));
  sl.registerFactory(() => PromiseBloc(getVersesUseCase: sl()));
  sl.registerFactory(() => PromiseOnlineBloc(repository: sl()));
  sl.registerFactory(() => PromiseGroupBloc());

  // Use cases
  sl.registerLazySingleton(() => GetVerses(sl()));

  // Repository
  sl.registerLazySingleton<BibleRepository>(() => BibleRepositoryImpl());
  sl.registerLazySingleton<BibleOnlineRepository>(() => BibleOnlineRepositoryImpl());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
}
