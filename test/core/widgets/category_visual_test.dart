import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/core/widgets/product_image.dart';

void main() {
  IconData iconFor(String category, [String name = '']) =>
      CategoryVisual.of(category, hint: name).icon;

  test('the real category decides when it is known', () {
    expect(iconFor('Incense', 'Himalayan Dhoop Sticks'), Icons.spa);
    expect(iconFor('Pooja Kits', 'Tihar Laxmi Pooja Kit'), Icons.card_giftcard);
    expect(iconFor('Brass Items', 'Brass Panas Batti'), Icons.emoji_objects_outlined);
    expect(iconFor('Diyas'), Icons.local_fire_department);
  });

  test('name keywords are the fallback for lines without a category', () {
    expect(iconFor('', 'Sandalwood Agarbatti (100 sticks)'), Icons.spa,
        reason: '"agarbatti" is incense, not a "batti" lamp');
    expect(iconFor('', 'Clay Diyo Set (12 pcs)'), Icons.local_fire_department);
    expect(iconFor('', 'Marigold Garland'), Icons.local_florist);
    expect(iconFor('', 'Ganesh Murti (Brass, 4 inch)'), Icons.temple_hindu);
    expect(iconFor('', 'Something else'), Icons.auto_awesome);
  });
}
