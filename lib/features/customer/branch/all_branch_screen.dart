import 'package:flutter/material.dart';
import '../../../core/services/branch_service.dart';
import '../branch/branch_detail_screen.dart';
class AllBranchScreen extends StatefulWidget {
  const AllBranchScreen({super.key});

  @override
  State<AllBranchScreen> createState() => _AllBranchScreenState();
}

class _AllBranchScreenState extends State<AllBranchScreen> {
  List branches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBranches();
  }

  Future<void> loadBranches() async {
    try {
      final data = await BranchService.fetchBranches();
      setState(() {
        branches = data;
        isLoading = false;
      });
    } catch (e) {
      print("Branch Load Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Branch"),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: branches.length,
        itemBuilder: (context, index) {
          final branch = branches[index];
          final isOpen = branch['status'] == "active";

          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  /// Logo Placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade200,
                    ),
                    child: const Icon(Icons.store, size: 40),
                  ),

                  const SizedBox(width: 15),

                  /// Branch Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch['branch_name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Text("Status: "),
                            Text(
                              isOpen ? "Open" : "Close",
                              style: TextStyle(
                                color: isOpen ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Location: ${branch['address'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  /// View Button
                 ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.teal,
  ),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BranchDetailScreen(
          branchId: branch['id'],
          branchName: branch['branch_name'],
        ),
      ),
    );
  },
  child: const Text("View"),
),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}