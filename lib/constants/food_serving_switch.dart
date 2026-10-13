import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/constants/bakery_foods_list.dart';
import 'package:nutrify/constants/core_food_serving_overrides.dart';
import 'package:nutrify/constants/food_database.dart';
import 'package:nutrify/constants/kurdish_beverages_user.dart';
import 'package:nutrify/constants/kurdish_foods_user.dart';
import 'package:nutrify/constants/kurdish_plates_snacks_user.dart';
import 'package:nutrify/constants/kurdish_sweets_fried_user.dart';
import 'package:nutrify/constants/shla_foods_list.dart';

/// Grams / piece / bowl in the food log sheet.
enum FoodServingMode { grams, piece, bowl }

/// Maps Kurdish (and paired) [FoodItem.id]s so switching mode uses the correct row
/// (e.g. fish 100g vs fish 1 piece — different protein per serving in your data).
const Map<String, String> _kurdishIdToGramsCanonical = {
  // Piece / chunk / skewer / slice → 100g row
  'kuu_kebab_1pc': 'kuu_kebab_100g',
  'kuu_shish_gosht_1pc': 'kuu_shish_gosht_100g',
  'kuu_meat_tikka_chunk_1': 'kuu_shish_gosht_100g',
  'kuu_chicken_breast_skewer_1': 'kuu_shish_sing_100g',
  'kuu_chicken_breast_piece_1': 'kuu_shish_sing_100g',
  'kuu_fish_tikka_1pc': 'kuu_fish_tikka_100g',
  'kuu_shrimp_tikka_1pc': 'kuu_shrimp_tikka_100g',
  'kuu_chicken_kebab_1pc': 'kuu_chicken_kebab_100g',
  'kuu_kebab_bread_1pc': 'kuu_kebab_bread_100g',
  'kuu_qara_plain_bowl': 'kuu_qara_plain_100g',
  'kuu_qara_meat_bowl': 'kuu_qara_meat_100g',
  'kuu_fried_eggplant_1pc': 'kuu_fried_eggplant_100g',
  'kuu_rice_kurdish_oil_bowl': 'kuu_rice_kurdish_oil_100g',
  'kuu_rice_kurdish_oil_spoon': 'kuu_rice_kurdish_oil_100g',
  'kuu_rice_kurdish_no_oil_bowl': 'kuu_rice_kurdish_no_oil_100g',
  'kuu_rice_kurdish_no_oil_spoon': 'kuu_rice_kurdish_no_oil_100g',
  'kuu_rice_red_bowl': 'kuu_rice_red_100g',
  'kuu_rice_red_spoon': 'kuu_rice_red_100g',
  'kuu_rice_white_precooked_large': 'kuu_rice_white_precooked_100g',
  'kuu_rice_white_precooked_fistful': 'kuu_rice_white_precooked_100g',
  'kuu_rice_white_bowl': 'kuu_rice_white_no_oil_100g',
  'kuu_rice_white_no_oil_spoon': 'kuu_rice_white_no_oil_100g',
  'kuu_rice_yellow_bowl': 'kuu_rice_yellow_100g',
  'kuu_rice_yellow_spoon': 'kuu_rice_yellow_100g',
  'kuu_rice_brown_bowl': 'kuu_rice_brown_100g',
  'kuu_rice_brown_spoon': 'kuu_rice_brown_100g',
  'kuu_rice_mung_bowl': 'kuu_rice_mung_100g',
  'kuu_rice_mung_spoon': 'kuu_rice_mung_100g',
  'kuu_rice_kurdish_precooked_cup': 'kuu_rice_kurdish_precooked_100g',
  'kuu_rice_kurdish_precooked_fistful': 'kuu_rice_kurdish_precooked_100g',
  'kuu_rice_white_oil_bowl': 'kuu_rice_white_oil_100g',
  'kuu_rice_white_oil_spoon': 'kuu_rice_white_oil_100g',
  'kuu_quozi_bowl': 'kuu_quozi_100g',
  'kuu_quozi_spoon': 'kuu_quozi_100g',
  'kuu_quozi_sham_bowl': 'kuu_quozi_sham_100g',
  'kuu_tarkhina_bowl': 'kuu_tarkhina_100g',
  'kuu_cream_rice_bowl': 'kuu_cream_rice_100g',
  'kuu_cream_rice_spoon': 'kuu_cream_rice_100g',
  'kuu_lamb_boiled_bowl': 'kuu_boiled_lamb_100g',
  // Quzi chicken
  'kuu_quozi_chicken_bowl': 'kuu_quozi_chicken_100g',
  'kuu_quozi_chicken_spoon': 'kuu_quozi_chicken_100g',
  // Paqla (broad beans)
  'kuu_paqla_spoon': 'kuu_paqla_raw_no_oil_100g',
  'kuu_paqla_bowl': 'kuu_paqla_raw_no_oil_100g',
  'kuu_paqla_piece': 'kuu_paqla_raw_no_oil_100g',
  // Shla (soup): bowl / spoon / piece → 100g row
  'shl_qaysi_bowl': 'shl_qaysi_100g',
  'shl_qaysi_spoon': 'shl_qaysi_100g',
  'shl_fasolia_bowl': 'shl_fasolia_100g',
  'shl_fasolia_spoon': 'shl_fasolia_100g',
  'shl_loobia_bowl': 'shl_loobia_100g',
  'shl_loobia_spoon': 'shl_loobia_100g',
  'shl_paqla_bowl': 'shl_paqla_100g',
  'shl_spinach_rice_bowl': 'shl_spinach_rice_100g',
  'shl_germ_kotaw_bowl': 'shl_germ_kotaw_100g',
  'shl_germ_kotaw_spoon': 'shl_germ_kotaw_100g',
  'shl_kolk_kurdi_bowl': 'shl_kolk_kurdi_100g',
  'shl_kolk_kurdi_spoon': 'shl_kolk_kurdi_100g',
  'shl_potato_bowl': 'shl_potato_100g',
  'shl_potato_spoon': 'shl_potato_100g',
  'shl_mash_bowl': 'shl_mash_100g',
  'shl_mash_spoon': 'shl_mash_100g',
  'shl_fish_broth_bowl': 'shl_fish_broth_100g',
  'shl_fish_broth_spoon': 'shl_fish_broth_100g',
  'shl_chicken_soup_bowl': 'shl_chicken_soup_100g',
  'shl_chicken_soup_spoon': 'shl_chicken_soup_100g',
  'shl_savar_chicken_bowl': 'shl_savar_chicken_100g',
  'shl_eggplant_bowl': 'shl_eggplant_100g',
  'shl_eggplant_spoon': 'shl_eggplant_100g',
  'shl_okra_meat_bowl': 'shl_okra_meat_100g',
  'shl_onion_soup_bowl': 'shl_onion_soup_100g',
  'shl_okra_bowl': 'shl_okra_100g',
  'shl_okra_spoon': 'shl_okra_100g',
  'shl_savar_meat_bowl': 'shl_savar_meat_100g',
  'shl_kufta_rice_bowl': 'shl_kufta_rice_100g',
  'shl_vegetable_bowl': 'shl_vegetable_100g',
  'shl_rice_yogurt_bowl': 'shl_rice_yogurt_100g',
  'shl_rice_yogurt_spoon': 'shl_rice_yogurt_100g',
  'shl_lentil_bowl': 'shl_lentil_100g',
  'shl_spinach_bowl': 'shl_spinach_100g',
  'shl_spinach_spoon': 'shl_spinach_100g',
  'shl_mushroom_bowl': 'shl_mushroom_100g',
  'shl_chicken_broccoli_bowl': 'shl_chicken_broccoli_100g',
  'shl_kufta_meat_1pc': 'shl_kufta_meat_100g',
  // Milks / drinks (cup = bowl mode only; bottle/glass rows map to canonical for old logs)
  'kuu_mlk_cow_ff_cup': 'kuu_mlk_cow_ff_100ml',
  'kuu_mlk_buffalo_cup': 'kuu_mlk_buffalo_100g',
  'kuu_mlk_goat_cup': 'kuu_mlk_goat_100g',
  'kuu_mlk_oat_cup': 'kuu_mlk_oat_100g',
  'kuu_mlk_walnut_full_cup': 'kuu_mlk_walnut_full_100g',
  'kuu_mlk_skim_cup': 'kuu_mlk_skim_100ml',
  'kuu_mlk_strawberry_cream_cup': 'kuu_mlk_strawberry_cream_100g',
  'kuu_mlk_strawberry_cup': 'kuu_mlk_strawberry_100g',
  'kuu_mlk_sheep_cup': 'kuu_mlk_sheep_100g',
  'kuu_mlk_almond_plain_cup': 'kuu_mlk_almond_plain_100ml',
  'kuu_mlk_chocolate_ff_cup': 'kuu_mlk_chocolate_ff_100g',
  'kuu_mlk_oat_sweet_cup': 'kuu_mlk_oat_sweet_100ml',
  'kuu_mlk_melon_seed_cup': 'kuu_mlk_melon_seed_100ml',
  'kuu_mlk_fatfree_cup': 'kuu_mlk_fatfree_100g',
  'kuu_mlk_whole_ff_cup': 'kuu_mlk_whole_ff_100ml',
  'kuu_mlk_walnut_sweet_cup': 'kuu_mlk_walnut_sweet_100ml',
  'kuu_mlk_banana_cup': 'kuu_mlk_banana_100ml',
  'kuu_mlk_almond_sweet_cup': 'kuu_mlk_almond_sweet_100ml',
  'kuu_mlk_chocolate_lf_cup': 'kuu_mlk_chocolate_lf_100g',
  'kuu_mlk_dry_powder_cup': 'kuu_mlk_dry_powder_100g',
  'kuu_srb_banana_cup': 'kuu_srb_banana_100g',
  'kuu_srb_banana_1pc': 'kuu_srb_banana_100g',
  'kuu_srb_melon_seed_cup': 'kuu_srb_melon_seed_100g',
  'kuu_srb_melon_seed_1pc': 'kuu_srb_melon_seed_100g',
  'kuu_srb_chocolate_cup': 'kuu_srb_chocolate_100g',
  'kuu_srb_chocolate_1pc': 'kuu_srb_chocolate_100g',
  'kuu_srb_date_cup': 'kuu_srb_date_100ml',
  'kuu_srb_protein_cup': 'kuu_srb_protein_100g',
  'kuu_srb_protein_1pc': 'kuu_srb_protein_100g',
  'kuu_tea_milk_glass': 'kuu_tea_milk_100ml',
  'kuu_milk_oreo_cup': 'kuu_milk_oreo_100g',
  'kuu_milk_oreo_1pc': 'kuu_milk_oreo_100g',
  'kuu_snk_icecream_soft_spoon': 'kuu_snk_icecream_soft_100g',
  // Wraps / pasta bowls / pastries
  'kuu_plt_wrap_chicken_1pc': 'kuu_plt_wrap_chicken_100g',
  'kuu_plt_wrap_lamb_1pc': 'kuu_plt_wrap_lamb_100g',
  'kuu_plt_wrap_beef_cu_1pc': 'kuu_plt_wrap_beef_cu_100g',
  'kuu_plt_wrap_chicken_liver_1pc': 'kuu_plt_wrap_chicken_liver_100g',
  'kuu_plt_wrap_broadbean_1pc': 'kuu_plt_wrap_broadbean_100g',
  'kuu_plt_wrap_chicken_sdw_1pc': 'kuu_plt_wrap_chicken_sdw_100g',
  'kuu_plt_wrap_mayonnaise_1pc': 'kuu_plt_wrap_mayonnaise_100g',
  'kuu_plt_wrap_hotdog_1pc': 'kuu_plt_wrap_hotdog_100g',
  'kuu_plt_wrap_grilled_fish_1pc': 'kuu_plt_wrap_grilled_fish_bread_100g',
  'kuu_plt_wrap_sesame_chicken_1pc': 'kuu_plt_wrap_sesame_chicken_100g',
  'kuu_plt_wrap_falafel_1pc': 'kuu_plt_wrap_falafel_100g',
  'kuu_plt_wrap_goat_semoun_1pc': 'kuu_plt_wrap_goat_semoun_100g',
  'kuu_plt_wrap_sesame_meat_1pc': 'kuu_plt_wrap_sesame_meat_100g',
  'kuu_plt_wrap_chick_semoun_1pc': 'kuu_plt_wrap_chick_semoun_100g',
  'kuu_plt_sushi_roll_1pc': 'kuu_plt_sushi_salmon_roll_100g',
  'kuu_plt_mkhala_pot_bowl': 'kuu_plt_mkhala_pot_100g',
  'kuu_plt_pasta_bowl': 'kuu_plt_pasta_100g',
  'kuu_plt_pasta_plain_bowl': 'kuu_plt_pasta_plain_100g',
  'kuu_plt_pasta_chicken_bowl': 'kuu_plt_pasta_chicken_100g',
  'kuu_plt_pasta_alfredo_bowl': 'kuu_plt_pasta_alfredo_100g',
  'kuu_plt_pasta_meat_bowl': 'kuu_plt_pasta_meat_100g',
  'kuu_plt_mak_simple_bowl': 'kuu_plt_mak_simple_100g',
  'kuu_snk_bak_walnut_1pc': 'kuu_snk_bak_walnut_100g',
  'kuu_snk_bak_turkish_1pc': 'kuu_snk_bak_turkish_100g',
  'kuu_snk_bak_strawberry_1pc': 'kuu_snk_bak_strawberry_100g',
  'kuu_snk_bak_sha_riya_1pc': 'kuu_snk_bak_sha_riya_100g',
  'kuu_snk_bourma_1pc': 'kuu_snk_bourma_100g',
  'kuu_snk_icecream_ball_1pc': 'kuu_snk_icecream_ball_100g',
  'kuu_snk_icecream88_strawberry_1pc': 'kuu_snk_icecream88_strawberry_100g',
  // Bakery: piece / slice row → canonical per-100g row (bf01…bf26)
  'bf01_pc': 'bf01',
  'bf02_pc': 'bf02',
  'bf03_pc': 'bf03',
  'bf04_pc': 'bf04',
  'bf05_pc': 'bf05',
  'bf06_pc': 'bf06',
  'bf07_pc': 'bf07',
  'bf08_pc': 'bf08',
  'bf09_pc': 'bf09',
  'bf10_sc': 'bf10',
  'bf11_pc': 'bf11',
  'bf12_pc': 'bf12',
  'bf13_pc': 'bf13',
  'bf14_pc': 'bf14',
  'bf15_pc': 'bf15',
  'bf16_pc': 'bf16',
  'bf17_pc': 'bf17',
  'bf18_pc': 'bf18',
  'bf19_pc': 'bf19',
  'bf20_pc': 'bf20',
  'bf21_pc': 'bf21',
  'bf22_pc': 'bf22',
  'bf23_pc': 'bf23',
  'bf24_pc': 'bf24',
  'bf25_pc': 'bf25',
  'bf26_pc': 'bf26',
};

