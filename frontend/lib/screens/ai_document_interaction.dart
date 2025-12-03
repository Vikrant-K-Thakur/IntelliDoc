// screens/ai_document_interaction.dart
import 'package:flutter/material.dart';

class AIDocumentInteractionScreen extends StatelessWidget {
  const AIDocumentInteractionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Document Interaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Original Document',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'The Industrial Revolution, beginning in the late 18th century, was a period of profound technological innovation and economic transformation. It saw the shift from agrarian and handicraft economies to ones dominated by industry and machine manufacturing. Key developments included the invention of the steam engine, which revolutionized transportation and revolutionary production.',
            ),
            const Divider(height: 40),
            const Text(
              'AI Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Full Summary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'The Industrial Revolution, starting in the late 18th century, transformed economies from agriculture to machine manufacturing. Key innovations included the steam engine and the factory system, leading to rapid urbanization. While fostering economic growth, it also resulted in poor working and living conditions. Originating in Great Britain, its global spread reshaped societies, politics, and the world economy, setting the foundation for modern industrial society through advancements in textiles, metallurgy, mining, and new energy sources like coal.',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Export Summary'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Download Summary'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('Made with 💸'),
            ),
          ],
        ),
      ),
    );
  }
}