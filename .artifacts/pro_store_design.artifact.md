# Design Proposal: TipsyTheoryy "Pro Store" Verification

This proposal outlines the implementation of a "Pro Store" status for premium merchants, featuring a distinctive **Teal Green Verification Tick** to build customer trust and platform prestige.

## 1. Concept & Visual Identity
- **The Badge:** A circular teal green badge with a white checkmark.
- **Teal Color:** Using a vibrant teal (`#2DD4BF`) to distinguish from standard platform colors while maintaining a "premium" feel.
- **Placement:** Positioned immediately after the store name on all platform surfaces.

## 2. Technical Implementation (Backend)

### Data Model Changes
Add an `is_pro` field to the `Store` model.
```python
# urbanfoods/models.py
class Store(models.Model):
    # ... existing fields
    is_pro = models.BooleanField(default=False)
```

### Serializer Update
Expose the status to the mobile app.
```python
# urbanfoods/api_v1_serializers.py
class StoreSerializer(models.ModelSerializer):
    class Meta:
        model = Store
        fields = ['id', 'name', 'is_pro', ...] # Include is_pro
```

## 3. Technical Implementation (Flutter)

### Component: `ProBadge`
A reusable widget for consistent rendering.
```dart
class ProBadge extends StatelessWidget {
  final double size;
  const ProBadge({this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Color(0xFF2DD4BF), // Tipsy Teal
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, color: Colors.white, size: size * 0.7),
    );
  }
}
```

### Integration Points
1.  **Store Card:** Shown in the main feed.
2.  **Store Detail Header:** High-visibility placement.
3.  **Checkout:** Confirms trust during the final step.
4.  **Search Results:** Helps Pro stores stand out.

## 4. Proposed Workflow
1.  **Phase 1:** Backend migration to support `is_pro`.
2.  **Phase 2:** UI Component creation in Flutter.
3.  **Phase 3:** Integration across all customer-facing screens.
4.  **Phase 4 (Future):** Automated criteria for "Pro" status (e.g., >4.5 rating, <20min delivery avg).

---
**Do you approve of this Teal Badge design and implementation plan?**
