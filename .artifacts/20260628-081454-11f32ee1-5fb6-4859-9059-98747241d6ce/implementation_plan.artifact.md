# Optimize Store Loading Performance and UI Snappiness

Investigate and fix the loading speed difference between "Featured Drinks" and "Stores" by optimizing backend queries and decoupling frontend data fetching.

## Proposed Changes

### Backend (Django)

#### [api_v1_customer_views.py](file:///C:/Users/PC/Desktop/tipsytheoryy/urbanfoods/api_v1_customer_views.py)

-   Optimize `CustomerStoreListView` to annotate the `is_favourite` status for the current user. This prevents N+1 queries in the serializer.
-   Use `django.db.models.Exists` with a subquery for efficient favorite checking.

#### [api_v1_serializers.py](file:///C:/Users/PC/Desktop/tipsytheoryy/urbanfoods/api_v1_serializers.py)

-   Update `StoreSerializer` to use the annotated `is_favourite` field from the queryset instead of performing a database query for each item in the list.

---

### Frontend (Flutter)

#### [product_provider.dart](file:///C:/Users/PC/Desktop/tipsytheoryy_app/lib/providers/product_provider.dart)

-   Refactor `fetchHomeData` to decouple the three API calls (Featured Products, Stores, Categories).
-   Introduce independent loading flags: `isFeaturedLoading`, `isStoresLoading`, `isCategoriesLoading`.
-   Update state and call `notifyListeners()` as soon as each individual request completes.
-   Add `isHomeLoading` getter that returns true if ANY of the critical sections are still loading.

#### [home_screen.dart](file:///C:/Users/PC/Desktop/tipsytheoryy_app/lib/screens/customer/home_screen.dart)

-   Update the UI logic to use the new independent loading flags.
-   Refactor the main build method to show skeletons for specific sections (Featured vs Stores) based on their individual loading states.
-   This ensures that "Featured Deals" can appear instantly even if "Popular Stores" (which involves distance calculations) takes a bit longer.

---

## Verification Plan

### Automated Tests
-   I will verify the number of queries in the backend by monitoring logs or using a simple script to count queries for the `customer/stores/` endpoint.
-   Since there are no existing automated UI tests for this specific performance metric, I will rely on manual verification and log analysis.

### Manual Verification
-   **Log Monitoring:** Verify in the Django console that the `customer/stores/` endpoint no longer triggers multiple `favourite_stores` lookups per request.
-   **UI Performance:** Run the app and observe the "snappiness" of the home screen. Verify that "Featured Deals" and "Categories" populate independently of "Popular Stores".
-   **Functionality Check:** Ensure that adding to favorites still works correctly and is reflected in the UI after the optimizations.
