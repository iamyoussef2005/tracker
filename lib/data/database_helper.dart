import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_theme_settings.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/savings_goal.dart';
import '../models/user_profile.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();
  static const List<Category> defaultCategories = [
    Category(name: 'Food', icon: 'restaurant', colorHex: '#D94841'),
    Category(name: 'Transport', icon: 'directions_car', colorHex: '#2D6A9F'),
    Category(name: 'Utilities', icon: 'bolt', colorHex: '#C17C10'),
  ];

  static const String _databaseName = 'finance_tracker.db';
  static const int _databaseVersion = 5;

  static const String expensesTable = 'expenses';
  static const String categoriesTable = 'categories';
  static const String budgetsTable = 'budgets';
  static const String monthlyIncomeTable = 'monthly_income';
  static const String savingsGoalsTable = 'savings_goals';
  static const String usersTable = 'users';
  static const String sessionsTable = 'sessions';
  static const String appThemeSettingsTable = 'app_theme_settings';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $categoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT,
        color_hex TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $expensesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        note TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES $categoriesTable (id)
          ON DELETE CASCADE
          ON UPDATE NO ACTION
      )
    ''');

    await db.execute('''
      CREATE TABLE $budgetsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        category_id INTEGER,
        FOREIGN KEY (category_id) REFERENCES $categoriesTable (id)
          ON DELETE SET NULL
          ON UPDATE NO ACTION
      )
    ''');

    await _createMonthlyIncomeTable(db);
    await _createSavingsGoalsTable(db);
    await _createAuthTables(db);
    await _createAppThemeSettingsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createMonthlyIncomeTable(db);
    }

    if (oldVersion < 3) {
      await _createSavingsGoalsTable(db);
    }

    if (oldVersion < 4) {
      await _createAuthTables(db);
    }

    if (oldVersion < 5) {
      await _createAppThemeSettingsTable(db);
    }
  }

  Future<void> _createMonthlyIncomeTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $monthlyIncomeTable (
        month TEXT PRIMARY KEY,
        amount REAL NOT NULL
      )
    ''');
  }

  Future<void> _createSavingsGoalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $savingsGoalsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0,
        deadline TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createAuthTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $usersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        display_name TEXT NOT NULL,
        photo_path TEXT,
        preferred_currency TEXT NOT NULL DEFAULT 'USD',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $sessionsTable (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id INTEGER NOT NULL,
        token TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $usersTable (id)
          ON DELETE CASCADE
          ON UPDATE NO ACTION
      )
    ''');
  }

  Future<void> _createAppThemeSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $appThemeSettingsTable (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        theme_mode TEXT NOT NULL,
        palette_id TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<AppThemeSettings> getAppThemeSettings() async {
    final maps = await (await database).query(
      appThemeSettingsTable,
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) {
      return AppThemeSettings.fallback;
    }

    return AppThemeSettings.fromMap(maps.first);
  }

  Future<void> upsertAppThemeSettings(AppThemeSettings settings) async {
    await (await database).insert(
      appThemeSettingsTable,
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertUser({
    required UserProfile user,
    required String passwordHash,
    required String passwordSalt,
  }) async {
    final db = await database;
    final map = user.toMap()
      ..remove('id')
      ..addAll({
        'password_hash': passwordHash,
        'password_salt': passwordSalt,
      });
    return db.insert(usersTable, map);
  }

  Future<UserProfile?> getUserByEmail(String email) async {
    final maps = await (await database).query(
      usersTable,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return UserProfile.fromMap(maps.first);
  }

  Future<UserAuthRecord?> getUserAuthByEmail(String email) async {
    final maps = await (await database).query(
      usersTable,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    final map = maps.first;
    return UserAuthRecord(
      profile: UserProfile.fromMap(map),
      passwordHash: map['password_hash'] as String,
      passwordSalt: map['password_salt'] as String,
    );
  }

  Future<UserProfile?> getUserById(int id) async {
    final maps = await (await database).query(
      usersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return UserProfile.fromMap(maps.first);
  }

  Future<int> updateUserProfile(UserProfile user) async {
    if (user.id == null) {
      throw ArgumentError('User id is required for update.');
    }

    final map = user.toMap()..remove('id');
    return (await database).update(
      usersTable,
      map,
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> replaceSession({
    required int userId,
    required String token,
  }) async {
    await (await database).insert(sessionsTable, {
      'id': 1,
      'user_id': userId,
      'token': token,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserProfile?> getCurrentSessionUser() async {
    final maps = await (await database).query(
      sessionsTable,
      columns: ['user_id'],
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return getUserById(maps.first['user_id'] as int);
  }

  Future<int> clearSession() async {
    return (await database).delete(
      sessionsTable,
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert(expensesTable, expense.toMap());
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final maps = await db.query(expensesTable, orderBy: 'date DESC');
    return maps.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month);
    final startOfNextMonth = DateTime(month.year, month.month + 1);

    return getExpensesBetween(
      start: startOfMonth,
      endExclusive: startOfNextMonth,
    );
  }

  Future<List<Expense>> getExpensesBetween({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final maps = await (await database).query(
      expensesTable,
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), endExclusive.toIso8601String()],
      orderBy: 'date DESC',
    );

    return maps.map(Expense.fromMap).toList();
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await database;
    final maps = await db.query(
      expensesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Expense.fromMap(maps.first);
  }

  Future<int> updateExpense(Expense expense) async {
    if (expense.id == null) {
      throw ArgumentError('Expense id is required for update.');
    }

    final db = await database;
    return db.update(
      expensesTable,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete(expensesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert(categoriesTable, category.toMap());
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query(categoriesTable, orderBy: 'name ASC');
    return maps.map(Category.fromMap).toList();
  }

  Future<void> ensureDefaultCategories(List<Category> categories) async {
    final db = await database;

    await db.transaction((txn) async {
      for (final category in categories) {
        final existing = await txn.query(
          categoriesTable,
          columns: ['id'],
          where: 'name = ?',
          whereArgs: [category.name],
          limit: 1,
        );

        if (existing.isEmpty) {
          await txn.insert(categoriesTable, category.toMap());
        }
      }
    });
  }

  Future<List<Category>> getCategoriesEnsuringDefaults() async {
    await ensureDefaultCategories(defaultCategories);
    return getCategories();
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final maps = await db.query(
      categoriesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Category.fromMap(maps.first);
  }

  Future<int> updateCategory(Category category) async {
    if (category.id == null) {
      throw ArgumentError('Category id is required for update.');
    }

    final db = await database;
    return db.update(
      categoriesTable,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete(categoriesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    return db.insert(budgetsTable, budget.toMap());
  }

  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final maps = await db.query(budgetsTable, orderBy: 'start_date DESC');
    return maps.map(Budget.fromMap).toList();
  }

  Future<List<Budget>> getBudgetsForMonth(DateTime month) async {
    final db = await database;
    final startOfMonth = DateTime(month.year, month.month);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final maps = await db.query(
      budgetsTable,
      where: 'start_date <= ? AND end_date >= ?',
      whereArgs: [endOfMonth.toIso8601String(), startOfMonth.toIso8601String()],
      orderBy: 'start_date DESC',
    );

    return maps.map(Budget.fromMap).toList();
  }

  Future<Budget?> getBudgetById(int id) async {
    final db = await database;
    final maps = await db.query(
      budgetsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Budget.fromMap(maps.first);
  }

  Future<int> updateBudget(Budget budget) async {
    if (budget.id == null) {
      throw ArgumentError('Budget id is required for update.');
    }

    final db = await database;
    return db.update(
      budgetsTable,
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return db.delete(budgetsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<double?> getMonthlyIncome(DateTime month) async {
    final db = await database;
    final maps = await db.query(
      monthlyIncomeTable,
      columns: ['amount'],
      where: 'month = ?',
      whereArgs: [_monthKey(month)],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return (maps.first['amount'] as num).toDouble();
  }

  Future<void> upsertMonthlyIncome({
    required DateTime month,
    required double amount,
  }) async {
    final db = await database;
    await db.insert(monthlyIncomeTable, {
      'month': _monthKey(month),
      'amount': amount,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteMonthlyIncome(DateTime month) async {
    final db = await database;
    return db.delete(
      monthlyIncomeTable,
      where: 'month = ?',
      whereArgs: [_monthKey(month)],
    );
  }

  Future<int> insertSavingsGoal(SavingsGoal goal) async {
    final db = await database;
    return db.insert(savingsGoalsTable, goal.toMap());
  }

  Future<List<SavingsGoal>> getSavingsGoals() async {
    final db = await database;
    final maps = await db.query(savingsGoalsTable, orderBy: 'deadline ASC');
    return maps.map(SavingsGoal.fromMap).toList();
  }

  Future<int> updateSavingsGoal(SavingsGoal goal) async {
    if (goal.id == null) {
      throw ArgumentError('Savings goal id is required for update.');
    }

    final db = await database;
    return db.update(
      savingsGoalsTable,
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteSavingsGoal(int id) async {
    final db = await database;
    return db.delete(savingsGoalsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  String _monthKey(DateTime month) {
    final normalizedMonth = DateTime(month.year, month.month);
    final monthValue = normalizedMonth.month.toString().padLeft(2, '0');
    return '${normalizedMonth.year}-$monthValue';
  }
}

class UserAuthRecord {
  const UserAuthRecord({
    required this.profile,
    required this.passwordHash,
    required this.passwordSalt,
  });

  final UserProfile profile;
  final String passwordHash;
  final String passwordSalt;
}
