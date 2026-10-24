import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/app/theme/app_theme.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/presentation/widgets/product_card.dart';

import '../../support/fakes.dart';

Product _product({int stock = 10, String festival = '', int ratingCount = 0}) => Product(
      id: 'p1',
      name: 'Brass Diya',
      description: '',
      price: 500,
      category: 'Diyas',
      images: const [],
      stock: stock,
      sellerId: 's1',
      sellerName: 'Shree Pooja Bhandar',
      isActive: true,
      festivalTag: festival,
      ratingAverage: 4.5,
      ratingCount: ratingCount,
    );

Future<void> _pump(WidgetTester tester, Product product, {double width = 180}) {
  return tester.pumpWidget(ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: ProductCard.heightFor(width),
            child: ProductCard(product: product),
          ),
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('shows name, seller, price and an add button', (tester) async {
    await _pump(tester, _product());
    expect(find.text('Brass Diya'), findsOneWidget);
    expect(find.text('by Shree Pooja Bhandar'), findsOneWidget);
    expect(find.text('Rs.500'), findsOneWidget);
    expect(find.byTooltip('Add to cart'), findsOneWidget);
  });

  testWidgets('badges festival, low stock and rating', (tester) async {
    await _pump(tester, _product(stock: 3, festival: 'Tihar', ratingCount: 12));
    expect(find.text('Tihar'), findsOneWidget);
    expect(find.text('Only 3 left'), findsOneWidget);
    expect(find.text('4.5 · 12'), findsOneWidget);
  });

  testWidgets('a sold-out product says so and cannot be added', (tester) async {
    await _pump(tester, _product(stock: 0));
    expect(find.text('Sold out'), findsOneWidget);
    final button = tester.widget<IconButton>(
        find.ancestor(of: find.byTooltip('Sold out'), matching: find.byType(IconButton)));
    expect(button.onPressed, isNull);
  });

  testWidgets('fits its grid cell at narrow and wide widths without overflowing', (tester) async {
    for (final width in [150.0, 180.0, 240.0]) {
      await _pump(tester, _product(stock: 3, festival: 'Dashain', ratingCount: 2), width: width);
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });

  test('the grid uses 2 columns on a phone and up to 4 on wide screens', () {
    int columnsFor(double width) {
      final layout = const ProductGridDelegate().getLayout(SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0,
        precedingScrollExtent: 0,
        overlap: 0,
        remainingPaintExtent: 800,
        crossAxisExtent: width,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 800,
        remainingCacheExtent: 800,
        cacheOrigin: 0,
      )) as SliverGridRegularTileLayout;
      return layout.crossAxisCount;
    }

    expect(columnsFor(360), 2);
    expect(columnsFor(560), 3);
    expect(columnsFor(720), 4);
    expect(columnsFor(1400), 4);
  });
}
