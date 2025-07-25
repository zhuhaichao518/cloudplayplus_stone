import 'package:cloudplayplus/pages/main_page.dart';
import 'package:cloudplayplus/services/secure_storage_manager.dart';
import 'package:cloudplayplus/services/shared_preferences_manager.dart';
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../dev_settings.dart/develop_settings.dart';
import '../services/login_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1: login succeed.
  int _loginstate = 0;

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) async {
    var result = await LoginService.login(data.name, data.password);
    if (result['status'] == 'success') {
      _loginstate = 1;
      return null;
    } else {
      return result['message'];
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    try {
      var additionalData = data.additionalSignupData!;
      var password = additionalData['password']!;
      var confirmPassword = additionalData['confirmpassword']!;
      var username = additionalData['username']!;
      var email = additionalData['email']!;
      var nickname = additionalData['nickname']!;

      if (password != confirmPassword) {
        return '两次密码不一致';
      }

      var result =
          await LoginService.register(username, password, email, nickname);
      if (result['status'] == 'success') {
        await LoginService.login(username, password);
        _loginstate = 1;
        return null;
      } else {
        return result['message'];
      }
    } catch (e) {
      return '注册过程中发生错误，检查输入和网络后重试';
    }
  }

  Future<String> _recoverPassword(String name) {
    debugPrint('Name: $name');
    return Future.delayed(loginTime).then((_) {
      return "";
    });
  }

  static String? _userValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Invalid username!';
    }
    return null;
  }

  String? _savedEmail;
  String? _savedPassword;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    if (DevelopSettings.useSecureStorage) {
      SecureStorageManager.getString('username').then((value) {
        setState(() {
          _savedEmail = value;
          _isLoading = false;
        });
      });
      /*SecureStorageManager.getString('password').then((value) {
        setState(() {
          _savedPassword = value;
          _isLoading = false;
        });
      });*/
    } else {
      setState(() {
        _savedEmail = SharedPreferencesManager.getString('username');
        //_savedPassword = SharedPreferencesManager.getString('password');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return FlutterLogin(
        savedEmail: _savedEmail ?? "",
        savedPassword: _savedPassword ?? "",
        title: 'CloudPlay Plus',
        logo: const AssetImage('assets/images/cpp_logo.png'),
        userType: LoginUserType.name,
        onLogin: _authUser,
        onSignup: _signupUser,
        userValidator: _userValidator,
        onSubmitAnimationCompleted: () {
          if (_loginstate == 1) {
            // For unknown reason, when register succeed, there is a "goback" on the topleft.
            // So pushAndRemoveUntil.
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
            ).then((_) => false);
          }
        },
        onRecoverPassword: _recoverPassword,
        isAndroidTV: AppPlatform.isAndroidTV,
        additionalSignupFields: [
          const UserFormField(
            keyName: 'username',
            displayName: '用户名',
            userType: LoginUserType.name,
          ),
          const UserFormField(
            keyName: 'nickname',
            displayName: '昵称',
            icon: Icon(FontAwesomeIcons.userLarge),
            userType: LoginUserType.name,
          ),
          UserFormField(
            keyName: 'email',
            displayName: '邮箱',
            icon: const Icon(Icons.email),
            fieldValidator: (value) {
              final emailRegExp = RegExp(
                r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$',
              );
              if (value != null && !emailRegExp.hasMatch(value)) {
                return "This isn't a valid email address";
              }
              return null;
            },
            userType: LoginUserType.email,
          ),
          const UserFormField(
              keyName: 'password',
              displayName: '密码',
              icon: Icon(FontAwesomeIcons.lock),
              obscureText: true),
          const UserFormField(
              keyName: 'confirmpassword',
              displayName: '确认密码',
              icon: Icon(FontAwesomeIcons.lock),
              obscureText: true),
        ],
      );
    }
  }
}
