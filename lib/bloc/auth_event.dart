import 'package:equatable/equatable.dart';

import '../models/user_profile.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSessionRequested extends AuthEvent {
  const AuthSessionRequested();
}

class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignupSubmitted extends AuthEvent {
  const AuthSignupSubmitted({
    required this.email,
    required this.password,
    required this.displayName,
    required this.preferredCurrency,
  });

  final String email;
  final String password;
  final String displayName;
  final String preferredCurrency;

  @override
  List<Object?> get props => [
    email,
    password,
    displayName,
    preferredCurrency,
  ];
}

class AuthProfileUpdateRequested extends AuthEvent {
  const AuthProfileUpdateRequested(this.profile);

  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthMessageCleared extends AuthEvent {
  const AuthMessageCleared();
}
