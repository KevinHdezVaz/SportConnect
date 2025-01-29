// import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/login_page.dart';
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
  final _codigPostalController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confromPasswordController = TextEditingController();
  final _yearController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _authService = AuthService();
  File? _profileImage;
  final _imagePicker = ImagePicker();
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

      final emailExists =
          await _authService.checkEmailExists(_emailController.text);
      if (emailExists) {
        Navigator.pop(context);
        showErrorSnackBar(
            "Este correo electrónico ya está registrado, agrega otro.");
        _emailController.clear();
        return;
      }
      final phoneExists =
          await _authService.checkPhoneExists(_phoneController.text);
      if (phoneExists) {
        Navigator.pop(context);
        showErrorSnackBar("Este teléfono ya está registrado, agrega otro.");
        _phoneController.clear();
        return;
      }

      final success = await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        codigpostal: _codigPostalController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        profileImage: _profileImage,
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
    _codigPostalController.dispose();

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
    if (_nameController.text.contains(RegExp(r'[^a-zA-Z\s]'))) {
      showErrorSnackBar("El nombre solo debe contener letras");
      return false;
    }

    if (_profileImage == null) {
      showErrorSnackBar("Por favor, sube una foto de perfil");
      return false;
    }

    if (_codigPostalController.text.length != 5) {
      showErrorSnackBar("El código postal debe tener 5 dígitos");
      return false;
    }

    if (_phoneController.text.length != 10) {
      showErrorSnackBar("El número de teléfono debe tener 10 dígitos");
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
        backgroundColor: const Color.fromARGB(255, 207, 80, 80),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
       onWillPop: () async {
        // Lógica para manejar el botón de retroceso
 Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginPage(showLoginPage: () {  },)),
  );        return false;  
      },
      child: Scaffold(
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
                      height: 600,
                      width: 350,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 15,
                            ),
                            Text(
                              "Bienvenido, Completa tu registro.",
                              style: GoogleFonts.lato(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 42, 179, 33),
                              ),
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.photo_camera,
                                          color: Colors.grey),
                                      SizedBox(width: 8),
                                      Text("Foto de perfil"),
                                      Spacer(),
                                      if (_profileImage != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            _profileImage!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            customTextField(
                              labelText: "Nombre completo",
                              prefixIcon: Icon(Icons.person, color: Colors.grey),
                              controller: _nameController,
                              isObscure:
                                  false,  
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            customTextField(
                              labelText: "Teléfono",
                              prefixIcon: Icon(Icons.phone, color: Colors.grey),
                              controller: _phoneController,
                              isObscure:
                                  false, 
                              keyboardType: TextInputType
                                  .phone,  
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly,  
                                LengthLimitingTextInputFormatter(
                                    10),  
                              ],
                            ),
      
                            const SizedBox(
                              height: 20,
                            ),
                            //email textfield
                            customTextField(
                              labelText: "Correo electrónico",
                              prefixIcon: Icon(Icons.email, color: Colors.grey),
                              controller: _emailController,
                              isObscure:
                                  false, 
                            ),
      
                            const SizedBox(
                              height: 20,
                            ),
      
                            customTextField(
                              labelText: "Código Postal (C.P)",
                              prefixIcon:
                                  Icon(Icons.add_location, color: Colors.grey),
                              controller: _codigPostalController,
                              isObscure: false,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly, // Solo números
                                LengthLimitingTextInputFormatter(
                                    5), // Limitar a 5 dígitos para código postal
                              ],
                            ),
      
                            const SizedBox(
                              height: 20,
                            ),
      
                            //password textfield
                            customTextField(
                              labelText: "Contraseña",
                              prefixIcon: Icon(Icons.lock, color: Colors.grey),
                              controller: _passwordController,
                              isObscure: isObscure,
                            ),
      
                            const SizedBox(
                              height: 20,
                            ),
      
                            //password textfield
                            customTextField(
                              labelText: "Confirmar Contraseña",
                              prefixIcon: Icon(Icons.lock, color: Colors.grey),
                              controller: _confromPasswordController,
                              isObscure: isObscure,
                            ),
                            const SizedBox(
                              height: 20,
                            ),
      
                            //login Button
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  customTextField({
    required String labelText,
    required Icon prefixIcon,
    required TextEditingController controller,
    bool isObscure = false, // Por defecto lo configuramos como 'false'
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        cursorColor: Colors.white,
        controller: controller,
        obscureText:
            isObscure, // Aquí se maneja si el texto debe estar oculto o no
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
         style: const TextStyle(
      color: Colors.black,  
    ),
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
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.black),
          prefixIcon: prefixIcon,
        ),
      ),
    );
  }
}
