# Favorites / Home Loading – Review & Optimizations

## 1. Was `fetchData()` called repeatedly inside `build()`?

**Yes.** The Favorite section used a `ValueListenableBuilder<int>(favoriteFromChatVersion)` that rebuilds when the version changes or when the parent rebuilds (e.g. `currentUserProfileCache` updates). Inside that builder, when the cache was null, the code did:

```dart
future = SupabaseService.getFavoriteTutorsTabList(user.id);  // NEW future every build
return FutureBuilder(future: future, ...);
```

Each rebuild created a **new** `Future`, so `FutureBuilder` restarted and triggered a **new** Supabase request. Any of these could cause repeated rebuilds and thus repeated fetches:

- `favoriteFromChatVersion` notifier firing
- `currentUserProfileCache` notifier firing (e.g. when profile stats load or disk hydrate runs)
- Parent `setState` or other listeners

**Fix applied:** One in-flight future per tab is stored in state (`_inFlightFavoriteTutors`, etc.). The same future is reused across rebuilds until it completes, then the cache is updated and the in-flight slot is cleared. Invalidating the cache (e.g. on version change) also clears the in-flight futures so the next load uses a fresh request.

---

## 2. N+1 or per-item profile fetches?

**No.** Favorites are not loaded with an N+1 pattern.

- **IDs:** `getFavoriteTutorIdsFromChat(userId)` (and the other tabs) run **one** query on `favorite_tab_assignments` for that tab and cache the result in memory (`_favoriteTutorIdsFromChat`, etc.).
- **Profiles:** A **single** query is used:  
  `supabase.from('profiles').select().inFilter('user_id', ids.toList())`  
  So all profiles for the current tab are fetched in one request, not one per item.

So there is no “fetch profile for each item in a list” pattern; it’s already a batch query.

---

## 3. Other sources of load

- **`hydrateCachesFromDisk(userId)`** is called at the start of each `getFavorite*TabList()`. It returns immediately if that `userId` was already hydrated (`_diskHydratedUserIds`). So after the first call per user, it does not repeat disk/DB work for hydration.
- **Preload:** `_preloadFavoriteTabCaches(user.id)` in `initState` starts **three** parallel fetches (Tutors, Students, Fellows) once when the home screen is first loaded. That is intentional (one fetch per tab) and not repeated on every build.

---

## 4. Optional further optimization (Supabase side)

To reduce round-trips and CPU a bit more, you could replace “IDs query + profiles by IDs” with a **single RPC** (or a view) that returns favorite profiles for a user and tab in one call, e.g.:

- **RPC:** e.g. `get_favorite_tab_profiles(p_user_id uuid, p_tab text)` that:
  - Reads `favorite_tab_assignments` for that user and tab, then
  - Joins to `profiles` and returns the profile rows (or a restricted set of columns).

Then the client would call that RPC once per tab instead of:

1. `favorite_tab_assignments` select  
2. `profiles` select with `inFilter('user_id', ids)`

This is optional; the main fix for repeated requests was stopping the repeated creation of new futures in `build()`.