/// From canonical **100g** id → **one piece** row (skewer for chicken breast).
const Map<String, String> _gramsToPieceId = {
  'kuu_kebab_100g': 'kuu_kebab_1pc',
  'kuu_shish_gosht_100g': 'kuu_shish_gosht_1pc',
  'kuu_shish_sing_100g': 'kuu_chicken_breast_skewer_1',
  'kuu_fish_tikka_100g': 'kuu_fish_tikka_1pc',
  'kuu_shrimp_tikka_100g': 'kuu_shrimp_tikka_1pc',
  'kuu_chicken_kebab_100g': 'kuu_chicken_kebab_1pc',
  'kuu_kebab_bread_100g': 'kuu_kebab_bread_1pc',
  'kuu_fried_eggplant_100g': 'kuu_fried_eggplant_1pc',
  'shl_kufta_meat_100g': 'shl_kufta_meat_1pc',
  // Wrap / sandwich servings (drinks: no piece mode — use g/ml or cup)
  'kuu_plt_wrap_chicken_100g': 'kuu_plt_wrap_chicken_1pc',
  'kuu_plt_wrap_lamb_100g': 'kuu_plt_wrap_lamb_1pc',
  'kuu_plt_wrap_beef_cu_100g': 'kuu_plt_wrap_beef_cu_1pc',
  'kuu_plt_wrap_chicken_liver_100g': 'kuu_plt_wrap_chicken_liver_1pc',
  'kuu_plt_wrap_broadbean_100g': 'kuu_plt_wrap_broadbean_1pc',
  'kuu_paqla_raw_no_oil_100g': 'kuu_paqla_piece',
  'kuu_paqla_raw_with_oil_100g': 'kuu_paqla_piece',
  'kuu_paqla_boiled_no_oil_100g': 'kuu_paqla_piece',
  'kuu_paqla_boiled_with_oil_100g': 'kuu_paqla_piece',
  'kuu_plt_wrap_chicken_sdw_100g': 'kuu_plt_wrap_chicken_sdw_1pc',
  'kuu_plt_wrap_mayonnaise_100g': 'kuu_plt_wrap_mayonnaise_1pc',
  'kuu_plt_wrap_hotdog_100g': 'kuu_plt_wrap_hotdog_1pc',
  'kuu_plt_wrap_grilled_fish_bread_100g': 'kuu_plt_wrap_grilled_fish_1pc',
  'kuu_plt_wrap_sesame_chicken_100g': 'kuu_plt_wrap_sesame_chicken_1pc',
  'kuu_plt_wrap_falafel_100g': 'kuu_plt_wrap_falafel_1pc',
  'kuu_plt_wrap_goat_semoun_100g': 'kuu_plt_wrap_goat_semoun_1pc',
  'kuu_plt_wrap_sesame_meat_100g': 'kuu_plt_wrap_sesame_meat_1pc',
  'kuu_plt_wrap_chick_semoun_100g': 'kuu_plt_wrap_chick_semoun_1pc',
  'kuu_plt_sushi_salmon_roll_100g': 'kuu_plt_sushi_roll_1pc',
  'kuu_snk_bak_walnut_100g': 'kuu_snk_bak_walnut_1pc',
  'kuu_snk_bak_turkish_100g': 'kuu_snk_bak_turkish_1pc',
  'kuu_snk_bak_strawberry_100g': 'kuu_snk_bak_strawberry_1pc',
  'kuu_snk_bak_sha_riya_100g': 'kuu_snk_bak_sha_riya_1pc',
  'kuu_snk_bourma_100g': 'kuu_snk_bourma_1pc',
  'kuu_snk_icecream_ball_100g': 'kuu_snk_icecream_ball_1pc',
  'kuu_snk_icecream88_strawberry_100g': 'kuu_snk_icecream88_strawberry_1pc',
  // Bakery (single list entry; piece / slice via mode switch)
  'bf01': 'bf01_pc',
  'bf02': 'bf02_pc',
  'bf03': 'bf03_pc',
  'bf04': 'bf04_pc',
  'bf05': 'bf05_pc',
  'bf06': 'bf06_pc',
  'bf07': 'bf07_pc',
  'bf08': 'bf08_pc',
  'bf09': 'bf09_pc',
  'bf10': 'bf10_sc',
  'bf11': 'bf11_pc',
  'bf12': 'bf12_pc',
  'bf13': 'bf13_pc',
  'bf14': 'bf14_pc',
  'bf15': 'bf15_pc',
  'bf16': 'bf16_pc',
  'bf17': 'bf17_pc',
  'bf18': 'bf18_pc',
  'bf19': 'bf19_pc',
  'bf20': 'bf20_pc',
  'bf21': 'bf21_pc',
  'bf22': 'bf22_pc',
  'bf23': 'bf23_pc',
  'bf24': 'bf24_pc',
  'bf25': 'bf25_pc',
  'bf26': 'bf26_pc',
};

