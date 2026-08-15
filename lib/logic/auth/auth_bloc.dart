import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/repository_selector.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String name;
  const RegisterSubmitted({required this.email, required this.password, required this.name});
  @override
  List<Object?> get props => [email, password, name];
}

class LogoutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String email;
  final String name;
  const Authenticated({required this.email, required this.name});
  @override
  List<Object?> get props => [email, name];
}

class Unauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String error;
  const AuthFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RepositorySelector repositorySelector;

  AuthBloc({required this.repositorySelector}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final repo = await repositorySelector.getActiveRepository();
      final loggedIn = await repo.isLoggedIn();
      if (loggedIn) {
        final email = await repo.getCurrentUserEmail();
        final name = await repo.getCurrentUserName();
        emit(Authenticated(email: email ?? '', name: name ?? ''));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final repo = await repositorySelector.getActiveRepository();
      final success = await repo.login(event.email, event.password);
      if (success) {
        final email = await repo.getCurrentUserEmail();
        final name = await repo.getCurrentUserName();
        emit(Authenticated(email: email ?? '', name: name ?? ''));
      } else {
        emit(const AuthFailure("Authentication failed"));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegisterSubmitted(RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final repo = await repositorySelector.getActiveRepository();
      final success = await repo.register(event.email, event.password, event.name);
      if (success) {
        final email = await repo.getCurrentUserEmail();
        final name = await repo.getCurrentUserName();
        emit(Authenticated(email: email ?? '', name: name ?? ''));
      } else {
        emit(const AuthFailure("Registration failed"));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final repo = await repositorySelector.getActiveRepository();
      await repo.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
