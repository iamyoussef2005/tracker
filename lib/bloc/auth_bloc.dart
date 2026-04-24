import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository(),
      super(const AuthState()) {
    on<AuthSessionRequested>(_onSessionRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthSignupSubmitted>(_onSignupSubmitted);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthMessageCleared>(_onMessageCleared);
  }

  final AuthRepository _authRepository;

  Future<void> _onSessionRequested(
    AuthSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));

    try {
      final user = await _authRepository.restoreSession();
      if (user == null) {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearUser: true,
            clearMessage: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          message: 'Unable to restore your session.',
        ),
      );
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));

    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearMessage: true,
        ),
      );
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          clearUser: true,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          clearUser: true,
          message: 'Unable to sign in right now.',
        ),
      );
    }
  }

  Future<void> _onSignupSubmitted(
    AuthSignupSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));

    try {
      final user = await _authRepository.signUp(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
        preferredCurrency: event.preferredCurrency,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearMessage: true,
        ),
      );
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          clearUser: true,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          clearUser: true,
          message: 'Unable to create your account right now.',
        ),
      );
    }
  }

  Future<void> _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));

    try {
      final user = await _authRepository.updateProfile(event.profile);
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          message: 'Profile updated.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: state.user,
          message: 'Unable to update profile.',
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));
    await _authRepository.logout();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearMessage: true,
      ),
    );
  }

  void _onMessageCleared(
    AuthMessageCleared event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(clearMessage: true));
  }
}
