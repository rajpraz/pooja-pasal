/// Server-side sort options for paginated product queries. The enum names
/// are the API's `sort` values (`GET /products?sort=`).
enum ProductSort { newest, priceLowToHigh, priceHighToLow, popularity }
