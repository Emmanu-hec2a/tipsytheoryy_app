# Walkthrough: Home Screen Performance Optimization

I have optimized the store loading performance and improved the UI "snappiness" of the home screen by optimizing backend queries and decoupling frontend data fetching.

## Changes Made

### Backend (Django)
-   **Optimized `CustomerStoreListView`:**
    -   Annotated the `is_favourite` field using a subquery (`Exists`), eliminating N+1 queries during serialization.
    -   Added `select_related('owner')` to fetch store owner details (phone, email, bank info) in the same query, further reducing database hits.
-   **Updated `StoreSerializer`:**
    -   Modified `get_is_favourite` to prioritize the annotated field from the queryset, falling back to a manual query only if necessary.

### Frontend (Flutter)
-   **Refactored `ProductProvider`:**
    -   Decoupled `fetchHomeData` into three independent async operations (Featured Products, Stores, Categories).
    -   Introduced granular loading flags: `isFeaturedLoading`, `isStoresLoading`, and `isCategoriesLoading`.
    -   The UI now updates incrementally as each data piece arrives.
-   **Improved `HomeScreen` UI:**
    -   Updated the loading logic to show section-specific skeletons.
    -   "Featured Deals" and "Categories" now appear instantly even if the "Popular Stores" (which involves distance calculations) takes slightly longer to fetch.
    -   This prevents the "all-or-nothing" loading behavior that caused perceived lag.

## Verification Results

### Backend Efficiency
I verified the query optimization using a script that simulates store list serialization.
-   **Result:** Serializing 4 stores now takes significantly fewer queries (down from many individual lookups to just a few unified queries).
-   **SQL Proof:** The `is_favourite` check is now a single `EXISTS` subquery inside the main `SELECT` statement.

### UI Performance
-   The home screen now feels much more responsive.
-   Users can interact with Featured Products almost immediately upon opening the app.
-   Shimmer effects are now localized to the specific section that is still loading.
