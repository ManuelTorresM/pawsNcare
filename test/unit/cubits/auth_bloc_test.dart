import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawsncare/data/repositories/base_repository.dart';
import 'package:pawsncare/data/repositories/repository_selector.dart';
import 'package:pawsncare/logic/auth/auth_bloc.dart';

class MockRepositorySelector extends Mock implements RepositorySelector {}
class MockBaseRepository extends Mock implements BaseRepository {}

void main() {
  late MockRepositorySelector mockRepositorySelector;
  late MockBaseRepository mockRepository;

  setUp(() {
    mockRepositorySelector = MockRepositorySelector();
    mockRepository = MockBaseRepository();
    when(() => mockRepositorySelector.getActiveRepository())
        .thenAnswer((_) async => mockRepository);
  });

  group('AuthBloc Unit Tests', () {
    test('initial state is AuthInitial', () {
      expect(AuthBloc(repositorySelector: mockRepositorySelector).state, equals(AuthInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when AuthCheckRequested is triggered and user is logged in',
      build: () {
        when(() => mockRepository.isLoggedIn()).thenAnswer((_) async => true);
        when(() => mockRepository.getCurrentUserEmail()).thenAnswer((_) async => 'user@test.com');
        when(() => mockRepository.getCurrentUserName()).thenAnswer((_) async => 'Test User');
        return AuthBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        AuthLoading(),
        const Authenticated(email: 'user@test.com', name: 'Test User'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when AuthCheckRequested is triggered and user is not logged in',
      build: () {
        when(() => mockRepository.isLoggedIn()).thenAnswer((_) async => false);
        return AuthBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        AuthLoading(),
        Unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on successful LoginSubmitted',
      build: () {
        when(() => mockRepository.login('test@test.com', 'password123')).thenAnswer((_) async => true);
        when(() => mockRepository.getCurrentUserEmail()).thenAnswer((_) async => 'test@test.com');
        when(() => mockRepository.getCurrentUserName()).thenAnswer((_) async => 'Test User');
        return AuthBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(const LoginSubmitted('test@test.com', 'password123')),
      expect: () => [
        AuthLoading(),
        const Authenticated(email: 'test@test.com', name: 'Test User'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] on failed LoginSubmitted',
      build: () {
        when(() => mockRepository.login('wrong@test.com', 'badpass')).thenAnswer((_) async => false);
        return AuthBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(const LoginSubmitted('wrong@test.com', 'badpass')),
      expect: () => [
        AuthLoading(),
        const AuthFailure("Authentication failed"),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on successful RegisterSubmitted',
      build: () {
        when(() => mockRepository.register('new@test.com', 'pass1234', 'New User'))
            .thenAnswer((_) async => true);
        when(() => mockRepository.getCurrentUserEmail()).thenAnswer((_) async => 'new@test.com');
        when(() => mockRepository.getCurrentUserName()).thenAnswer((_) async => 'New User');
        return AuthBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(const RegisterSubmitted(email: 'new@test.com', password: 'pass1234', name: 'New User')),
      expect: () => [
        AuthLoading(),
        const Authenticated(email: 'new@test.com', name: 'New User'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] on LogoutRequested',
      build: () {
        when(() => mockRepository.logout()).thenAnswer((_) async {});
        return AuthBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(LogoutRequested()),
      expect: () => [
        AuthLoading(),
        Unauthenticated(),
      ],
    );
  });
}
