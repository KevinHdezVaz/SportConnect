import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/forget_pass_page.dart';
import 'package:user_auth_crudd10/pages/home_page.dart';
import 'package:user_auth_crudd10/services/settings/theme_data.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const LoginPage({super.key, required this.showLoginPage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isRember = false;
  bool isObscure = true;

  //textControllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '237230625824-uhg81q3ro2at559t31bnorjqrlooe3lr.apps.googleusercontent.com',
  );
  final _authService = AuthService();

  //login logic
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final response = await _authService.loginWithGoogle(googleAuth.idToken);

      return response;
    } catch (e) {
      print('Error durante el login con Google: $e');
      return false;
    }
  }

  Future signIn() async {
    if (!validateLogin()) return;

    try {
      showDialog(
        context: context,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final success = await _authService.login(
          _emailController.text.trim(), _passwordController.text.trim());

      Navigator.pop(context); // Cierra el loader

      if (success) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => AuthCheckMain()));
      } else {
        showErrorSnackBar('Credenciales inválidas');
      }
    } catch (e) {
      showErrorSnackBar(e.toString());
    }
  }

  //dispose
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool validateLogin() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showErrorSnackBar("Por favor complete todos los campos");
      return false;
    }

    if (!_emailController.text.contains('@')) {
      showErrorSnackBar("Correo electrónico inválido");
      return false;
    }

    if (_passwordController.text.length < 6) {
      showErrorSnackBar("La contraseña debe tener al menos 6 caracteres");
      return false;
    }

    return true;
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 234, 61, 61),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(90, 20, 0, 0),
                  child: Image.asset('assets/images/grad2.png'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 100, 0),
                  child: Image.asset('assets/images/grad1.png'),
                ),

                // Rectángulo blanco
                Padding(
                  padding: const EdgeInsets.only(
                      top: 50), // Ajusta este valor para bajar el rectángulo
                  child: Center(
                    child: Container(
                      height: size.height * 0.75, // 3/4 de la pantalla
                      width: size.width * 0.9, // Ancho del 90% de la pantalla
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                            child: Image.asset(
                              'assets/icons/logoapp.webp',
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              "Ingresa tu correo y contraseña o crea una cuenta.",
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          //email textfield
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              cursorColor: lightTheme.primaryColor,
                              controller: _emailController,
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width: 0.8,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 0.8,
                                  ),
                                ),
                                labelText: "Correo",
                                labelStyle: TextStyle(color: Colors.black),
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 20),
                          //password textfield
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              cursorColor: lightTheme.primaryColor,
                              controller: _passwordController,
                              obscureText: isObscure,
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width: 0.8,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 0.8,
                                  ),
                                ),
                                labelText: " Contraseña ",
                                labelStyle: TextStyle(color: Colors.black),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isObscure = !isObscure;
                                    });
                                  },
                                  icon: Icon(
                                    isObscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 20),
                          //remember--forget row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      isRember = !isRember;
                                    });
                                  },
                                  icon: Icon(
                                    isRember
                                        ? Icons.check_box_outline_blank
                                        : Icons.check_box,
                                  ),
                                ),
                                const Text(
                                  'Recordarme',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(width: 40),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgetPassPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Olvide contraseña",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.black,
                                      decorationThickness:
                                          1.5, // Grosor del subrayado
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 60),
                          // Botón "Entrar"
                          Container(
                            width: size.width * 0.8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.9),
                                  Colors.white.withOpacity(0.7)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shadowColor: Colors.black.withOpacity(0.3),
                                elevation: 10,
                                minimumSize: Size(double.infinity, 50),
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: Text(
                                "Entrar",
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: widget.showLoginPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: Size(double.infinity, 50),
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                "Crea tu cuenta",
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
