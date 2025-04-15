import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        title: const Text('About BlazeSense'),
        backgroundColor: const Color(0xFFB5062D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // ADDED: Makes it scrollable
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Image.asset(
                'assets/about_logo.png',
                height: 270,
                width: 270,
              ),
            ),

            const Text(
              'BlazeSense is an intelligent fire monitoring system designed to detect fires early and protect lives and the environment.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 40, thickness: 1.2),
            _buildFeature(Icons.videocam, 'Live Camera Monitoring', 'Receives real-time footage from IP cameras.'),
            _buildFeature(Icons.visibility, 'AI Fire Detection', 'Uses the YOLOv8 model to instantly analyze whether there is a fire.'),
            _buildFeature(Icons.cloud_upload, 'Data Logging', 'Automatically sends data and logs events to the database.'),
            _buildFeature(Icons.phone_android, 'Mobile Interface', 'Provides a user-friendly mobile application developed with Flutter.'),
            const SizedBox(height: 30),
            const Text(
              '© 2025 BlazeSense Team ',
              style: TextStyle(color: Colors.grey),
            ),

            const Text(
              '(Fettah Elçik, Emre Karaçal, Cemresu Uzun, Mustafaca Daşdemir, Ahmet Utku Nadirler)',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFB5062D)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
