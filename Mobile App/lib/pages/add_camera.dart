import 'package:flutter/material.dart';

class AddCameraPage extends StatelessWidget {
  const AddCameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Camera'),
        backgroundColor: const Color(0xFF282828),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Camera setup form goes here!',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
