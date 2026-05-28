import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/services/home_service.dart';
import '../../../core/utils/auth_guard.dart';
import '../branch/branch_detail_screen.dart';
import '../menu/menu_detail_screen.dart';
import '../../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List branches = [];
  List menuItems = [];
  bool isLoading = true;
  int _currentBannerPage = 0;
  final PageController _bannerController = PageController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  static const Color teal = Color(0xFF009688);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color tealDark = Color(0xFF00695C);
  static const Color readableText = Color(0xFF111111);
  static const List<String> khmerFontFallback = [
    'Noto Sans Khmer',
    'Khmer OS Battambang',
    'Roboto',
  ];

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  final List<String> banners = [
    "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/banner1.jpg",
    "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/banner2.jpg",
    "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/banner3.jpg",
    "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/banner4.jpg",
    "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/banner5.jpg",
    "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/banner6.jpg",
    "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/banner7.jpg",
  ];

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadHomeData() async {
    try {
      final branchData = await HomeService.fetchBranches();
      final menuData = await HomeService.fetchMenuItems();
      menuData.shuffle(Random());

      if (!mounted) return;

      setState(() {
        branches = branchData ?? [];
        menuItems = menuData.take(5).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Home Load Error: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String buildImageUrl(String? image) {
    if (image == null || image.isEmpty) return "";
    if (image.startsWith("http")) return image;
    // Use machine IP from config for real devices
    final baseUrl = "${ApiConfig.baseUrl.replaceAll('/api', '')}";
    return "$baseUrl$image";
  }

  List get filteredMenuItems {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return menuItems;
    return menuItems.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final branch =
          (item['branch']?['branch_name'] ?? '').toString().toLowerCase();
      return name.contains(query) || branch.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: teal),
      );
    }

    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          /// ===============================
          /// HEADER — overlapping logo (STICKY)
          /// ===============================
          Container(
            color: Colors.transparent,
            margin: const EdgeInsets.only(top: 48),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 36),
                  padding: const EdgeInsets.only(
                      left: 52, right: 16, top: 14, bottom: 14),
                  decoration: const BoxDecoration(color: Color(0xFF008F99)),
                  child: Text(
                    lang.welcome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
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
                          Icons.restaurant,
                          color: teal,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// ===============================
          /// SCROLLABLE CONTENT
          /// ===============================
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ===============================
                  /// BANNER — full width, no side padding
                  /// ===============================
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      SizedBox(
                        height: 165,
                        child: PageView.builder(
                          controller: _bannerController,
                          itemCount: banners.length,
                          onPageChanged: (index) {
                            setState(() => _currentBannerPage = index);
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              banners[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: teal.withOpacity(0.15),
                                child: const Icon(Icons.image,
                                    size: 48, color: teal),
                              ),
                            );
                          },
                        ),
                      ),
                      // Dot indicators
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(banners.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: _currentBannerPage == index ? 18 : 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: _currentBannerPage == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),

                        /// ===============================
                        /// SEARCH BAR
                        /// ===============================
                        TextField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: "Search food or branch...",
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13),
                            prefixIcon:
                                const Icon(Icons.search, color: teal, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = "");
                                    },
                                    icon: Icon(Icons.close,
                                        color: Colors.grey.shade400, size: 18),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: teal.withOpacity(0.25)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: teal.withOpacity(0.25)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: teal, width: 1.5),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// ===============================
                        /// ALL BRANCH LABEL
                        /// ===============================
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: tealLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: teal.withOpacity(0.3)),
                          ),
                          child: Text(
                            lang.allBranch,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tealDark,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// ===============================
                        /// BRANCH LIST
                        /// ===============================
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: branches.length,
                            itemBuilder: (context, index) {
                              final branch = branches[index];

                              return GestureDetector(
                                onTap: () {
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
                                child: Container(
                                  width: 82,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border:
                                              Border.all(color: teal, width: 2),
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.network(
                                            logoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.store,
                                                    color: teal),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        branch['branch_name'],
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 18),

                        /// ===============================
                        /// POPULAR FOOD HEADER
                        /// ===============================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: tealLight,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: teal.withOpacity(0.3)),
                              ),
                              child: Text(
                                lang.popularFood,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: tealDark,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: teal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Text(
                                lang.viewAll,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// ===============================
                        /// FOOD LIST
                        /// ===============================
                        if (filteredMenuItems.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: teal.withOpacity(0.2)),
                            ),
                            child: Text(
                              "No food found for '$_searchQuery'",
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                          )
                        else
                          ...filteredMenuItems.map((item) {
                            final imageUrl = buildImageUrl(item['image']);
                            final isAvailable =
                                item['status']?.toString().toLowerCase() ==
                                    'available';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: teal.withOpacity(0.22)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    /// FOOD IMAGE
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              width: 95,
                                              height: 95,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _imageFallback(),
                                            )
                                          : _imageFallback(),
                                    ),

                                    const SizedBox(width: 12),

                                    /// FOOD DETAILS
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Name pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: tealLight,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: readableText,
                                                fontFamilyFallback:
                                                    khmerFontFallback,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          const SizedBox(height: 6),

                                          Text(
                                            "${lang.price}: ${item['price']}\$",
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),

                                          const SizedBox(height: 3),

                                          Text(
                                            "status: ${isAvailable ? 'Available' : (item['status'] ?? '')}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isAvailable
                                                  ? Colors.grey.shade600
                                                  : Colors.red,
                                            ),
                                          ),

                                          const SizedBox(height: 2),

                                          Text(
                                            "${lang.location}: ${item['branch']['branch_name']}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    /// ACTION BUTTONS
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            final allowed =
                                                await ensureLoggedIn(context);
                                            if (!allowed) return;

                                            await HomeService.addToCart(
                                                item['id']);
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(lang.addedToCart),
                                                backgroundColor: Colors.green,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                            );
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(
                                              Icons.shopping_cart_outlined,
                                              color: Color(0xFF008F99),
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        SizedBox(
                                          width: 72,
                                          height: 32,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Color(0xFF008F99),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      MenuDetailScreen(
                                                          item: item),
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
                                  ],
                                ),
                              ),
                            );
                          }).toList(),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 95,
      height: 95,
      color: Colors.grey.shade200,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 36),
    );
  }
}
