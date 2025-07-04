import 'dart:async';
import 'dart:io';

// Enum for category
enum Category {
  food,
  drink,
}

// Logger mixin for logging messages
mixin LoggerMixin {
  void log(String message) {
    final time = DateTime.now().toIso8601String();
    print('[$time] $message');
  }
}

// Abstract base class with mixin
abstract class Consumable {
  final String name;
  final int calories;

  Consumable({required this.name, required this.calories});

  Category get category;

  bool get isHighCalorie => calories > 500;

  void printCalories() {
    print('$name has $calories calories.');
  }
}

// Food class: Inherit from Consumable
class Food extends Consumable {
  Food({required super.name, required super.calories});

  @override
  Category get category => Category.food;
}

// Drink class with sugary flag default as false
class Drink extends Consumable {
  final bool isSugary;
  Drink({required super.name, required super.calories, this.isSugary = false});

  @override
  Category get category => Category.drink;
}

// Tracker class for any Consumable type, uses LoggerMixin
class Tracker<T extends Consumable> with LoggerMixin {
  final List<T> _items = []; //private list, can't be modified outside


  void add(T item) {
    _items.add(item);
    log('${item.name} added!');

    if (item.category == Category.food) {
      if (item.isHighCalorie) {
        log('⚠️ Alert: ${item.name} is high in calories!');
      }
    } else if (item.category == Category.drink) {
      final drink = item as Drink;
      if (drink.isSugary) {
        if (drink.isHighCalorie) {
          log('Warning: ${drink.name} is both sugary and high in calories!');
        } else {
          log('Note: ${drink.name} is sugary!');
        }
      }
    }
  }

  List<T> get items => List.unmodifiable(_items); //return a read-only version of the list _items

  String listItems() {
    if (_items.isEmpty) {
      return 'No items tracked yet.';
    }
    return _items.map((item) => '${item.name} (${item.calories} cal)').join(', ');
  } //Transforms each item in the _items list into a formatted string.

  int totalCalories() {
    return _items.fold(0, (sum, item) => sum + item.calories);
  } //fold(initialValue = 0, combineFunction: (sum, item) => sum + item.calories )

  void deleteAt(int index) {
    if (index < 0 || index >= _items.length) {
      log('Invalid index: $index');
      return;
    }
    final removed = _items.removeAt(index);
    log('${removed.name} removed.');
  }

  void deleteByName(String nameToDelete) {
   final index = _items.indexWhere(
      (item) => item.name.toLowerCase() == nameToDelete.toLowerCase(),
   );

   if (index == -1) {
      log('Item "$nameToDelete" not found.');
      return;
   }

   deleteAt(index);
}

}

// Helper extension to parse calories safely from String input
extension CalorieParser on String {
  int? tryToCalories() {
    try {
      final val = int.parse(this);
      if (val < 0) return null; // negative calories invalid 
      return val;
    } catch (_) {
      return null; //Return null if parsing fails
    }
  }
}

// Capitalize first letter
extension Capitalize on String {
  String capitalize() => this.isEmpty ? this : this[0].toUpperCase() + substring(1);
}

// Helper to ask user for input synchronously
String askSync(String prompt) {
  stdout.write(prompt);
  return stdin.readLineSync() ?? ''; //return a String or return null ''
}

// Async function for startup delay with Future
Future<void> showStartupMessage() async {
  print('Program started. Please wait...\n');
  await Future.delayed(Duration(seconds: 1));
}

void validateMenuChoice(String input) {
  if (!RegExp(r'^[1-8]$').hasMatch(input)) {
    throw FormatException('Invalid choice. Please enter a number from 1 to 8.');
  }
}

void main() async {
  await showStartupMessage();

  final tracker = Tracker<Consumable>();
  const dailyCalorieLimit = 1500;


  print('\nWelcome to the Food & Drink Tracker!');

  while (true) {
    print('\nMenu:');
    print('1. Add food');
    print('2. Add drink'); 
    print('3. Delete food');
    print('4. Delete drink');
    print('5. List food');
    print('6. List drink');
    print('7. Show total calories');
    print('8. Exit');
    
    int menuChoice = 0;

    try {
      final choice = askSync('Enter choice: ').trim();
      validateMenuChoice(choice); // throws if invalid

      menuChoice = int.parse(choice); // Now it's safe to parse
      
      } catch (e) {
      print('Error: $e');
      continue; // ask for input again
      }

    switch (menuChoice) {
      case 1: // Add food
        final name = askSync('Enter food name: ').capitalize();

        final calsInput = askSync('Enter calorie amount: ');
        final cals = calsInput.tryToCalories();
        if (cals == null) {
          print('Invalid calories. Must be a non-negative integer.');
          break;
        }

        tracker.add(Food(name: name, calories: cals));
        break;

      case 2: // Add drink
        final name = askSync('Enter drink name: ').capitalize();

        final calsInput = askSync('Enter calorie amount: ');
        final cals = calsInput.tryToCalories();
        if (cals == null) {
          print('Invalid calories. Must be a non-negative integer.');
          break;
        }

        final sugaryInput = askSync('Is it sugary? (yes/no): ').toLowerCase();
        final isSugary = sugaryInput == 'yes';

        tracker.add(Drink(name: name, calories: cals, isSugary: isSugary));
        break;

      case 3: // Delete food
        final foodItems = tracker.items.where((i) => i.category == Category.food).toList();
         if (foodItems.isEmpty) {
            tracker.log('No food items in the list.');
            break;
         }
        final foodName = askSync('Enter the food to be deleted: ').trim();
        tracker.deleteByName(foodName);
        break;

      case 4: // Delete drink
        final drinkItems = tracker.items.where((i) => i.category == Category.drink).toList();
         if (drinkItems.isEmpty) {
            tracker.log('No drink items in the list.');
            break;
         }
        final drinkName = askSync('Enter the drink to be deleted: ').trim();
        tracker.deleteByName(drinkName);
        break;

      case 5: // List food
        print('\nTracked Food:');
        final foodItems = tracker.items.where((i) => i.category == Category.food).toList();
        if (foodItems.isEmpty) {
          print('No food items tracked yet.');
        } else {
          print(foodItems.map((f) => '${f.name} (${f.calories} cal)').join(', '));
        }
        break;

      case 6: // List drink
        print('\nTracked Drinks:');
        final drinkItems = tracker.items.where((i) => i.category == Category.drink).toList();
        if (drinkItems.isEmpty) {
          print('No drink items tracked yet.');
        } else {
          print(drinkItems.map((d) {
            final sug = (d as Drink).isSugary ? ' (Sugary)' : '';
            return '${d.name} (${d.calories} cal)$sug';
          }).join(', '));
        }
        break;

      case 7: // Show totals
        final totalFoodCalories = tracker.items
            .where((i) => i.category == Category.food)
            .fold(0, (sum, i) => sum + i.calories);
        final totalDrinkCalories = tracker.items
            .where((i) => i.category == Category.drink)
            .fold(0, (sum, i) => sum + i.calories);
        final grandTotal = totalFoodCalories + totalDrinkCalories;

        print('\nTotal Calories:');
        print('- Food: $totalFoodCalories cal');
        print('- Drinks: $totalDrinkCalories cal');

        if (grandTotal > dailyCalorieLimit) {
          final overCalories = grandTotal - dailyCalorieLimit;
          print('⚠️ Grand Total: $grandTotal cal — you are over your daily limit by $overCalories calories!');
        } 
        break;

      case 8: // Exit
        print('\nExiting program, goodbye!');
        exit(0);

    }
  }
}