/// From canonical **100g** id → **one bowl** row (or large plate / cup where that is the main “big” serving).
const Map<String, String> _gramsToBowlId = {
  'kuu_qara_plain_100g': 'kuu_qara_plain_bowl',
  'kuu_qara_meat_100g': 'kuu_qara_meat_bowl',
  'kuu_rice_kurdish_oil_100g': 'kuu_rice_kurdish_oil_bowl',
  'kuu_rice_kurdish_no_oil_100g': 'kuu_rice_kurdish_no_oil_bowl',
  'kuu_rice_red_100g': 'kuu_rice_red_bowl',
  'kuu_rice_white_precooked_100g': 'kuu_rice_white_precooked_large',
  'kuu_rice_white_no_oil_100g': 'kuu_rice_white_bowl',
  'kuu_rice_yellow_100g': 'kuu_rice_yellow_bowl',
  'kuu_rice_brown_100g': 'kuu_rice_brown_bowl',
  'kuu_rice_mung_100g': 'kuu_rice_mung_bowl',
  'kuu_rice_kurdish_precooked_100g': 'kuu_rice_kurdish_precooked_cup',
  'kuu_rice_white_oil_100g': 'kuu_rice_white_oil_bowl',
  'kuu_quozi_100g': 'kuu_quozi_bowl',
  'kuu_quozi_chicken_100g': 'kuu_quozi_chicken_bowl',
  'kuu_quozi_sham_100g': 'kuu_quozi_sham_bowl',
  'kuu_tarkhina_100g': 'kuu_tarkhina_bowl',
  'kuu_cream_rice_100g': 'kuu_cream_rice_bowl',
  'kuu_boiled_lamb_100g': 'kuu_lamb_boiled_bowl',
  'shl_qaysi_100g': 'shl_qaysi_bowl',
  'shl_fasolia_100g': 'shl_fasolia_bowl',
  'shl_loobia_100g': 'shl_loobia_bowl',
  'kuu_paqla_raw_no_oil_100g': 'kuu_paqla_bowl',
  'kuu_paqla_raw_with_oil_100g': 'kuu_paqla_bowl',
  'kuu_paqla_boiled_no_oil_100g': 'kuu_paqla_bowl',
  'kuu_paqla_boiled_with_oil_100g': 'kuu_paqla_bowl',
  'shl_paqla_100g': 'shl_paqla_bowl',
  'shl_spinach_rice_100g': 'shl_spinach_rice_bowl',
  'shl_germ_kotaw_100g': 'shl_germ_kotaw_bowl',
  'shl_kolk_kurdi_100g': 'shl_kolk_kurdi_bowl',
  'shl_potato_100g': 'shl_potato_bowl',
  'shl_mash_100g': 'shl_mash_bowl',
  'shl_fish_broth_100g': 'shl_fish_broth_bowl',
  'shl_chicken_soup_100g': 'shl_chicken_soup_bowl',
  'shl_savar_chicken_100g': 'shl_savar_chicken_bowl',
  'shl_eggplant_100g': 'shl_eggplant_bowl',
  'shl_okra_meat_100g': 'shl_okra_meat_bowl',
  'shl_onion_soup_100g': 'shl_onion_soup_bowl',
  'shl_okra_100g': 'shl_okra_bowl',
  'shl_savar_meat_100g': 'shl_savar_meat_bowl',
  'shl_kufta_rice_100g': 'shl_kufta_rice_bowl',
  'shl_vegetable_100g': 'shl_vegetable_bowl',
  'shl_rice_yogurt_100g': 'shl_rice_yogurt_bowl',
  'shl_lentil_100g': 'shl_lentil_bowl',
  'shl_spinach_100g': 'shl_spinach_bowl',
  'shl_mushroom_100g': 'shl_mushroom_bowl',
  'shl_chicken_broccoli_100g': 'shl_chicken_broccoli_bowl',
  // Milks & drinks (cup = “bowl” mode)
  'kuu_mlk_cow_ff_100ml': 'kuu_mlk_cow_ff_cup',
  'kuu_mlk_buffalo_100g': 'kuu_mlk_buffalo_cup',
  'kuu_mlk_goat_100g': 'kuu_mlk_goat_cup',
  'kuu_mlk_oat_100g': 'kuu_mlk_oat_cup',
  'kuu_mlk_walnut_full_100g': 'kuu_mlk_walnut_full_cup',
  'kuu_mlk_skim_100ml': 'kuu_mlk_skim_cup',
  'kuu_mlk_strawberry_cream_100g': 'kuu_mlk_strawberry_cream_cup',
  'kuu_mlk_strawberry_100g': 'kuu_mlk_strawberry_cup',
  'kuu_mlk_sheep_100g': 'kuu_mlk_sheep_cup',
  'kuu_mlk_almond_plain_100ml': 'kuu_mlk_almond_plain_cup',
  'kuu_mlk_chocolate_ff_100g': 'kuu_mlk_chocolate_ff_cup',
  'kuu_mlk_oat_sweet_100ml': 'kuu_mlk_oat_sweet_cup',
  'kuu_mlk_melon_seed_100ml': 'kuu_mlk_melon_seed_cup',
  'kuu_mlk_fatfree_100g': 'kuu_mlk_fatfree_cup',
  'kuu_mlk_whole_ff_100ml': 'kuu_mlk_whole_ff_cup',
  'kuu_mlk_walnut_sweet_100ml': 'kuu_mlk_walnut_sweet_cup',
  'kuu_mlk_banana_100ml': 'kuu_mlk_banana_cup',
  'kuu_mlk_almond_sweet_100ml': 'kuu_mlk_almond_sweet_cup',
  'kuu_mlk_chocolate_lf_100g': 'kuu_mlk_chocolate_lf_cup',
  'kuu_mlk_dry_powder_100g': 'kuu_mlk_dry_powder_cup',
  'kuu_srb_banana_100g': 'kuu_srb_banana_cup',
  'kuu_srb_melon_seed_100g': 'kuu_srb_melon_seed_cup',
  'kuu_srb_chocolate_100g': 'kuu_srb_chocolate_cup',
  'kuu_srb_date_100ml': 'kuu_srb_date_cup',
  'kuu_srb_protein_100g': 'kuu_srb_protein_cup',
  'kuu_milk_oreo_100g': 'kuu_milk_oreo_cup',
  // Plates
  'kuu_plt_mkhala_pot_100g': 'kuu_plt_mkhala_pot_bowl',
  'kuu_plt_pasta_100g': 'kuu_plt_pasta_bowl',
  'kuu_plt_pasta_plain_100g': 'kuu_plt_pasta_plain_bowl',
  'kuu_plt_pasta_chicken_100g': 'kuu_plt_pasta_chicken_bowl',
  'kuu_plt_pasta_alfredo_100g': 'kuu_plt_pasta_alfredo_bowl',
  'kuu_plt_pasta_meat_100g': 'kuu_plt_pasta_meat_bowl',
  'kuu_plt_mak_simple_100g': 'kuu_plt_mak_simple_bowl',
};

