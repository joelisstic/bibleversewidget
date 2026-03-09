import 'package:get_it/get_it.dart';
import 'features/promise_box/data/repositories/bible_repository_impl.dart';
import 'features/promise_box/domain/repositories/bible_repository.dart';
import 'features/promise_box/domain/usecases/get_verses.dart';
import 'features/promise_box/presentation/bloc/promise_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoC
  sl.registerFactory(() => PromiseBloc(getVersesUseCase: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetVerses(sl()));

  // Repository
  sl.registerLazySingleton<BibleRepository>(() => BibleRepositoryImpl());
}
