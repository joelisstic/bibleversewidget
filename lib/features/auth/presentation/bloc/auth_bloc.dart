import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/auth_repository.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}
class SignInRequested extends AuthEvent {}
class SignOutRequested extends AuthEvent {}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}
class Unauthenticated extends AuthState {}
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckRequested>((event, emit) async {
      final user = authRepository.currentUser;
      if (user != null) {
        debugPrint('AuthCheckRequested: User found with email: ${user.email}');
        await _syncUserToFirestore(user);
        emit(Authenticated(user));
      } else {
        debugPrint('AuthCheckRequested: No user found');
        emit(Unauthenticated());
      }
    });

    on<SignInRequested>((event, emit) async {
      debugPrint('SignInRequested: Initializing sign in...');
      emit(AuthLoading());
      try {
        final user = await authRepository.signInWithGoogle();
        if (user != null) {
          debugPrint('SignInRequested: Success! User: ${user.email}');
          await _syncUserToFirestore(user);
          emit(Authenticated(user));
        } else {
          debugPrint('SignInRequested: Sign in aborted by user');
          emit(Unauthenticated());
        }
      } catch (e) {
        debugPrint('SignInRequested: Error occurred: $e');
        emit(AuthFailure(e.toString()));
      }
    });

    on<SignOutRequested>((event, emit) async {
      debugPrint('SignOutRequested: Signing out...');
      await authRepository.signOut();
      emit(Unauthenticated());
    });
  }

  Future<void> _syncUserToFirestore(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('User synced to Firestore: ${user.uid}');
    } catch (e) {
      debugPrint('Error syncing user to Firestore: $e');
    }
  }
}
