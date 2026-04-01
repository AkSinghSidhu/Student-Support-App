# Student Support UI - Design System

> **Note:** Since the Stitch MCP server did not return the project, this layout, color palette, and typography system has been successfully extracted directly from the app's internal Flutter architecture (`app_colors.dart` and `app_theme.dart`).

---

## 🎨 Color Palette

### Primary Colors
* **Primary Dark Blue:** `#020065`
* **Primary Gold:** `#FDC50C`
* **Primary Black:** `#000000`
* **Primary White:** `#FFFFFF`

### Surface & Backgrounds
* **Light Surface:** `#F8F9FA`
* **Dark Surface:** `#1A1A2E`
* **Light Card Background:** `#FFFFFF`
* **Dark Card Background:** `#262640`

### Gradients
* **Primary Backdrop Gradient:** Deep Blue (`#020065`) → Midnight Blue (`#010033`) → Black (`#000000`)
* **Radiant Gold Gradient:** Bright Gold (`#FFD700`) → Primary Gold (`#FDC50C`) → Dark Gold (`#E5A800`)

### Semantic / Status Colors
* **Success:** `#10B981` (Green)
* **Warning:** `#F59E0B` (Amber)
* **Error:** `#EF4444` (Red)
* **Info:** `#3B82F6` (Blue)

### Feature / Interactive Colors
* **Notices Tab:** `#6366F1` (Indigo)
* **Attendance System:** `#F97316` (Orange)
* **Resources Module:** `#10B981` (Teal/Green)
* **Syllabus Module:** `#06B6D4` (Cyan)
* **Feedback Portal:** `#8B5CF6` (Purple)
* **Complaints Portal:** `#EC4899` (Pink)

---

## 🖋️ Typography

* **Font Family:** `Roboto` (Default configuration across application).
* **App Bar Headings:** 18px | Semi-Bold (w600) | 0.5 Letter Spacing
* **Buttons:** 14px | Semi-Bold (w600) | 0.5 Letter Spacing
* **Tab Labels (Notices/History):** 13px | Semi-Bold (w600)
* **ListTile Main Text:** 14px | Semi-Bold (w600)
* **ListTile Subtext:** 12px | Regular
* **Drawer Section Headers:** 11px | Semi-Bold | 1.2 Letter Spacing

---

## 📏 Layout & Shape Components

* **Card Roundness:** `16px` circular borders
* **Modal / Drawer Roundness:** `14px` and `16px` combinations
* **Buttons & TextFields:** `12px` circular borders with absolute zero elevation (`elevation: 0`)
* **Button Target Areas:** padded `24px` horizontally, `14px` vertically
* **Text Field Behavior:** Filled input fields utilizing Dark Blue with `5%` opacity

---

## 🛠️ Required Architecture & Design Improvements

Based on a deep-dive scan of all files in this project repository, here is the list of improvements that must be addressed to enforce full Design System compliance:

1. **Remove Hardcoded UI Colors:** Multiple core components (such as `loading_overlay.dart`, `app_drawer.dart`, and `login_page.dart`) have raw `Colors.white`, `Colors.amber`, or hard-typed hex codes (`Color(0xFF6366F1)`). **Fix:** Convert every literal color definition exclusively to `AppColors` references.
2. **Standardize Typography Themes:** Right now, nearly all font styling is injected randomly via inline `TextStyle(...)` arguments across the app. **Fix:** Move all TextStyles into `AppTheme.dart` to rely on `Theme.of(context).textTheme` allowing dynamic scale and easy centralized adjustments.
3. **Establish Spatial "Design Tokens":** Instead of using static numerical offsets (like `SizedBox(height: 16)` or `EdgeInsets.all(20)`), the project needs spacing configurations like `AppSpacing.md` and `AppSpacing.lg`.
4. **Implement `ColorScheme` Contexts:** A significant number of widgets toggle UI states using inline ternary operations (`isDarkMode ? AppColors.dark : AppColors.light`). **Fix:** Leverage the material `colorScheme` attributes directly inside `Theme.of(context).colorScheme.surface` to inherently react to mode switches without manual overrides.
5. **Extract User-Facing Hardcoded Strings:** Hundreds of static string declarations including "Login Failed", "Log Out", and "Profile Page Coming Soon" currently exist in raw `Text('')` widgets instead of unified lookup tables. **Fix:** Move static strings into an `AppConstants` map or implement an i18n lookup framework.
