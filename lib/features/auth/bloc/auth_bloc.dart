import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../../../main.dart' show authNotifier;

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String password2;
  AuthRegisterRequested(this.username, this.email, this.password, this.password2);
}

class AuthLogoutRequested extends AuthEvent {}
class AuthCheckRequested extends AuthEvent {}
class AuthGoogleRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _api;

  AuthBloc(this._api) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthGoogleRequested>(_onGoogleSignIn);
  }

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final loggedIn = await LocalStorage.isLoggedIn();
    authNotifier.value = loggedIn;
    emit(loggedIn ? AuthAuthenticated() : AuthUnauthenticated());
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final data = await _api.login(event.email, event.password);
      await LocalStorage.saveTokens(data['access'] ?? '', data['refresh'] ?? '');
      await LocalStorage.saveUserInfo(event.email.split('@').first, event.email);
      authNotifier.value = true;
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError('Email ou mot de passe incorrect.'));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _api.register(event.username, event.email, event.password, event.password2);
      final data = await _api.login(event.email, event.password);
      await LocalStorage.saveTokens(data['access'] ?? '', data['refresh'] ?? '');
      await LocalStorage.saveUserInfo(event.username, event.email);
      authNotifier.value = true;
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError('Erreur lors de la création du compte.'));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await LocalStorage.clearTokens();
    authNotifier.value = false;
    emit(AuthUnauthenticated());
  }

  Future<void> _onGoogleSignIn(AuthGoogleRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '929532321800-b6iskg5f6gsokmq1jjnpp8lpcvb0fv3r.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) { emit(AuthUnauthenticated()); return; }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) { emit(AuthError('Erreur Google Sign-In')); return; }
      final data = await _api.googleLogin(idToken);
      await LocalStorage.saveTokens(data['access'] ?? '', data['refresh'] ?? '');
      await LocalStorage.saveUserInfo(googleUser.displayName ?? googleUser.email.split('@').first, googleUser.email);
      authNotifier.value = true;
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError('Erreur lors de la connexion Google.'));
    }
  }
}

