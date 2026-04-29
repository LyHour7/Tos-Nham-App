import 'package:flutter/material.dart';
import '../../../core/services/branch_service.dart';
import 'branch_detail_screen.dart';
import '../../../l10n/app_localizations.dart';

class AllBranchScreen extends StatefulWidget {
  const AllBranchScreen({super.key});

  @override
  State<AllBranchScreen> createState() => _AllBranchScreenState();
}

class _AllBranchScreenState extends State<AllBranchScreen> {
  List branches = [];
  bool isLoading = true;

  static const Color teal = Color(0xFF008F99);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color tealDark = Color(0xFF00695C);

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  @override
  void initState() {
    super.initState();
    loadBranches();
  }

  Future<void> loadBranches() async {
    try {
      final data = await BranchService.fetchBranches();

      if (!mounted) return;

      setState(() {
        branches = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Branch load error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: teal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [

          /// ============================
          /// HEADER — overlapping logo style
          /// ============================
          Container(
            color: Colors.transparent,
            margin: const EdgeInsets.only(top: 48),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // Teal bar
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 36),
                  padding: const EdgeInsets.only(
                    left: 52, right: 16, top: 14, bottom: 14,
                  ),
                  decoration: const BoxDecoration(color: Color(0xFF008F99)),
                  child: Text(
                    lang.allBranch,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                // Logo circle overlapping the bar
                Positioned(
                  left: 0,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: teal, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.store,
                          color: teal,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ============================
          /// BRANCH LIST
          /// ============================
          Expanded(
            child: RefreshIndicator(
              color: teal,
              onRefresh: loadBranches,
              child: branches.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: 300,
                          child: Center(
                            child: Text(
                              "No branches found",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      itemCount: branches.length,
                      itemBuilder: (context, index) {
                        final branch = branches[index];
                        final bool isOpen =
                            branch['status'].toString().toLowerCase() == "open";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: teal.withOpacity(0.22),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [

                                /// BRANCH IMAGE
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: teal.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    color: tealLight,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: Image.network(
                                      logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.store,
                                              color: teal, size: 36),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                /// BRANCH INFO
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [

                                      // Branch name pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: tealLight,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          branch['branch_name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: tealDark,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Status badge
                                      Row(
                                        children: [
                                          Text(
                                            "${lang.status}: ",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isOpen
                                                  ? Colors.green
                                                      .withOpacity(0.1)
                                                  : Colors.red
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isOpen
                                                    ? Colors.green
                                                        .withOpacity(0.4)
                                                    : Colors.red
                                                        .withOpacity(0.4),
                                              ),
                                            ),
                                            child: Text(
                                              branch['status'],
                                              style: TextStyle(
                                                color: isOpen
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 5),

                                      // Location row
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined,
                                              size: 13,
                                              color: Colors.grey.shade500),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              branch['address'] ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                /// VIEW BUTTON
                                SizedBox(
                                  width: 68,
                                  height: 34,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: teal,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
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
                                    child: Text(
                                      lang.view,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}