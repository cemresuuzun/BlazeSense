import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('About BlazeSense'),
        backgroundColor: const Color(0xFF282828),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🌈 Gradient Banner with logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF282828), Color(0xFFFF0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Image.asset(
                  'assets/about_logo.png',
                  height: 350,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 💡 Modern Feature Cards with Glassmorphism
            _buildFeatureCard(
              icon: Icons.videocam_rounded,
              title: 'Live Camera Monitoring',
              description: 'Receives real-time footage from IP cameras.',
            ),
            _buildFeatureCard(
              icon: Icons.visibility_rounded,
              title: 'AI Fire Detection',
              description: 'Uses YOLOv8 model to instantly detect fire.',
            ),
            _buildFeatureCard(
              icon: Icons.cloud_upload_rounded,
              title: 'Data Logging',
              description: 'Automatically logs events to the database.',
            ),
            _buildFeatureCard(
              icon: Icons.phone_android_rounded,
              title: 'Mobile Interface',
              description: 'User-friendly mobile app powered by Flutter.',
            ),

            const SizedBox(height: 40),
            const Text(
              '© 2025 BlazeSense Team',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              '(Fettah Elçik, Emre Karaçal, Cemresu Uzun, Mustafaca Daşdemir, Ahmet Utku Nadirler)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🧩 Modern Feature Card with Glassmorphism Style
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.8), // Glass effect
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF5F5F5),
                child: Icon(icon, color: const Color(0xFF282828), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF555555),
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
