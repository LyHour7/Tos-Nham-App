class MenuItem {
  final int id;
  final String name;
  final String? description;
  final int categoryId;
  final int branchId;
  final String price;
  final String? image;
  final String status;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final String averageRating;
  final String totalRatings;
  final Category category;
  final Branch branch;

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.branchId,
    required this.price,
    this.image,
    required this.status,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.averageRating,
    required this.totalRatings,
    required this.category,
    required this.branch,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      categoryId: json['category_id'],
      branchId: json['branch_id'],
      price: json['price'],
      image: json['image'],
      status: json['status'],
      deletedAt: json['deleted_at'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      averageRating: json['average_rating'],
      totalRatings: json['total_ratings'],
      category: Category.fromJson(json['category']),
      branch: Branch.fromJson(json['branch']),
    );
  }
}

class Category {
  final int id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Branch {
  final int id;
  final String branchName;

  Branch({
    required this.id,
    required this.branchName,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      branchName: json['branch_name'],
    );
  }
}