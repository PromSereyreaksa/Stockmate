import '../services/database_service.dart';
import '../data/data_seeder.dart';

// Utility to reset and reseed the database
// This will delete all existing data and recreate tables with fresh seed data

// the prints are for debugging purposes.
class DatabaseResetter {
  static Future<void> resetAndReseed() async {
    try {
      print('Starting database reset...');

      // Reset the database (delete and recreate)
      await DatabaseService.instance.resetDatabase();
      print('Database reset successfully');

      // Reseed with initial data
      print('Seeding data...');
      await DataSeeder().seedInitialData();
      print('Data seeded successfully');
      
      print('Database reinitialized with fresh data including images!');
    } catch (e) {
      print('Error resetting database: $e');
      rethrow;
    }
  }
}
