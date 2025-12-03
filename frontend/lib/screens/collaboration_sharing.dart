// screens/collaboration_sharing.dart
import 'package:flutter/material.dart';

class CollaborationSharingScreen extends StatelessWidget {
  const CollaborationSharingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaboration & Sharing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invite Collaborator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Email Address'),
            const SizedBox(height: 5),
            const TextField(
              decoration: InputDecoration(
                hintText: 'collaborator@example.com',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Access Level'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                FilterChip(
                  label: const Text('View Only'),
                  onSelected: (bool value) {},
                ),
                FilterChip(
                  label: const Text('Comment'),
                  onSelected: (bool value) {},
                ),
                FilterChip(
                  label: const Text('Edit'),
                  onSelected: (bool value) {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.send),
              label: const Text('Send Invite'),
            ),
            const Divider(height: 40),
            const Text(
              'Your Shared Workspaces',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSharedWorkspace('Project Alpha Proposal', 'You can edit', 'Active'),
            _buildSharedWorkspace('Q3 Financial Report', 'You can view', 'Archived'),
            _buildSharedWorkspace('User Research Findings', 'You can comment', 'Pending Review'),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedWorkspace(String title, String permission, String status) {
    Color statusColor = Colors.grey;
    if (status == 'Active') statusColor = Colors.green;
    if (status == 'Pending Review') statusColor = Colors.orange;

    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(permission),
        trailing: Chip(
          label: Text(
            status,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: statusColor,
        ),
      ),
    );
  }
}