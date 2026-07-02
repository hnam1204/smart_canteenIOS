import 'dart:async';

import 'package:firebase_core/firebase_core.dart';


import '../../models/firestore_models.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/food_repository.dart';
import 'widgets/category_filter_bar.dart';

import '../../core/utils/safe_change_notifier.dart';

enum FoodState { loading, loaded, error, empty }

enum CategoryState { loading, loaded, error, empty }

class MenuProvider extends SafeChangeNotifier {
  MenuProvider({
    FoodRepository? foodRepository,
    CategoryRepository? categoryRepository,
  }) : _foodRepository = foodRepository,
       _categoryRepository = categoryRepository;

  FoodRepository? _foodRepository;
  CategoryRepository? _categoryRepository;

  FoodState _foodState = FoodState.loading;
  CategoryState _categoryState = CategoryState.loading;
  List<FoodModel> _foods = const [];
  List<CategoryFilterItem> _categories = const [CategoryFilterItem.all];
  String _selectedCategoryId = CategoryFilterItem.allId;
  String _searchKeyword = '';
  String _errorMessage = '';
  Timer? _searchDebounce;

  FoodState get foodState => _foodState;
  CategoryState get categoryState => _categoryState;
  List<FoodModel> get foods => List<FoodModel>.unmodifiable(_foods);
  List<CategoryFilterItem> get categories =>
      List<CategoryFilterItem>.unmodifiable(_categories);
  String get selectedCategoryId => _selectedCategoryId;
  String get errorMessage => _errorMessage;

  List<FoodModel> get visibleFoods {
    final keyword = _searchKeyword.trim().toLowerCase();
    return _foods
        .where((food) {
          final matchCategory =
              _selectedCategoryId == CategoryFilterItem.allId ||
              food.categoryId == _selectedCategoryId;
          if (!matchCategory) return false;
          if (keyword.isEmpty) return true;
          return food.name.toLowerCase().contains(keyword) ||
              food.description.toLowerCase().contains(keyword) ||
              food.categoryName.toLowerCase().contains(keyword);
        })
        .toList(growable: false);
  }

  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      _foodState = FoodState.empty;
      _categoryState = CategoryState.loaded;
      notifyListeners();
      return;
    }
    _foodRepository ??= FoodRepository();
    _categoryRepository ??= CategoryRepository();
    _hydrateFromCache();
    notifyListeners();

    await Future.wait<void>([refreshCategories(), refreshFoods()]);
  }

  void _hydrateFromCache() {
    final cachedCategories =
        _categoryRepository?.getCachedCategories() ?? const <CategoryModel>[];
    if (cachedCategories.isNotEmpty) {
      _categories = categoryFilterItems(cachedCategories);
      _categoryState = CategoryState.loaded;
    }

    final cachedFoods =
        _foodRepository?.getCachedFoods() ?? const <FoodModel>[];
    if (cachedFoods.isNotEmpty) {
      _foods = cachedFoods;
      _foodState = FoodState.loaded;
    }
    _ensureValidSelectedCategory();
  }

  Future<void> refreshCategories({bool force = false}) async {
    if (_categories.length <= 1) _categoryState = CategoryState.loading;
    try {
      final repository = _categoryRepository;
      if (repository == null) {
        _categoryState = CategoryState.empty;
        notifyListeners();
        return;
      }
      final items = await repository.syncCategories(force: force);
      _categories = categoryFilterItems(items);
      _categoryState = _categories.length <= 1
          ? CategoryState.empty
          : CategoryState.loaded;
      _ensureValidSelectedCategory();
    } catch (error) {
      _categoryState = _categories.length <= 1
          ? CategoryState.error
          : CategoryState.loaded;
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> refreshFoods({bool force = false}) async {
    if (_foods.isEmpty) _foodState = FoodState.loading;
    try {
      final repository = _foodRepository;
      if (repository == null) {
        _foodState = FoodState.empty;
        notifyListeners();
        return;
      }
      final items = await repository.syncFoods(force: force);
      _foods = items;
      _foodState = _foods.isEmpty ? FoodState.empty : FoodState.loaded;
    } catch (error) {
      _foodState = _foods.isEmpty ? FoodState.error : FoodState.loaded;
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  void selectCategory(String categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void onSearchChanged(String keyword) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchKeyword == keyword) return;
      _searchKeyword = keyword;
      notifyListeners();
    });
  }

  void _ensureValidSelectedCategory() {
    final hasSelected = _categories.any(
      (item) => item.id == _selectedCategoryId,
    );
    if (!hasSelected) _selectedCategoryId = CategoryFilterItem.allId;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
