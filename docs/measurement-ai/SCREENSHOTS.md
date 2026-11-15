# Native screenshot evidence

The complete manifest records 306 captures from passing native runs. The full raw set remains locally under ignored `build/measurement-evidence/raw`; representative PNGs are committed here. Native integration runs use fictional offline application data and injected openly licensed food images, not live Gemini predictions.

- [Android rice / spoon](screenshots/pixel_verified_android_en_White-rice,-cooked_tablespoon.png)
- [Android Arabic milk / litres](screenshots/pixel_verified_android_ar_Whole-milk_liter.png)
- [Android Sorani pizza / dark](screenshots/pixel_verified_android_ku_usda_sr_170317_dark.png)
- [Android Arabic two-image review / dark](screenshots/pixel_verified_android_ar-photo-side-dark.png)
- [iPhone rice / spoon](screenshots/iphone_verified_ios_en_White-rice,-cooked_tablespoon.png)
- [iPhone Arabic milk / litres](screenshots/iphone_verified_ios_ar_Whole-milk_liter.png)
- [iPhone Sorani milk / dark](screenshots/iphone_verified_ios_ku_usda_sr_171265_dark.png)
- [iPhone Sorani two-image review](screenshots/iphone_verified_ios_ku-photo-side-light.png)
- [Android tablet-sized layout](screenshots/android_tablet_android_ku_usda_sr_170317_dark.png)
- [Small iPhone layout](screenshots/small_iphone_ios_ku_White-rice,-cooked_tablespoon.png)
- [Full-width iPad test layout](screenshots/ipad_full_ios_ku_usda_sr_170317_dark.png)
- [Native iOS system picker: one input](screenshots/iphone_native_picker_single.png)
- [Native iOS system picker: second input](screenshots/iphone_native_picker_two.png)
- [Native Android system picker: two inputs](screenshots/android_native_picker_two.png)

The native iOS picker screenshots contain a built-in iOS Simulator sample image selected only for local UI checks. The injected dolma fixture is by Hill93, [Wikimedia source](https://commons.wikimedia.org/wiki/File:Iraqi_Dolma.jpg), [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Source images and complete license metadata remain in the backend's `vercel-api/evaluation/` directory. No QA image was added to the production food catalog or ordinary food-list UI.

The two-image tests can reuse an input to verify UI mechanics; they do not establish a real paired-view portion-estimation result. See the report for simulator/physical-device and live-recognition limitations.