FoodItem? foodById(String id) {
  for (final f in foodDatabase) {
    if (f.id == id) return f;
  }
  for (final f in bakeryPieceServings) {
    if (f.id == id) return f;
  }
  for (final f in kurdishFoodServingVariants) {
    if (f.id == id) return f;
  }
  for (final f in kurdishBeverageFoodServingVariants) {
    if (f.id == id) return f;
  }
  for (final f in kurdishPlateSnackFoodServingVariants) {
    if (f.id == id) return f;
  }
  for (final f in kurdishSweetsFriedServingVariants) {
    if (f.id == id) return f;
  }
  for (final f in shlaFoodServingVariants) {
    if (f.id == id) return f;
  }
  return null;
}

/// Always use an instance from [foodDatabase] (avoids stale references after hot reload on web).
/// On web, [FoodItem] references can briefly be JS `null`; coalesce to a real row.
FoodItem _reload(FoodItem? f) {
  if (f == null) return foodDatabase.first;
  return foodById(f.id) ?? f;
}

/// Normalizes to the **100g** (or primary per-100g) row for this dish family.
FoodItem foodCanonicalGrams(FoodItem selected) {
  final s = _reload(selected);
  final id = _kurdishIdToGramsCanonical[s.id] ??
      kurdishSweetsFriedIdToGramsCanonical[s.id] ??
      s.id;
  return foodById(id) ?? s;
}

