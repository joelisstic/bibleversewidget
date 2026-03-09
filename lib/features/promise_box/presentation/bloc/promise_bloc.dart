import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:home_widget/home_widget.dart';
import '../../domain/entities/bible_verse.dart';
import '../../domain/usecases/get_verses.dart';

// Events
abstract class PromiseEvent extends Equatable {
  const PromiseEvent();
  @override
  List<Object> get props => [];
}

class LoadVersesEvent extends PromiseEvent {}

class GetRandomVerseEvent extends PromiseEvent {}

class UpdateWidgetEvent extends PromiseEvent {
  final BibleVerse verse;
  const UpdateWidgetEvent(this.verse);
}

// States
abstract class PromiseState extends Equatable {
  const PromiseState();
  @override
  List<Object?> get props => [];
}

class PromiseInitial extends PromiseState {}

class PromiseLoading extends PromiseState {}

class PromiseLoaded extends PromiseState {
  final List<BibleVerse> allVerses;
  final BibleVerse? currentVerse;

  const PromiseLoaded({required this.allVerses, this.currentVerse});

  @override
  List<Object?> get props => [allVerses, currentVerse];
}

class PromiseError extends PromiseState {
  final String message;
  const PromiseError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class PromiseBloc extends Bloc<PromiseEvent, PromiseState> {
  final GetVerses getVersesUseCase;

  PromiseBloc({required this.getVersesUseCase}) : super(PromiseInitial()) {
    on<LoadVersesEvent>((event, emit) async {
      emit(PromiseLoading());
      try {
        final verses = await getVersesUseCase();
        emit(PromiseLoaded(allVerses: verses));
      } catch (e) {
        emit(PromiseError(e.toString()));
      }
    });

    on<GetRandomVerseEvent>((event, emit) {
      if (state is PromiseLoaded) {
        final currentState = state as PromiseLoaded;
        if (currentState.allVerses.isNotEmpty) {
          final randomVerse = currentState.allVerses[Random().nextInt(currentState.allVerses.length)];
          
          // Update the widget whenever a new verse is picked
          add(UpdateWidgetEvent(randomVerse));

          emit(PromiseLoaded(
            allVerses: currentState.allVerses,
            currentVerse: randomVerse,
          ));
        }
      }
    });

    on<UpdateWidgetEvent>((event, emit) async {
      await HomeWidget.saveWidgetData<String>('widget_quote', event.verse.sentence);
      await HomeWidget.saveWidgetData<String>('widget_reference', event.verse.reference);
      await HomeWidget.updateWidget(
        name: 'BibleVerseWidgetProvider',
        androidName: 'BibleVerseWidgetProvider',
      );
    });
  }
}
