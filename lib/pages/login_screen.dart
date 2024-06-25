import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/login_service.dart';

const users = {
  'dribbble@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
};

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) {
    debugPrint('Name: ${data.name}, Password: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(data.name)) {
        return 'User not exists';
      }
      if (users[data.name] != data.password) {
        return 'Password does not match';
      }
      return null;
    });
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

    var result = await LoginService.register(username, password, email, nickname);
    if (result['status'] == 'success') {
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
      if (!users.containsKey(name)) {
        return 'User not exists';
      }
      return "";
    });
  }

  static String? _userValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Invalid username!';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'CloudPlay Plus',
      logo: const AssetImage('assets/images/cpp_logo.png'),
      userType: LoginUserType.name,
      onLogin: _authUser,
      onSignup: _signupUser,
      userValidator: _userValidator,
      onSubmitAnimationCompleted: () {
        /*Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ));*/
      },
      onRecoverPassword: _recoverPassword,
      additionalSignupFields: [
        const UserFormField(
          keyName: 'username',
          displayName: '用户名',
        ),
        const UserFormField(keyName: 'nickname',displayName: '昵称',          icon: Icon(FontAwesomeIcons.userLarge),),
        UserFormField(
          keyName: 'email',
          displayName: '邮箱',
          icon: const Icon(Icons.email),
          fieldValidator: (value) {
            final emailRegExp = RegExp(
              r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$',
            );
            if (value != null &&
                !emailRegExp.hasMatch(value)) {
              return "This isn't a valid email address";
            }
            return null;
          },
        ),
        const UserFormField(
          keyName: 'password',
          displayName: '密码',
          icon: Icon(FontAwesomeIcons.lock),
          obscureText: true
        ),
        const UserFormField(
          keyName: 'confirmpassword',
          displayName: '确认密码',
          icon: Icon(FontAwesomeIcons.lock),
          obscureText: true
        ),
      ],
    );
  }
}
