// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/pages/home_page.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({super.key, required this.showLoginPage});

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
  final _phoneController = TextEditingController();
  String _selectedRole = 'player';
  final _businessNameController = TextEditingController();
  final _rfcController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _authService = AuthService();

  //check passoword same or not
  bool checkPassowrd() {
    if (_passwordController.text.trim() ==
        _confromPasswordController.text.trim()) {
      return true;
    } else {
      return false;
    }
  }

  Future signUp() async {
    if (!validateRegister()) return;
    try {
      showDialog(
          context: context,
          builder: (_) => Center(child: CircularProgressIndicator()));

      final success = await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        role: _selectedRole,
        businessName:
            _selectedRole == 'admin' ? _businessNameController.text : null,
        businessAddress:
            _selectedRole == 'admin' ? _businessAddressController.text : null,
      );

      Navigator.pop(context);
      if (success) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => AuthCheckMain()));
      }
    } catch (e) {
      Navigator.pop(context);
      showErrorSnackBar(e.toString());
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

  bool validateRegister() {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _confromPasswordController.text.isEmpty) {
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

    if (_passwordController.text != _confromPasswordController.text) {
      showErrorSnackBar("Las contraseñas no coinciden");
      return false;
    }

    return true;
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[200],
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
      appBar: AppBar(
        title: const Text("Registro"),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        backgroundColor: Colors.transparent,
        elevation: 10,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: widget.showLoginPage,
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextField(
                              cursorColor: Colors.white,
                              controller: _nameController,
                              decoration: InputDecoration(
                                prefixIcon:
                                    Icon(Icons.person, color: Colors.grey),
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
                                labelText: "Nombre",
                                labelStyle: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextField(
                              cursorColor: Colors.white,
                              controller: _phoneController,
                              decoration: InputDecoration(
                                prefixIcon:
                                    Icon(Icons.phone, color: Colors.grey),
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
                                labelText: " Telefono ",
                                labelStyle: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          //email textfield
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextField(
                              cursorColor: Colors.white,
                              controller: _emailController,
                              decoration: InputDecoration(
                                prefixIcon:
                                    Icon(Icons.email, color: Colors.grey),
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
                                labelText: " Email ",
                                labelStyle: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),

                          //password textfield
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextField(
                              cursorColor: Colors.white,
                              controller: _passwordController,
                              obscureText: isObscure,
                              decoration: InputDecoration(
                                prefixIcon:
                                    Icon(Icons.lock, color: Colors.grey),
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
                                labelText: " Password ",
                                labelStyle: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),

                          //password textfield
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                    color: Colors.black,
                                    width: 0.8,
                                  ),
                                ),
                                labelText: "Confirmar Contraseña",
                                labelStyle: TextStyle(color: Colors.black),
                                prefixIcon:
                                    Icon(Icons.lock, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: InputDecorator(
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
                                labelText: "Seleccionar rol",
                                labelStyle: TextStyle(color: Colors.black),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedRole,
                                isExpanded:
                                    true, // Para que ocupe todo el ancho
                                underline:
                                    const SizedBox(), // Ocultar la línea por defecto
                                items: [
                                  DropdownMenuItem(
                                    value: 'player',
                                    child: Text(
                                      'Jugador',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'admin',
                                    child: Text('Administrador'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),

                          if (_selectedRole == 'admin') ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: TextField(
                                cursorColor: Colors.white,
                                controller: _businessNameController,
                                obscureText: isObscure,
                                decoration: InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.business, color: Colors.grey),
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
                                  labelText: "Nombre de la cancha",
                                  labelStyle: TextStyle(color: Colors.black),
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
                                controller: _businessAddressController,
                                obscureText: isObscure,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.location_on,
                                      color: Colors.grey),
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
                                  labelText: "Ubicacion de la cancha",
                                  labelStyle: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                          ]

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
                onPressed: signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/google.png', height: 24),
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
