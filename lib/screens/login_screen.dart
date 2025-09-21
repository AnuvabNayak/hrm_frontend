import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
// import '../widgets/bottom_nav_bar.dart';

class LoginScreen extends StatefulWidget {
  final String? role;
  const LoginScreen({Key? key, this.role}) : super(key: key);

  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    final error = await AuthService.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text
    );
    setState(() => _isLoading = false);
    if (error == null) {
      context.go('/home');
    } else {
      setState(() => _errorMsg = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role ?? "employee";
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("LOGIN - ${role[0].toUpperCase()}${role.substring(1)}", style: GoogleFonts.nunito()),
        centerTitle: true, elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', width: 90, height: 90),
              const SizedBox(height: 12),
              Text("LOGIN", style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold, fontSize: 24, color: Colors.blue[800])),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: GoogleFonts.nunito(),
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: GoogleFonts.nunito(),
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                    ),
                    AnimatedOpacity(
                      opacity: _errorMsg != null ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 250),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 11),
                        child: Text(_errorMsg ?? "", style: TextStyle(color: Colors.red[700])),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: Colors.blueAccent
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: _isLoading
                          ? SizedBox(key: ValueKey('loading'), width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.3))
                          : Text('Login', key: ValueKey('btn'), style: GoogleFonts.nunito(fontSize: 18, color: Colors.white)),
                      ),
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
}



// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../services/auth_service.dart';

// class LoginScreen extends StatefulWidget {
//   final String? role;
//   const LoginScreen({Key? key, this.role}) : super(key: key);

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();

//   bool _isLoading = false;
//   String? _errorMsg;

//   void _login() async {
//   setState(() {
//     _isLoading = true;
//     _errorMsg = null;
//   });

//   final username = _usernameController.text.trim();
//   final password = _passwordController.text;

//   final error = await AuthService.login(username: username, password: password);
//   setState(() => _isLoading = false);

//   if (error == null) {
//     context.go('/home'); // Replace with your actual home route or dashboard
//   } else {
//     setState(() => _errorMsg = error);
//   }
// }


//   @override
//   Widget build(BuildContext context) {
//     final role = widget.role ?? 'employee';
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Login - ${role[0].toUpperCase()}${role.substring(1)}'),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           onPressed: () => context.go('/'),
//         ),
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 Image.asset('assets/logo.png', width: 80),
//                 SizedBox(height: 32),
//                 TextFormField(
//                   controller: _usernameController,
//                   decoration: InputDecoration(
//                     labelText: 'Username',
//                     errorText: _errorMsg != null ? '' : null,
//                   ),
//                   validator: (value) =>
//                       value == null || value.isEmpty ? 'Enter Username' : null,
//                 ),
//                 SizedBox(height: 16),
//                 TextFormField(
//                   controller: _passwordController,
//                   decoration: InputDecoration(
//                     labelText: 'Password',
//                     errorText: _errorMsg != null ? '' : null,
//                   ),
//                   obscureText: true,
//                   validator: (value) =>
//                       value == null || value.isEmpty ? 'Enter Password' : null,
//                 ),
//                 if (_errorMsg != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 12),
//                     child: Text(_errorMsg!, style: TextStyle(color: Colors.red)),
//                   ),
//                 SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading
//                         ? null
//                         : () {
//                             if (_formKey.currentState!.validate()) {
//                               _login();
//                             }
//                           },
//                     child: _isLoading
//                         ? CircularProgressIndicator(color: Colors.white)
//                         : Text('Login'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
