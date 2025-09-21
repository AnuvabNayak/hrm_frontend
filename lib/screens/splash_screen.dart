import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // or Navigator
import 'package:google_fonts/google_fonts.dart';
// import '../widgets/bottom_nav_bar.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/background_user_selection.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                Text(
                  'ZYTEXA',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.blue[800],
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                _SplashButton(label: 'Admin', onTap: () => context.go('/login?role=admin')),
                const SizedBox(height: 16),
                _SplashButton(label: 'Employee', onTap: () => context.go('/login?role=employee')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _SplashButton({required this.label, required this.onTap});
  @override
  State<_SplashButton> createState() => _SplashButtonState();
}
class _SplashButtonState extends State<_SplashButton> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: Duration(milliseconds: 100),
        child: Container(
          width: 220,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.09),
                blurRadius: 10,
                offset: Offset(0, 3),
              )
            ]
          ),
          child: Text(widget.label, style: GoogleFonts.nunito(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_fonts/google_fonts.dart';
// // If you have SVGs/background watermark:
// import 'package:flutter_svg/flutter_svg.dart';

// class SplashScreen extends StatelessWidget {
//   const SplashScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: 
//       Stack(
//         children: [
//           Positioned.fill(
//             child: Opacity(
//               opacity: 0.07,
//               child: Image.asset('assets\background_user_selection.png', fit: BoxFit.cover),
//               ),
//               ),
//       Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // TODO: Replace with your asset image for the logo
//             Image.asset(
//               'assets/logo.png',
//               width: 100,
//               height: 100,
//               fit: BoxFit.contain,
//             ),
//             const SizedBox(height: 40),
//             Text(
//               'ZYTEXA',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 32,
//                 color: Colors.blue[800],
//                 letterSpacing: 2,
//               ),
//             ),
//             const SizedBox(height: 24),
            
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 minimumSize: Size(200, 50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () => context.go('/login?role=admin'),
//               child: Text('Admin',
//                 style: TextStyle(fontSize: 18),
//               ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 minimumSize: Size(200, 50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () => context.go('/login?role=employee'),
//               child: Text('Employee',
//                 style: TextStyle(fontSize: 18),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
