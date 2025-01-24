import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:user_auth_crudd10/auth/forget_pass_page.dart';
import 'package:user_auth_crudd10/services/functions/user_data_store.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  //login logic
  Future signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message.toString(),
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red[200],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
        ),
      );
    }
  }

Future<UserCredential?> signInWithGoogle() async {
 try {
   final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
   if (googleUser == null) return null;

   final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
   final credential = GoogleAuthProvider.credential(
     accessToken: googleAuth.accessToken,
     idToken: googleAuth.idToken,
   );

   final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
   
   if (userCredential.additionalUserInfo?.isNewUser ?? false) {
     await storeUserData(
       googleUser.displayName ?? '',
       '', // year
       googleUser.email ?? '',
     );
   }

   return userCredential;
 } catch (e) {
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
       content: Text("Error: $e"),
       backgroundColor: Colors.red[200],
     ),
   );
   return null;
 }
}
  //dispose
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

                //container
                Positioned(
                  top: 80,
                  left: 10,
                  right: 10,
                  bottom: 0,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    child: Container(
                      height: MediaQuery.of(context).size.height *
                          0.9, //chnage old was 700

                      width: 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                            child: Image.asset('assets/images/login.png'),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
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
                          const SizedBox(
                            height: 40,
                          ),
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
                                labelStyle: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              style: const TextStyle(
                                color: Colors
                                    .black, // Cambia el color del texto aquí
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
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
                                labelStyle: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isObscure = !isObscure;
                                    });
                                  },
                                  icon: Icon(
                                    isObscure
                                        ? Icons.lock
                                        : Icons
                                            .no_encryption_gmailerrorred_rounded,
                                  ),
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors
                                    .black, // Cambia el color del texto aquí
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),

                          //remember--forget row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(
                                  width: 40,
                                ),
                                Column(
                                  children: [
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
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          Container(
                            width: size.width * 0.8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.95),
                                  Colors.white.withOpacity(0.8)
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
                              onPressed: signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/images/google.png',
                                      height: 24),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Entrar con Google',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
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
            SizedBox(height: 40),
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
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: Size(double.infinity, 50),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  "Entrar",
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
           const SizedBox(height: 20),
               
               TextButton(
                onPressed: widget.showLoginPage,
                style: ElevatedButton.styleFrom(

                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: Size(double.infinity, 50),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  "Crear cuenta",
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
