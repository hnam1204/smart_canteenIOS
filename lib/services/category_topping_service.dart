import '../models/topping_model.dart';

class CategoryToppingService {
  static const String catRice = 'cat_rice';
  static const String catNoodle = 'cat_noodle';
  static const String catPho = 'cat_pho';
  static const String catSnack = 'cat_snack';
  static const String catDrink = 'cat_drink';

  static List<ToppingModel> optionsFor(String categoryId) {
    final normalized = categoryId.trim().toLowerCase();
    final resolved = switch (normalized) {
      catRice || 'rice' || 'com' => catRice,
      catNoodle || 'noodle' || 'mi' => catNoodle,
      catPho || 'pho' => catPho,
      catSnack || 'snack' => catSnack,
      catDrink || 'drink' => catDrink,
      _ => normalized,
    };
    return switch (resolved) {
      catRice => const [
        ToppingModel(id: 'egg', name: 'Thêm trứng ốp la', price: 7000),
        ToppingModel(id: 'extra_rice', name: 'Thêm cơm', price: 5000),
        ToppingModel(id: 'extra_meat', name: 'Thêm thịt', price: 12000),
        ToppingModel(id: 'fish_sauce', name: 'Nước mắm riêng', price: 0),
      ],
      catNoodle => const [
        ToppingModel(id: 'egg', name: 'Thêm trứng', price: 7000),
        ToppingModel(id: 'sausage', name: 'Thêm xúc xích', price: 10000),
        ToppingModel(id: 'beef_ball', name: 'Thêm bò viên', price: 12000),
        ToppingModel(id: 'less_spicy', name: 'Ít cay', price: 0),
        ToppingModel(id: 'extra_spicy', name: 'Cay nhiều', price: 0),
      ],
      catPho => const [
        ToppingModel(id: 'beef_ball', name: 'Thêm bò viên', price: 12000),
        ToppingModel(id: 'rare_beef', name: 'Thêm thịt tái', price: 15000),
        ToppingModel(id: 'extra_noodle', name: 'Thêm bánh phở', price: 7000),
        ToppingModel(id: 'more_onion', name: 'Nhiều hành', price: 0),
        ToppingModel(id: 'no_onion', name: 'Không hành', price: 0),
      ],
      catSnack => const [
        ToppingModel(id: 'cheese', name: 'Thêm phô mai', price: 8000),
        ToppingModel(id: 'spicy_sauce', name: 'Thêm sốt cay', price: 3000),
        ToppingModel(id: 'chili_sauce', name: 'Thêm tương ớt', price: 0),
        ToppingModel(id: 'mayo', name: 'Thêm mayonnaise', price: 3000),
      ],
      catDrink => const [
        ToppingModel(id: 'pearl', name: 'Thêm trân châu', price: 7000),
        ToppingModel(id: 'jelly', name: 'Thêm thạch', price: 6000),
        ToppingModel(id: 'less_ice', name: 'Ít đá', price: 0),
        ToppingModel(id: 'no_ice', name: 'Không đá', price: 0),
        ToppingModel(id: 'less_sugar', name: 'Ít đường', price: 0),
        ToppingModel(id: 'no_sugar', name: 'Không đường', price: 0),
      ],
      _ => const [],
    };
  }
}
