import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/core/network/json_reader.dart';

void main() {
  final json = <String, dynamic>{
    'name': 'Diya',
    'price': '240.50',
    'stock': 3.0,
    'active': 1,
    'tags': ['a', 2, 'b'],
    'items': [
      {'x': 1},
      'junk',
    ],
    'id': 42,
  };

  test('reads values of the expected type', () {
    expect(json.str('name'), 'Diya');
    expect(json.integer('stock'), 3);
    expect(json.flag('active'), isTrue);
    expect(json.strings('tags'), ['a', 'b']);
    expect(json.objects('items'), [
      {'x': 1}
    ]);
  });

  test('coerces near-misses instead of throwing', () {
    expect(json.dbl('price'), 240.5, reason: 'numeric string');
    expect(json.str('id'), '42', reason: 'number where a string was expected');
  });

  test('falls back for missing or wrong-typed values', () {
    expect(json.str('missing', 'none'), 'none');
    expect(json.strOrNull('missing'), isNull);
    expect(json.integer('name', 7), 7);
    expect(json.flag('name', true), isTrue);
    expect(json.strings('name'), isEmpty);
    expect(json.date('name'), isNull);
  });
}
