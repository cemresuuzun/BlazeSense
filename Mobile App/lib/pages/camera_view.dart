// import 'package:flutter/material.dart';
//
// class IPCameraView extends StatelessWidget {
//   const IPCameraView({super.key});
//
//   final String mjpegUrl = 'http://192.168.1.101:8081/video_feed';
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Main MJPEG stream
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Container(
//             height: MediaQuery.of(context).size.height * 0.45,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: Colors.black,
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   spreadRadius: 2,
//                   blurRadius: 5,
//                   offset: const Offset(0, 3),
//                 ),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: Image.network(
//                 mjpegUrl,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => const Center(
//                   child: Text(
//                     "❌ Cannot load stream",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//                 loadingBuilder: (context, child, loadingProgress) {
//                   if (loadingProgress == null) return child;
//                   return const Center(child: CircularProgressIndicator());
//                 },
//               ),
//             ),
//           ),
//         ),
//
//         // Optional message or placeholder
//         Padding(
//           padding: const EdgeInsets.only(top: 10.0),
//           child: Text(
//             "Live FireCam Feed",
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[800],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }


