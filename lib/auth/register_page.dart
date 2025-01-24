// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:user_auth_crudd10/services/functions/user_data_store.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showSignUpPage;
  const RegisterPage({super.key, required this.showSignUpPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isObscure = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confromPasswordController = TextEditingController();
  final _yearController = TextEditingController();
final GoogleSignIn _googleSignIn = GoogleSignIn();

  //check passoword same or not
  bool checkPassowrd() {
    if (_passwordController.text.trim() ==
        _confromPasswordController.text.trim()) {
      return true;
    } else {
      return false;
    }
  }
Future<void> signInWithGoogle() async {
 try {
   final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
   if (googleUser == null) return;

   final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
   final credential = GoogleAuthProvider.credential(
     accessToken: googleAuth.accessToken, 
     idToken: googleAuth.idToken,
   );

   // Obtenemos el UserCredential y verificamos si es nuevo usuario
   final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
   if (userCredential.additionalUserInfo?.isNewUser ?? false) {
     // Solo guardamos en Firestore si es nuevo usuario
     await storeUserData(
       googleUser.displayName ?? '',
       '', // year 
       googleUser.email ?? '',
     );
   }

 } catch (e) {
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
       content: Text("Error: $e"),
       backgroundColor: Colors.red[200],
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
       ),
     ),
   );
 }
}

  //method to create account
  Future signUp() async {
    try {
      if (checkPassowrd()) {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        User? user = userCredential.user;
        if (user != null) {
          await storeUserData(
            _nameController.text.trim(),
            _yearController.text.trim(),
            _emailController.text.trim(),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Password is Incorrect"),
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
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message.toString()),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confromPasswordController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
        final size = MediaQuery.of(context).size;

    return Scaffold(
        appBar: AppBar(
          title: const Text("Registro"),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
    backgroundColor: Colors.transparent,
    elevation: 10,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
      onPressed: () => Navigator.of(context).pop(),
    ),
  ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                 Padding(
                   padding:
                       const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                   child: Container(
                     height: 500,
                     width: 350,
                     decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.surface,
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: SingleChildScrollView(
                       child: Column(
                         children: [
                           Padding(
                             padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                             child: Image.asset('assets/images/signup.png'),
                           ),
                           const SizedBox(
                             height: 15,
                           ),
                           Text(
                             "Completa tu registro.",
                             style: GoogleFonts.lato(
                               fontSize: 17,
                               fontWeight: FontWeight.w400,
                               color: Colors.grey[600],
                             ),
                           ),
                           const SizedBox(
                             height: 30,
                           ),
                           Padding(
                             padding:
                                 const EdgeInsets.symmetric(horizontal: 20),
                             child: TextField(
                               cursorColor: Colors.white,
                               controller: _nameController,
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
                                     color: Colors.purpleAccent,
                                     width: 0.8,
                                   ),
                                 ),
                                 labelText: " Full Name ",
                                 labelStyle: TextStyle(
                                     color: Theme.of(context)
                                         .colorScheme
                                         .secondary),
                               ),
                             ),
                           ),
                           const SizedBox(
                             height: 20,
                           ),
                           Padding(
                             padding:
                                 const EdgeInsets.symmetric(horizontal: 20),
                             child: TextField(
                               cursorColor: Colors.white,
                               controller: _yearController,
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
                                     color: Colors.purpleAccent,
                                     width: 0.8,
                                   ),
                                 ),
                                 labelText: " Year ",
                                 labelStyle: TextStyle(
                                     color: Theme.of(context)
                                         .colorScheme
                                         .secondary),
                               ),
                             ),
                           ),
                           const SizedBox(
                             height: 20,
                           ),
                           //email textfield
                           Padding(
                             padding:
                                 const EdgeInsets.symmetric(horizontal: 20),
                             child: TextField(
                               cursorColor: Colors.white,
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
                                     color: Colors.purpleAccent,
                                     width: 0.8,
                                   ),
                                 ),
                                 labelText: " Email ",
                                 labelStyle: TextStyle(
                                     color: Theme.of(context)
                                         .colorScheme
                                         .secondary),
                               ),
                             ),
                           ),
                           const SizedBox(
                             height: 20,
                           ),
                 
                           //password textfield
                           Padding(
                             padding:
                                 const EdgeInsets.symmetric(horizontal: 20),
                             child: TextField(
                               cursorColor: Colors.white,
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
                                     color: Colors.purpleAccent,
                                     width: 0.8,
                                   ),
                                 ),
                                 labelText: " Password ",
                                 labelStyle: TextStyle(
                                     color: Theme.of(context)
                                         .colorScheme
                                         .secondary),
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
                             ),
                           ),
                           const SizedBox(
                             height: 20,
                           ),
                 
                           //password textfield
                           Padding(
                             padding:
                                 const EdgeInsets.symmetric(horizontal: 20),
                             child: TextField(
                               cursorColor: Colors.white,
                               controller: _confromPasswordController,
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
                                     color: Colors.purpleAccent,
                                     width: 0.8,
                                   ),
                                 ),
                                 labelText: " Confirm Password ",
                                 labelStyle: TextStyle(
                                     color: Theme.of(context)
                                         .colorScheme
                                         .secondary),
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
                             ),
                           ),
                 
                           //login Button
                         ],
                       ),
                     ),
                   ),
                 ),
              ],
            ),
            //year
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 50),
            //   child: TextField(
            //     cursorColor: Colors.white,
            //     controller: _confromPasswordController,
            //     obscureText: isObscure,
            //     decoration: InputDecoration(
            //       enabledBorder: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(12),
            //         borderSide: const BorderSide(
            //           color: Colors.grey,
            //           width: 0.8,
            //         ),
            //       ),
            //       focusedBorder: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(12),
            //         borderSide: const BorderSide(
            //           color: Colors.purpleAccent,
            //           width: 0.8,
            //         ),
            //       ),
            //       labelText: " Confirm Password ",
            //       labelStyle:
            //           TextStyle(color: Theme.of(context).colorScheme.secondary),
            //       suffixIcon: IconButton(
            //         onPressed: () {
            //           setState(() {
            //             isObscure = !isObscure;
            //           });
            //         },
            //         icon: Icon(
            //           isObscure
            //               ? Icons.lock
            //               : Icons.no_encryption_gmailerrorred_rounded,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            const SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: GestureDetector(
                onTap: signUp,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/ic_button.png',
                    ),
                    Text(
                      "Crea tu cuenta",
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
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
    );
  }
}
