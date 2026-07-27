# Implementation Plan: "The Obsidian Collection" Order History UI

This plan outlines the transformation of the Tipsy Theoryy Order History screen into a minimalist, luxury experience. The design moves away from generic, cluttered cards towards a "journal-like" aesthetic that feels exclusive and modern.

## 1. Design Philosophy
- **Obsidian Luxury**: Moving from pure black to a deep, matte charcoal palette.
- **Quiet Typography**: Pairing a sophisticated Serif (Playfair/Georgia) with a clean, geometric Sans-Serif (Inter/Montserrat).
- **Glass & Depth**: Using subtle borders and inner glows instead of heavy shadows.
- **Information Breathability**: Increasing padding and reducing visual noise.

## 2. Proposed Changes

### [Core UI Components]

#### [theme.dart](file:///C:/Users/PC/Desktop/tipsytheoryy_app/lib/core/theme.dart)
- Define new luxury constants:
    - `obsidianBlack`: `#0A0A0A` (Deepest background)
    - `matteCharcoal`: `#121212` (Card surfaces)
    - `champagneGold`: `#F7E7CE` (Status accents/Progress)
    - `silkGreen`: `#1B4D42` (Reorder button)

---

### [Order History Screen]

#### [orders_screen.dart](file:///C:/Users/PC/Desktop/tipsytheoryy_app/lib/screens/customer/orders_screen.dart)

**Header & Layout:**
- Change "My Orders" to "Your Journal" or "Order History" using a Serif font.
- Implement a floating header that fades as the user scrolls.

**Card Refactoring (_buildOrderCard):**
- **Shape**: Increase border radius to `28px` for a softer, organic feel.
- **Glassmorphism**: Remove card shadows. Add a `1px` border with `Colors.white.withOpacity(0.05)`.
- **Typography**:
    - Store name in a Serif font (or bold Sans-serif with tight tracking).
    - Metadata (Date, Total) in all-caps, light grey, with `1.0` letter spacing.
- **Status Indicator**: Replace blocky badges with a "Minimalist Dot" and a thin line at the bottom of the card (Champagne Gold for Active, Silk Green for Delivered).
- **Imagery**: Add a desaturated, rounded thumbnail of the first item in the order to provide visual context without clutter.

**Action Buttons:**
- Use "Text-Only" or "Icon-Only" primary actions until the user expands the card.
- "Reorder" button should be a slim, elegant pill with a muted silk-green background.

---

### [User Experience Enhancements]

- **Haptic Feedback**: Integrate `HapticFeedback.lightImpact()` on filter changes and card taps.
- **Skeleton Polish**: Update shimmering colors to match the Obsidian theme (deep charcoal base).

## 3. Verification Plan

### Automated Verification
- **Static Analysis**: Run `flutter analyze` to ensure no linting errors in new UI code.

### Manual Verification
- **Visual Audit**: Compare the implemented screen against the "Obsidian Collection" concept (screenshots in walkthrough).
- **Dark Mode Check**: Verify contrast ratios for `champagneGold` text on `matteCharcoal` backgrounds.
- **Interaction Testing**: Verify that scrolling is fluid and the floating header transitions correctly.
- **Notch/SafeArea Check**: Ensure the new header logic respects the device notch.
