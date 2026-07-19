# Task: Optimize Store Loading Performance

- [/] Research and Plan Performance Optimization
- [ ] Optimize Backend Store Queries
	- [ ] Annotate `is_favourite` in `CustomerStoreListView`
	- [ ] Update `StoreSerializer` to use annotated field
- [ ] Refactor Flutter ProductProvider
	- [ ] Split `fetchHomeData` into independent futures
	- [ ] Add granular loading states
- [ ] Update Home Screen UI
	- [ ] Show independent skeletons for Featured and Stores
	- [ ] Ensure smooth transitions between loading and loaded states
- [ ] Verify Optimizations
	- [ ] Check backend query counts
	- [ ] Manual UI verification
