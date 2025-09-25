import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyDetailsScreen extends StatelessWidget {
  const CompanyDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Company Details",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Company Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/logo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Z',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Company Name
            Text(
              "Zytexa",
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 32),

            // Company Info
            _InfoTile(
              icon: Icons.location_on,
              iconColor: Colors.blue,
              title: "Head Office",
              subtitle: "Jaipur, Rajasthan",
            ),
            _InfoTile(
              icon: Icons.business,
              iconColor: Colors.blue,
              title: "Industry",
              subtitle: "IT Services and IT Consulting",
            ),
            _InfoTile(
              icon: Icons.calendar_today,
              iconColor: Colors.blue,
              title: "Founded",
              subtitle: "2025",
            ),
            _InfoTile(
              icon: Icons.people,
              iconColor: Colors.blue,
              title: "Employees",
              subtitle: "11-50 Employees",
            ),
            _InfoTile(
              icon: Icons.email,
              iconColor: Colors.blue,
              title: "Email",
              subtitle: "zytexatechnology@gmail.com",
              isLink: true,
              onTap: () => _launchEmail("zytexatechnology@gmail.com"),
            ),

            const SizedBox(height: 32),

            // About Company
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "About Company",
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AboutSection(
                    title: "Mission",
                    content:
                        "At Zytexa Technology, our mission is to deliver outstanding results for businesses across various sectors, helping them grow and thrive through personalized digital strategies. We work relentlessly to provide innovative, result-oriented solutions, ensuring our clients achieve their desired outcomes seamlessly.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLink;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isLink ? Colors.blue : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String title;
  final String content;

  const _AboutSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:go_router/go_router.dart';
// import 'package:url_launcher/url_launcher.dart';

// class CompanyDetailsScreen extends StatelessWidget {
//   const CompanyDetailsScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text(
//           "Company Details",
//           style: GoogleFonts.nunito(
//             fontWeight: FontWeight.bold,
//             fontSize: 22,
//             color: Colors.black,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => context.go('/menu'),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // Company Logo
//             // Company Logo - UPDATED VERSION
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.2),
//                     spreadRadius: 2,
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: Image.asset(
//                   'assets/logo.png',
//                   width: 80,
//                   height: 80,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     // Fallback to letter if logo fails to load
//                     return Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         color: Colors.blue.shade600,
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: const Center(
//                         child: Text(
//                           'Z',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 36,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),
            
//             // Company Name
//             Text(
//               "Zytexa",
//               style: GoogleFonts.nunito(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             const SizedBox(height: 32),
            
//             // Company Info
//             _InfoTile(
//               icon: Icons.location_on,
//               iconColor: Colors.blue,
//               title: "Head Office",
//               subtitle: "Mumbai, Maharashtra, India",
//             ),
//             _InfoTile(
//               icon: Icons.business,
//               iconColor: Colors.blue,
//               title: "Industry",
//               subtitle: "IT Services & Solutions",
//             ),
//             _InfoTile(
//               icon: Icons.calendar_today,
//               iconColor: Colors.blue,
//               title: "Founded",
//               subtitle: "January 2024",
//             ),
//             _InfoTile(
//               icon: Icons.people,
//               iconColor: Colors.blue,
//               title: "Employees",
//               subtitle: "50+ Professionals",
//             ),
//             _InfoTile(
//               icon: Icons.email,
//               iconColor: Colors.blue,
//               title: "Support Email",
//               subtitle: "hr@zytexa.com",
//               isLink: true,
//               onTap: () => _launchEmail("hr@zytexa.com"),
//             ),
//             _InfoTile(
//               icon: Icons.language,
//               iconColor: Colors.blue,
//               title: "Website",
//               subtitle: "www.zytexa.com",
//               isLink: true,
//               onTap: () => _launchUrl("https://www.zytexa.com"),
//             ),
            
//             const SizedBox(height: 32),
            
//             // About Company
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade50,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "About Company",
//                     style: GoogleFonts.nunito(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _AboutSection(
//                     title: "Mission",
//                     content: "Empowering businesses through innovative technology solutions and exceptional service delivery.",
//                   ),
//                   const SizedBox(height: 16),
//                   _AboutSection(
//                     title: "Culture",
//                     content: "\"Innovation, Integrity, Excellence\" - Building tomorrow's technology today.",
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _launchEmail(String email) async {
//     final Uri emailUri = Uri(
//       scheme: 'mailto',
//       path: email,
//     );
//     if (await canLaunchUrl(emailUri)) {
//       await launchUrl(emailUri);
//     }
//   }

//   Future<void> _launchUrl(String url) async {
//     final Uri uri = Uri.parse(url);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     }
//   }
// }

// class _InfoTile extends StatelessWidget {
//   final IconData icon;
//   final Color iconColor;
//   final String title;
//   final String subtitle;
//   final bool isLink;
//   final VoidCallback? onTap;

//   const _InfoTile({
//     required this.icon,
//     required this.iconColor,
//     required this.title,
//     required this.subtitle,
//     this.isLink = false,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(8),
//         child: Row(
//           children: [
//             Icon(icon, color: iconColor, size: 24),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: GoogleFonts.nunito(
//                       fontSize: 14,
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     subtitle,
//                     style: GoogleFonts.nunito(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: isLink ? Colors.blue : Colors.black,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _AboutSection extends StatelessWidget {
//   final String title;
//   final String content;

//   const _AboutSection({
//     required this.title,
//     required this.content,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: GoogleFonts.nunito(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           content,
//           style: GoogleFonts.nunito(
//             fontSize: 14,
//             color: Colors.grey.shade700,
//             height: 1.4,
//           ),
//         ),
//       ],
//     );
//   }
// }