/// Resolves the effective per-piece weight (g) for [f], consulting first an
/// explicit field on the [FoodItem] then the global [coreFoodServingOverrides]
/// table. Returns `null` if the food has no piece mode.
double? _gramsPerPieceFor(FoodItem f) {
  if (f.gramsPerPiece != null) return f.gramsPerPiece;
  final ov = coreFoodServingOverrides[f.id];
  return ov?.$1;
}

/// Same as [_gramsPerPieceFor] but for bowl/cup serving.
double? _gramsPerBowlFor(FoodItem f) {
  if (f.gramsPerBowl != null) return f.gramsPerBowl;
  final ov = coreFoodServingOverrides[f.id];
  return ov?.$2;
}

/// [FoodItem] to use for macros and logging for the current mode.
FoodItem foodForServingMode(FoodItem selected, FoodServingMode mode) {
  final sel = _reload(selected);
  FoodItem out;
  switch (mode) {
    case FoodServingMode.grams:
      out = foodCanonicalGrams(sel);
      break;
    case FoodServingMode.piece:
      if (sel.id == 'kuu_chicken_breast_piece_1' ||
          sel.id == 'kuu_chicken_breast_skewer_1') {
        out = sel;
      } else {
        final g = foodCanonicalGrams(sel);
        // 1) Explicit Kurdish / bakery piece variant.
        final pid = _gramsToPieceId[g.id] ??
            kurdishSweetsFriedGramsToPieceId[g.id];
        if (pid != null) {
          out = foodById(pid) ?? sel;
        } else {
          // 2) Synthesized variant from FoodItem.gramsPerPiece or the
          // core override table — keeps the food list slim while still
          // giving every common food a sensible piece serving.
          final perPiece = _gramsPerPieceFor(g);
          if (perPiece != null) {
            out = g.asServingVariant(
              idSuffix: 'syn_pc',
              gramsPerUnit: perPiece,
            );
          } else {
            out = sel;
          }
        }
      }
      break;
    case FoodServingMode.bowl:
      final g = foodCanonicalGrams(sel);
      final bid = _gramsToBowlId[g.id] ??
          kurdishSweetsFriedGramsToBowlId[g.id];
      if (bid != null) {
        out = foodById(bid) ?? sel;
      } else {
        final perBowl = _gramsPerBowlFor(g);
        if (perBowl != null) {
          out = g.asServingVariant(
            idSuffix: 'syn_bw',
            gramsPerUnit: perBowl,
          );
        } else {
          out = sel;
        }
      }
      break;
  }
  return _reload(out);
}

