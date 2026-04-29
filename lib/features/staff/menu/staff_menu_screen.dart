import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/menu_service.dart';
import '../../../models/menu_model.dart';
import 'staff_menu_detail_screen.dart';

class StaffMenuScreen extends StatefulWidget {
  const StaffMenuScreen({super.key});

  @override
  State<StaffMenuScreen> createState() => _StaffMenuScreenState();
}

class _StaffMenuScreenState extends State<StaffMenuScreen> {
  List<MenuItem> menuItems = [];
  bool isLoading = true;
  String errorMessage = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const Color teal = Color(0xFF008F99);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color tealDark = Color(0xFF00695C);

  final String logoUrl =
      "https://rulggijojszaxotcqkjd.supabase.co/storage/v1/object/public/app-assets/logo.png";

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MenuItem> get _filteredItems {
    if (_searchQuery.trim().isEmpty) return menuItems;
    final q = _searchQuery.toLowerCase();
    return menuItems.where((item) {
      return item.name.toLowerCase().contains(q) ||
          (item.category.name.toLowerCase().contains(q)) ||
          (item.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _toggleItemStatus(int indexInFiltered) async {
    final filteredItem = _filteredItems[indexInFiltered];
    final realIndex =
        menuItems.indexWhere((m) => m.id == filteredItem.id);
    if (realIndex == -1) return;

    final item = menuItems[realIndex];
    final newStatus =
        item.status == 'available' ? 'unavailable' : 'available';

    setState(() {
      menuItems[realIndex] = MenuItem(
        id: item.id,
        name: item.name,
        description: item.description,
        categoryId: item.categoryId,
        branchId: item.branchId,
        price: item.price,
        image: item.image,
        status: newStatus,
        deletedAt: item.deletedAt,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        averageRating: item.averageRating,
        totalRatings: item.totalRatings,
        category: item.category,
        branch: item.branch,
      );
    });

    final success =
        await MenuService.updateMenuItemStatus(item.id, newStatus);
    if (!mounted) return;

    if (!success) {
      setState(() {
        menuItems[realIndex] = item;
      });
      _showSnack('Failed to update item status', Colors.red);
    } else {
      _showSnack(
        'Status updated to $newStatus',
        newStatus == 'available' ? Colors.green : Colors.orange,
      );
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _fetchMenuItems() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null && user.branchId != null) {
        final items =
            await MenuService.fetchMenuItemsByBranch(user.branchId!);
        if (!mounted) return;
        setState(() {
          menuItems = items;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Unable to get branch information';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load menu items: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            /// ============================
            /// HEADER — overlapping logo style
            /// ============================
            Container(
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(left: 36),
                    padding: const EdgeInsets.only(
                        left: 52, right: 16, top: 14, bottom: 14),
                    decoration: const BoxDecoration(color: teal),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Menu Management',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Item count badge
                        if (!isLoading && errorMessage.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${menuItems.length} items',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
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
                            Icons.restaurant_menu,
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
            /// BODY
            /// ============================
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: teal, strokeWidth: 2.5))
                  : errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : menuItems.isEmpty
                          ? _buildEmptyState()
                          : Column(
                              children: [
                                /// SEARCH BAR
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 14, 16, 8),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search by name, category...',
                                      hintStyle: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 13),
                                      prefixIcon: const Icon(Icons.search,
                                          color: teal, size: 20),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() =>
                                                    _searchQuery = '');
                                              },
                                              icon: Icon(Icons.close,
                                                  color: Colors.grey.shade400,
                                                  size: 18),
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 0),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: teal.withOpacity(0.25)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: teal.withOpacity(0.25)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: teal, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ),

                                /// STATS ROW
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 10),
                                  child: Row(
                                    children: [
                                      _statChip(
                                        label: 'Available',
                                        count: menuItems
                                            .where((i) =>
                                                i.status == 'available')
                                            .length,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      _statChip(
                                        label: 'Unavailable',
                                        count: menuItems
                                            .where((i) =>
                                                i.status != 'available')
                                            .length,
                                        color: Colors.red,
                                      ),
                                      const Spacer(),
                                      if (_searchQuery.isNotEmpty)
                                        Text(
                                          '${_filteredItems.length} found',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                /// LIST
                                Expanded(
                                  child: RefreshIndicator(
                                    color: teal,
                                    onRefresh: _fetchMenuItems,
                                    child: _filteredItems.isEmpty
                                        ? ListView(
                                            children: [
                                              SizedBox(
                                                height: 200,
                                                child: Center(
                                                  child: Text(
                                                    'No items match "$_searchQuery"',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .grey.shade500,
                                                        fontSize: 14),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : ListView.builder(
                                            padding:
                                                const EdgeInsets.fromLTRB(
                                                    16, 0, 16, 20),
                                            itemCount:
                                                _filteredItems.length,
                                            itemBuilder: (context, index) {
                                              return _buildMenuCard(
                                                  index);
                                            },
                                          ),
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

  Widget _buildMenuCard(int index) {
    final item = _filteredItems[index];
    final isAvailable = item.status == 'available';
    final price = (double.tryParse(item.price.toString()) ?? 0)
        .toStringAsFixed(2);
    final rating = (double.tryParse(item.averageRating.toString()) ?? 0)
        .toStringAsFixed(1);

    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => StaffMenuDetailScreen(item: item),
          ),
        );
        if (updated == true && mounted) _fetchMenuItems();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: teal.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT — image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                  child: item.image != null && item.image!.isNotEmpty
                      ? Image.network(
                          item.image!,
                          width: 110,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imageHolder(110, 120),
                        )
                      : _imageHolder(110, 120),
                ),
                // Available / unavailable dot
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isAvailable ? Colors.green : Colors.red,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),

            /// RIGHT — content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Name + price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.red.withOpacity(0.25)),
                          ),
                          child: Text(
                            '\$$price',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tealLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category.name,
                        style: const TextStyle(
                          fontSize: 11,
                          color: tealDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    // Description
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),

                    // Bottom row — rating + status toggle + edit
                    Row(
                      children: [
                        // Rating badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.amber.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                '$rating (${item.totalRatings})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7A5C00),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Status toggle
                        GestureDetector(
                          onTap: () => _toggleItemStatus(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isAvailable
                                    ? Colors.green.withOpacity(0.35)
                                    : Colors.red.withOpacity(0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isAvailable
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isAvailable
                                      ? 'Available'
                                      : 'Off',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.swap_horiz,
                                  size: 13,
                                  color: isAvailable
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Edit button
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: tealLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: tealDark,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(
      {required String label,
      required int count,
      required Color color}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageHolder(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: tealLight,
      child:
          const Icon(Icons.fastfood, size: 36, color: teal),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchMenuItems,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tealLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_menu,
                  size: 48, color: teal),
            ),
            const SizedBox(height: 16),
            const Text(
              'No menu items yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Items assigned to your branch will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}