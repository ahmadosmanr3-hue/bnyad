/// Per-piece / per-bowl gram weights for the big `foodDatabase` list.
///
/// Adding an entry here automatically enables the **piece** and/or **bowl**
/// mode for that food in the food-log sheet — the serving switch synthesizes
/// a variant with linearly scaled macros/micros from the canonical per-100g
/// row, so no separate `FoodItem` is needed.
///
/// `{id : (gramsPerPiece, gramsPerBowl)}`. Use `null` for the mode that does
/// not apply (e.g. a rice with no natural "piece" size).
///
/// Numbers come from typical real-world servings: a medium dolma is ~50g, a
/// rice bowl is ~160g cooked, a slice of bread is ~28g, a chicken fillet is
/// ~150g, etc. The user can still override with the gram slider for precision.
const Map<String, (double?, double?)> coreFoodServingOverrides = {
  // ─── Kurdish / Iraqi (k*) ──────────────────────────────
  'k1': (50, 300),     // Dolma — 1 stuffed roll, full plate ≈ 6 pieces
  'k2': (null, 300),   // Kurdish Biryani
  'k3': (60, 360),     // Kubba — 6 balls per plate
  'k4': (null, 350),   // Tashreeb
  'k5': (90, null),    // Kurdish Naan — 1 flatbread
  'k6': (null, 300),   // Tepsi Baytinijan (eggplant casserole)
  'k7': (null, 300),   // Parcha (trotter soup)
  'k8': (null, 250),   // Qeema
  'k9': (null, 300),   // Fasolia bean stew
  'k10': (null, 250),  // Bamya (okra stew)
  'k12': (null, 300),  // Shorba lentil
  'k13': (40, 240),    // Yaprax — 1 leaf, plate ≈ 6
  'k14': (70, null),   // Kuba Halab
  'k15': (null, 240),  // Mastaw (yogurt drink) — 1 cup
  'k16': (100, null),  // Tikka chicken — 1 skewer
  'k18': (null, 280),  // Margat Bamya
  'k19': (25, null),   // Kleicha — 1 cookie
  'k20': (null, 200),  // Makhlama
  'k21': (80, null),   // Kahi — 1 piece
  'k22': (null, 100),  // Gaymer — 1 serving bowl
  'k23': (null, 250),  // Saffron rice
  'k24': (null, 300),  // Biryani Dajaj
  'k25': (50, 300),    // Dolma Silq

  // ─── Arabic / Middle Eastern (a*) ──────────────────────
  'a1': (null, 150),   // Hummus
  'a2': (17, 100),     // Falafel — 1 ball, 5–6 per plate
  'a3': (200, null),   // Shawarma — 1 wrap
  'a4': (null, 400),   // Mansaf
  'a5': (null, 100),   // Tabbouleh
  'a6': (null, 200),   // Fattoush
  'a7': (null, 120),   // Baba Ganoush
  'a8': (null, 120),   // Labneh
  'a9': (50, null),    // Kibbeh — 1 piece
  'a10': (250, null),  // Musakhan — 1 plate
  'a11': (null, 300),  // Koshari
  'a12': (null, 200),  // Ful Medames
  'a13': (30, null),   // Sambousek — 1 piece
  'a14': (80, 400),    // Mahshi — 1 stuffed zucchini, 5 per plate
  'a15': (100, null),  // Kunafeh — 1 piece
  'a16': (null, 250),  // Shakshuka
  'a17': (null, 350),  // Maqluba
  'a18': (25, null),   // Maamoul — 1 cookie
  'a19': (null, 250),  // Mulukhiyah
  'a20': (25, 200),    // Warak Enab — 1 leaf, 8 per plate
  'a21': (100, null),  // Shish Tawook — 1 skewer
  'a22': (120, null),  // Manakeesh — 1 small flatbread
  'a23': (100, null),  // Arayes — 1 meat-pita
  'a24': (30, null),   // Jawaneh — 1 wing

  // ─── Proteins (p*) ─────────────────────────────────────
  'p1': (150, null),   // Grilled Chicken Breast — 1 fillet
  'p1_fried': (150, null),
  'p1_boiled': (150, null),
  'p1_stew': (150, null),
  'p1_roasted': (150, null),
  'p2': (150, null),   // Salmon Fillet
  'p3': (180, null),   // Beef Steak
  'p5': (90, null),    // Lamb Chop
  'p6': (85, null),    // Tuna can (drained)
  'p7': (12, null),    // Shrimp (large)
  'p8': (50, null),    // Whole Egg — 1 large (by weight row)
  'p8_boiled': (50, null),
  'p8_fried': (50, null),
  'p8_poached': (50, null),
  'p8_scrambled': (50, null),
  'kuu_paqla_raw_no_oil_100g': (80, 170),
  'kuu_paqla_raw_with_oil_100g': (80, 170),
  'kuu_paqla_boiled_no_oil_100g': (80, 170),
  'kuu_paqla_boiled_with_oil_100g': (80, 170),
  'kuu_paqla_raw_fried_no_oil_100g': (80, 170),
  'kuu_paqla_raw_fried_with_oil_100g': (80, 170),
  'kuu_paqla_boiled_fried_no_oil_100g': (80, 170),
  'kuu_paqla_boiled_fried_with_oil_100g': (80, 170),
  'p9': (33, null),    // Egg White — 1 large
  'p10': (30, null),   // Turkey Breast — 1 deli slice
  'p11': (130, null),  // Chicken Thigh
  'p12': (12, null),   // Sardine — 1 fish
  'p13': (30, null),   // Chicken Wing
  'p14': (100, null),  // Beef Liver slice
  'p15': (200, null),  // Lamb Shoulder portion
  'p16': (150, null),  // Tilapia fillet
  'p17': (170, null),  // Duck Breast
  'p18': (90, null),   // Tofu block portion
  'p19': (100, null),  // Beef Tongue slice
  'p20': (30, null),   // Crab meat portion
  'p21': (80, null),   // Chicken Liver
  'p22': (100, null),  // Lamb Kebab — 1 skewer
  'p23': (null, 240),  // Bone Broth — 1 cup

  // ─── Dairy (d*) ────────────────────────────────────────
  'd1': (null, 170),   // Greek Yogurt — 1 cup
  'd2': (null, 240),   // Whole Milk — 1 cup
  'd3': (28, null),    // Cheddar — 1 slice
  'd4': (null, 113),   // Cottage Cheese — 1/2 cup
  'd5': (28, null),    // Mozzarella — 1 slice
  'd6': (5, null),     // Butter — 1 pat
  'd7': (30, null),    // Cream Cheese — 1 tbsp+
  'd8': (null, 170),   // Plain Yogurt — 1 cup
  'd9': (28, null),    // Feta cube
  'd10': (5, null),    // Parmesan — 1 tbsp
  'd11': (null, 240),  // Skim Milk
  'd13': (null, 124),  // Ricotta — 1/2 cup
  'd14': (null, 240),  // Kefir — 1 cup
  'd15': (28, null),   // Akkawi slice
  'd16': (28, null),   // Kashkaval slice

  // ─── Grains & Carbs (g*) ──────────────────────────────
  'g1': (null, 158),   // Brown Rice — 1 cup cooked
  'g2': (null, 158),   // White Rice — 1 cup cooked
  'g3': (null, 234),   // Oatmeal cooked — 1 cup
  'g4': (28, null),    // Whole Wheat Bread — 1 slice
  'g5': (28, null),    // White Bread — 1 slice
  'g6': (null, 140),   // Pasta cooked — 1 cup
  'g7': (null, 185),   // Quinoa cooked
  'g8': (130, 200),    // Sweet Potato — medium / mashed bowl
  'g9': (170, null),   // Potato boiled — medium
  'g10': (24, null),   // Corn Tortilla
  'g11': (null, 180),  // Bulgur cooked
  'g12': (null, 175),  // Couscous cooked
  'g13': (null, 158),  // Basmati Rice cooked
  'g14': (60, null),   // Pita Bread — 1 round
  'g15': (null, 56),   // Vermicelli (dry) — 1 bowl
  'g16': (null, 30),   // Cornflakes — 1 bowl (dry)
  'g17': (50, null),   // Flour Tortilla
  'g18': (null, 180),  // Freekeh cooked
  'g19': (100, null),  // Samoon — 1 loaf
  'g20': (90, null),   // Tannour Bread — 1 piece

  // ─── Fruits (f*) ──────────────────────────────────────
  'f1': (180, null),   // Apple — medium
  'f2': (120, null),   // Banana — medium
  'f3': (130, null),   // Orange — medium
  'f4': (12, 150),     // Strawberry — 1 berry / 1 cup
  'f5': (null, 280),   // Watermelon slice
  'f6': (null, 150),   // Grapes — 1 cup
  'f7': (200, 165),    // Mango — 1 whole / 1 cup chunks
  'f8': (280, null),   // Pomegranate
  'f9': (8, null),     // Date — 1 piece
  'f10': (50, null),   // Fig — 1 fruit
  'f11': (150, null),  // Peach
  'f12': (180, null),  // Pear
  'f13': (null, 148),  // Blueberry — 1 cup
  'f14': (200, null),  // Avocado — 1 whole
  'f15': (null, 165),  // Pineapple — 1 cup chunks
  'f16': (75, null),   // Kiwi
  'f17': (5, 150),     // Cherry — 1 fruit / 1 cup
  'f18': (60, null),   // Lemon
  'f19': (35, null),   // Apricot
  'f20': (null, 80),   // Fresh Coconut — 1 cup shredded
  'f21': (280, null),  // Papaya
  'f22': (65, null),   // Plum
  'f23': (null, 140),  // Mulberry — 1 cup
  'f24': (null, 160),  // Cantaloupe — 1 cup balls

  // ─── Vegetables (v*) ──────────────────────────────────
  'v1': (null, 91),    // Broccoli — 1 cup chopped
  'v2': (null, 30),    // Spinach — 1 cup raw
  'v3': (120, null),   // Tomato — medium
  'v4': (200, null),   // Cucumber
  'v5': (60, null),    // Carrot — medium
  'v6': (250, null),   // Eggplant
  'v7': (110, null),   // Onion — medium
  'v8': (120, null),   // Bell Pepper
  'v9': (null, 50),    // Lettuce — 1 cup shredded
  'v10': (200, null),  // Zucchini
  'v11': (null, 100),  // Cauliflower — 1 cup florets
  'v12': (null, 100),  // Green Beans — 1 cup
  'v13': (18, 70),     // Mushroom — 1 / 1 cup sliced
  'v14': (3, null),    // Garlic — 1 clove
  'v15': (null, 89),   // Cabbage — 1 cup shredded
  'v16': (40, null),   // Celery — 1 stalk
  'v17': (90, null),   // Leek
  'v18': (5, 116),     // Radish — 1 / 1 cup
  'v19': (120, null),  // Turnip
  'v20': (80, null),   // Beetroot
  'v21': (16, null),   // Asparagus — 1 spear
  'v22': (120, null),  // Artichoke
  'v23': (90, null),   // Sweet Corn — 1 ear
  'v24': (null, 30),   // Parsley — 1 cup chopped
  'v25': (null, 30),   // Fresh Mint — 1 cup
  'v26': (null, 80),   // Raw Okra
  'v27': (null, 116),  // Pumpkin — 1 cup cubed
  'v28': (15, null),   // Spring Onion — 1 stalk

  // ─── Nuts & Seeds (n*) ────────────────────────────────
  'n1': (1.2, 28),     // Almond — 1 nut / 1 handful (1 oz)
  'n2': (4, 28),       // Walnut — 1 half / handful
  'n3': (null, 28),    // Peanuts — handful
  'n4': (0.7, 30),     // Pistachio — 1 nut / handful
  'n5': (1.5, 28),     // Cashew — 1 nut / handful
  'n6': (null, 30),    // Sunflower Seeds — handful
  'n7': (null, 12),    // Chia Seeds — 1 tbsp
  'n8': (null, 10),    // Flaxseed — 1 tbsp
  'n9': (1, 28),       // Hazelnut — 1 nut / handful
  'n10': (2, 28),      // Macadamia — 1 nut / handful
  'n11': (null, 30),   // Pumpkin Seeds — handful
  'n12': (null, 28),   // Pine Nuts — handful

  // ─── Legumes (l*) ─────────────────────────────────────
  'l1': (null, 164),   // Chickpeas cooked — 1 cup
  'l2': (null, 172),   // Black Beans cooked
  'l3': (null, 198),   // Red Lentils cooked
  'l4': (null, 145),   // Green Peas
  'l5': (null, 177),   // Kidney Beans
  'l6': (null, 180),   // White Beans
  'l7': (null, 198),   // Green Lentils
  'l8': (null, 172),   // Soybeans cooked
  'l9': (null, 170),   // Broad Beans (fava)
  'l10': (null, 200),  // Mung Beans cooked

  // ─── International (i*) ───────────────────────────────
  'i1': (100, null),   // Pizza Margherita — 1 slice
  'i2': (250, null),   // Cheeseburger
  'i3': (null, 117),   // French Fries — medium portion
  'i4': (100, null),   // Fried Chicken — 1 piece
  'i5': (30, null),    // Sushi — 1 roll piece
  'i6': (null, 300),   // Pad Thai — 1 plate
  'i7': (null, 200),   // Caesar Salad
  'i8': (null, 248),   // Lentil Soup — 1 cup
  'i9': (80, null),    // Pancake — 1 piece
  'i10': (null, 300),  // Pasta Bolognese
  'i11': (100, null),  // Taco beef — 1
  'i12': (60, null),   // Spring Roll
  'i13': (null, 280),  // Fish & Chips plate
  'i14': (null, 400),  // Ramen bowl
  'i15': (null, 350),  // Butter Chicken
  'i16': (null, 350),  // Indian Biryani
  'i17': (250, null),  // Doner Kebab — 1 wrap
  'i18': (230, null),  // Gyro — 1 wrap
  'i19': (null, 300),  // Chicken Shawarma Plate
  'i20': (16, null),   // Chicken Nugget — 1 piece

  // ─── Beverages (b*) ───────────────────────────────────
  'b1': (null, 240),   // Black Coffee — 1 cup
  'b2': (null, 240),   // Black Tea
  'b3': (null, 240),   // Orange Juice
  'b4': (null, 330),   // Coca-Cola — 1 can
  'b5': (null, 240),   // Green Tea
  'b6': (null, 240),   // Apple Juice
  'b7': (null, 240),   // Lemonade
  'b8': (null, 240),   // Pomegranate Juice
  'b9': (null, 240),   // Hot Chocolate
  'b10': (null, 240),  // Chai Tea
  'b11': (null, 240),  // Ayran
  'b12': (null, 70),   // Turkish Coffee — 1 cup (small)
  'b13': (null, 240),  // Jallab

  // ─── Snacks & Sweets (s*) ─────────────────────────────
  's1': (5, null),     // Dark Chocolate — 1 square
  's2': (21, null),    // Honey — 1 tbsp
  's3': (16, null),    // Peanut Butter — 1 tbsp
  's4': (35, null),    // Granola Bar
  's5': (null, 10),    // Popcorn — 1 cup popped
  's6': (35, null),    // Baklava — 1 piece
  's7': (9, null),     // Rice Cake — 1 cake
  's8': (5, null),     // Milk Chocolate — 1 square
  's9': (null, 132),   // Ice Cream — 1 scoop bowl
  's10': (50, null),   // Protein Bar
  's11': (25, null),   // Energy Ball
  's12': (8, 30),      // Dried Apricot — 1 / handful
  's13': (null, 28),   // Trail Mix — 1 handful
  's14': (10, null),   // Turkish Delight — 1 piece
  's15': (30, null),   // Halva — 1 slice
  's16': (50, null),   // Znoud el Sit — 1 piece
  's17': (60, null),   // Qatayef — 1 piece

  // ─── Oils & Fats (o*) ─────────────────────────────────
  'o1': (14, null),    // Olive Oil — 1 tbsp
  'o2': (14, null),    // Coconut Oil — 1 tbsp
  'o3': (15, null),    // Tahini — 1 tbsp
  'o4': (14, null),    // Ghee — 1 tbsp
  'o5': (14, null),    // Sesame Oil — 1 tbsp

  // ─── Protein supplements (sup_*) — scoop = 1 piece ──
  'sup_on_gold_whey': (30.4, null),
  'sup_whey_concentrate': (30, null),
  'sup_whey_isolate': (30, null),
  'sup_mass_gainer': (165, null),
  'sup_casein': (33, null),
  'sup_plant_protein': (35, null),

  // ─── Fast food (ff_*) — typical item weights (g) ────
  'ff_big_mac': (219, null),
  'ff_quarter_pounder': (211, null),
  'ff_mcdouble': (155, null),
  'ff_hamburger': (105, null),
  'ff_cheeseburger_mcd': (119, null),
  'ff_mcchicken': (167, null),
  'ff_filet_o_fish': (141, null),
  'ff_mcnuggets': (16, null),
  'ff_mcfries_medium': (117, null),
  'ff_apple_pie_mcd': (77, null),
  'ff_whopper': (291, null),
  'ff_whopper_jr': (198, null),
  'ff_chicken_royale': (198, null),
  'ff_kfc_breast': (161, null),
  'ff_kfc_thigh': (149, null),
  'ff_kfc_tenders': (45, null),
  'ff_kfc_fries': (125, null),
  'ff_pepperoni_pizza': (113, null),
  'ff_cheese_pizza': (107, null),
  'ff_margherita_pizza_ff': (100, null),
  'ff_crunchy_taco': (78, null),
  'ff_burrito_beef': (248, null),
  'ff_nachos_cheese': (175, null),
  'ff_quesadilla_chicken': (180, null),
  'ff_sub_turkey': (219, null),
  'ff_sub_chicken': (219, null),
  'ff_club_sandwich': (200, null),
  'ff_fried_chicken_wing': (40, null),
  'ff_onion_rings': (85, null),
  'ff_mozzarella_sticks': (28, null),
  'ff_corn_dog': (75, null),
  'ff_hot_dog': (100, null),
  'ff_sausage_mcmuffin': (117, null),
  'ff_egg_mcmuffin': (134, null),
  'ff_hash_browns': (53, null),
  'ff_chocolate_shake': (400, null),
  'ff_soft_serve': (90, null),
  'ff_churros': (35, null),
  'ff_shawarma_wrap': (250, null),
  'ff_falafel_wrap_ff': (200, null),
  'ff_zinger_burger': (200, null),
};