/// Typical piece/scoop weight when the food has a core override entry.
double? defaultPieceGramsFor(FoodItem selected) =>
    _gramsPerPieceFor(foodCanonicalGrams(selected));

/// Fast food & supplements open in piece/scoop mode by default.
bool prefersPieceDefaultServing(FoodItem selected) {
  final g = foodCanonicalGrams(selected);
  if (g.category != 'FastFood' && g.category != 'Supplement') return false;
  return defaultPieceGramsFor(selected) != null;
}

/// Sensible gram default when opening the log sheet (scoop for powder, item weight for burgers).
double defaultGramAmountFor(FoodItem selected) {
  final g = foodCanonicalGrams(selected);
  final pieceG = defaultPieceGramsFor(selected);
  if (g.category == 'Supplement' && pieceG != null) return pieceG;
  if (g.category == 'FastFood' && pieceG != null) return pieceG;
  return g.nutritionReferenceG;
}

/// Calories shown in the browse list — one typical item when piece weight exists.
int browseDisplayCalories(FoodItem selected) {
  final g = foodCanonicalGrams(selected);
  final pieceG = defaultPieceGramsFor(selected);
  if (pieceG != null &&
      (g.category == 'FastFood' || g.category == 'Supplement')) {
    return (g.calories * pieceG / g.nutritionReferenceG).round();
  }
  return g.calories.round();
}

bool kurdishHasPieceMode(FoodItem selected) {
  final g = foodCanonicalGrams(selected);
  if (_gramsToPieceId.containsKey(g.id) ||
      kurdishSweetsFriedGramsToPieceId.containsKey(g.id)) {
    return true;
  }
  if (_gramsPerPieceFor(g) != null) return true;
  return false;
}

bool kurdishHasBowlMode(FoodItem selected) {
  final g = foodCanonicalGrams(selected);
  if (_gramsToBowlId.containsKey(g.id) ||
      kurdishSweetsFriedGramsToBowlId.containsKey(g.id)) {
    return true;
  }
  if (_gramsPerBowlFor(g) != null) return true;
  return false;
}

/// Bowl / spoon / piece / cup rows — hidden from food log search; use gram row + serving mode.
Set<String> get foodServingSizeVariantIds => {
  ..._kurdishIdToGramsCanonical.keys,
  ...kurdishSweetsFriedIdToGramsCanonical.keys,
};
