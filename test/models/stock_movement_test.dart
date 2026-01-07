import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/models/stock_movement.dart';

void main() {
  group('StockMovement Tests', () {
    test('toMap should convert StockMovement to Map correctly', () {
      final movement = StockMovement(
        id: 1,
        productId: 'p1',
        previousQty: 10,
        newQty: 15,
        changeType: 'add',
        reason: 'Restock',
        timestamp: DateTime(2026, 1, 1, 10, 0),
      );

      final map = movement.toMap();

      expect(map['id'], equals(1));
      expect(map['productId'], equals('p1'));
      expect(map['previousQty'], equals(10));
      expect(map['newQty'], equals(15));
      expect(map['changeType'], equals('add'));
      expect(map['reason'], equals('Restock'));
      expect(map['timestamp'], equals('2026-01-01T10:00:00.000'));
    });

    test('fromMap should create StockMovement from Map correctly', () {
      final map = {
        'id': 2,
        'productId': 'p2',
        'previousQty': 20,
        'newQty': 15,
        'changeType': 'remove',
        'reason': 'Sale',
        'timestamp': '2026-01-02T14:30:00.000',
      };

      final movement = StockMovement.fromMap(map);

      expect(movement.id, equals(2));
      expect(movement.productId, equals('p2'));
      expect(movement.previousQty, equals(20));
      expect(movement.newQty, equals(15));
      expect(movement.changeType, equals('remove'));
      expect(movement.reason, equals('Sale'));
      expect(movement.timestamp, equals(DateTime.parse('2026-01-02T14:30:00.000')));
    });
  });

  group('StockMovementData Tests', () {
    test('toMap should convert StockMovementData to Map correctly', () {
      final data = StockMovementData(
        date: DateTime(2026, 1, 1),
        stockIn: 50,
        stockOut: 30,
      );

      final map = data.toMap();

      expect(map['date'], equals(DateTime(2026, 1, 1).millisecondsSinceEpoch));
      expect(map['stock_in'], equals(50));
      expect(map['stock_out'], equals(30));
    });

    test('fromDb should create StockMovementData from Map correctly', () {
      final map = {
        'date': DateTime(2026, 1, 2).millisecondsSinceEpoch,
        'stock_in': 100,
        'stock_out': 75,
      };

      final data = StockMovementData.fromDb(map);

      expect(data.date, equals(DateTime(2026, 1, 2)));
      expect(data.stockIn, equals(100));
      expect(data.stockOut, equals(75));
    });
  });

  group('StockMovementSummary Tests', () {
    test('fromDailyData should calculate totals correctly', () {
      final dailyData = [
        StockMovementData(date: DateTime(2026, 1, 1), stockIn: 50, stockOut: 20),
        StockMovementData(date: DateTime(2026, 1, 2), stockIn: 30, stockOut: 15),
        StockMovementData(date: DateTime(2026, 1, 3), stockIn: 40, stockOut: 25),
      ];

      final summary = StockMovementSummary.fromDailyData(dailyData);

      expect(summary.totalIn, equals(120)); // 50 + 30 + 40
      expect(summary.totalOut, equals(60)); // 20 + 15 + 25
      expect(summary.dailyData.length, equals(3));
    });

    test('fromMovements should aggregate movements correctly', () {
      final movements = [
        // Day 1: +10
        StockMovement(
          productId: 'p1',
          previousQty: 10,
          newQty: 20,
          changeType: 'add',
          timestamp: DateTime(2026, 1, 1, 10, 0),
        ),
        // Day 1: -5
        StockMovement(
          productId: 'p1',
          previousQty: 20,
          newQty: 15,
          changeType: 'remove',
          timestamp: DateTime(2026, 1, 1, 15, 0),
        ),
        // Day 2: +20
        StockMovement(
          productId: 'p1',
          previousQty: 15,
          newQty: 35,
          changeType: 'add',
          timestamp: DateTime(2026, 1, 2, 9, 0),
        ),
      ];

      final summary = StockMovementSummary.fromMovements(
        movements,
        DateTime(2026, 1, 1),
        2,
      );

      expect(summary.totalIn, equals(30)); // 10 + 20
      expect(summary.totalOut, equals(5)); // 5
      expect(summary.dailyData.length, equals(2));
      expect(summary.dailyData[0].stockIn, equals(10));
      expect(summary.dailyData[0].stockOut, equals(5));
      expect(summary.dailyData[1].stockIn, equals(20));
      expect(summary.dailyData[1].stockOut, equals(0));
    });

    test('fromMovements should filter movements outside date range', () {
      final movements = [
        // Before range
        StockMovement(
          productId: 'p1',
          previousQty: 10,
          newQty: 20,
          changeType: 'add',
          timestamp: DateTime(2025, 12, 31),
        ),
        // In range
        StockMovement(
          productId: 'p1',
          previousQty: 20,
          newQty: 30,
          changeType: 'add',
          timestamp: DateTime(2026, 1, 1),
        ),
        // After range
        StockMovement(
          productId: 'p1',
          previousQty: 30,
          newQty: 40,
          changeType: 'add',
          timestamp: DateTime(2026, 1, 5),
        ),
      ];

      final summary = StockMovementSummary.fromMovements(
        movements,
        DateTime(2026, 1, 1),
        3, // Jan 1-3
      );

      expect(summary.totalIn, equals(10)); // Only the middle movement
      expect(summary.totalOut, equals(0));
    });

    test('fromMovements should normalize timestamps to midnight', () {
      final movements = [
        // Same day, different times
        StockMovement(
          productId: 'p1',
          previousQty: 10,
          newQty: 15,
          changeType: 'add',
          timestamp: DateTime(2026, 1, 1, 8, 30),
        ),
        StockMovement(
          productId: 'p1',
          previousQty: 15,
          newQty: 25,
          changeType: 'add',
          timestamp: DateTime(2026, 1, 1, 16, 45),
        ),
      ];

      final summary = StockMovementSummary.fromMovements(
        movements,
        DateTime(2026, 1, 1),
        1,
      );

      // Both should be aggregated to the same day
      expect(summary.dailyData[0].stockIn, equals(15)); // 5 + 10
    });

    test('fromMovements should handle negative changes as stockOut', () {
      final movements = [
        StockMovement(
          productId: 'p1',
          previousQty: 50,
          newQty: 30,
          changeType: 'remove',
          timestamp: DateTime(2026, 1, 1),
        ),
      ];

      final summary = StockMovementSummary.fromMovements(
        movements,
        DateTime(2026, 1, 1),
        1,
      );

      expect(summary.totalIn, equals(0));
      expect(summary.totalOut, equals(20)); // 50 - 30
    });

    test('fromMovements should initialize all days even with no movements', () {
      final summary = StockMovementSummary.fromMovements(
        [], // No movements
        DateTime(2026, 1, 1),
        5, // 5 days
      );

      expect(summary.dailyData.length, equals(5));
      expect(summary.totalIn, equals(0));
      expect(summary.totalOut, equals(0));
      
      // All days should have zero values
      for (var data in summary.dailyData) {
        expect(data.stockIn, equals(0));
        expect(data.stockOut, equals(0));
      }
    });
  });
}
