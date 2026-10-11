import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/member_model.dart';
import '../models/trip_model.dart';
import '../services/preferences_service.dart';
import '../services/supabase_service.dart';

class TripRepository {
  final PreferencesService _prefs;
  final _uuid = const Uuid();

  TripRepository(this._prefs);

  /// Fetches all trips (active and completed)
  Future<List<TripModel>> getTrips() async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        final client = SupabaseService.client!;
        final tripsResponse = await client
            .from(AppConstants.tableTrips)
            .select()
            .order('created_at', ascending: false);

        final List<TripModel> trips = [];
        for (final item in tripsResponse) {
          final tripId = item['id'] as String;
          // Fetch members for this trip
          final membersResponse = await client
              .from(AppConstants.tableTripMembers)
              .select()
              .eq('trip_id', tripId);

          final members = (membersResponse as List)
              .map((m) => MemberModel.fromJson(m as Map<String, dynamic>))
              .toList();

          trips.add(TripModel.fromJson(item, members: members));
        }

        // Cache locally for offline resilience
        await _prefs.saveLocalTrips(trips.map((t) => t.toJson()).toList());
        for (final t in trips) {
          await _prefs.saveLocalMembers(
            t.id,
            t.members.map((m) => m.toJson()).toList(),
          );
        }

        return trips;
      } catch (e) {
        // Fallback to local cache if network fails
        return _getLocalTrips();
      }
    } else {
      return _getLocalTrips();
    }
  }

  List<TripModel> _getLocalTrips() {
    final cachedTrips = _prefs.getLocalTrips();
    return cachedTrips.map((json) {
      final tripId = json['id'] as String;
      final cachedMembers = _prefs.getLocalMembers(tripId);
      final members = cachedMembers.map((m) => MemberModel.fromJson(m)).toList();
      return TripModel.fromJson(json, members: members);
    }).toList();
  }

  /// Creates a new trip with members
  Future<TripModel> createTrip({
    required String name,
    required DateTime fromDate,
    DateTime? toDate,
    String? description,
    List<String> memberNames = const [],
  }) async {
    final String tripId = _uuid.v4();
    final String ownerId = SupabaseService.currentUserId;
    final now = DateTime.now();

    // Default name to "New Trip" if user did not provide one
    final effectiveName = name.trim().isEmpty ? 'New Trip' : name.trim();

    // Requirement 3 & 4: Initially contains only "You (Me)" representing current user
    final ownerMember = MemberModel(
      id: _uuid.v4(),
      tripId: tripId,
      userId: ownerId,
      name: 'You (Me)',
      isOwner: true,
      createdAt: now,
    );

    final List<MemberModel> members = [ownerMember];
    for (final mName in memberNames) {
      final trimmed = mName.trim();
      if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'you' && trimmed.toLowerCase() != 'you (me)') {
        members.add(
          MemberModel(
            id: _uuid.v4(),
            tripId: tripId,
            name: trimmed,
            isOwner: false,
            createdAt: now,
          ),
        );
      }
    }

    final newTrip = TripModel(
      id: tripId,
      ownerId: ownerId,
      name: effectiveName,
      description: description?.trim(),
      fromDate: fromDate,
      toDate: toDate,
      status: 'active',
      currency: 'INR',
      members: members,
      createdAt: now,
      updatedAt: now,
    );

    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        final client = SupabaseService.client!;
        await client.from(AppConstants.tableTrips).insert(newTrip.toJson());
        await client
            .from(AppConstants.tableTripMembers)
            .insert(members.map((m) => m.toJson()).toList());
      } catch (e) {
        // Continue to save locally
      }
    }

    // Save locally
    final currentList = _prefs.getLocalTrips();
    currentList.insert(0, newTrip.toJson());
    await _prefs.saveLocalTrips(currentList);
    await _prefs.saveLocalMembers(tripId, members.map((m) => m.toJson()).toList());

    return newTrip;
  }

  /// Adds a new member to an existing trip
  Future<MemberModel> addMember({
    required String tripId,
    required String memberName,
    String? phone,
  }) async {
    final now = DateTime.now();
    final newMember = MemberModel(
      id: _uuid.v4(),
      tripId: tripId,
      name: memberName.trim(),
      phone: phone?.trim(),
      isOwner: false,
      createdAt: now,
    );

    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        await SupabaseService.client!
            .from(AppConstants.tableTripMembers)
            .insert(newMember.toJson());
      } catch (_) {}
    }

    final cachedMembers = _prefs.getLocalMembers(tripId);
    cachedMembers.add(newMember.toJson());
    await _prefs.saveLocalMembers(tripId, cachedMembers);

    return newMember;
  }

  /// Updates a member's name and/or phone
  Future<void> updateMember({
    required String tripId,
    required String memberId,
    required String name,
    String? phone,
  }) async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        await SupabaseService.client!
            .from(AppConstants.tableTripMembers)
            .update({
              'name': name.trim(),
              if (phone != null) 'phone': phone.trim(),
            })
            .eq('id', memberId);
      } catch (_) {}
    }

    final cachedMembers = _prefs.getLocalMembers(tripId);
    for (int i = 0; i < cachedMembers.length; i++) {
      if (cachedMembers[i]['id'] == memberId) {
        cachedMembers[i]['name'] = name.trim();
        if (phone != null) cachedMembers[i]['phone'] = phone.trim();
        break;
      }
    }
    await _prefs.saveLocalMembers(tripId, cachedMembers);
  }

  /// Removes a member from a trip (cannot remove owner)
  Future<void> removeMember({
    required String tripId,
    required String memberId,
  }) async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        await SupabaseService.client!
            .from(AppConstants.tableTripMembers)
            .delete()
            .eq('id', memberId);
      } catch (_) {}
    }

    final cachedMembers = _prefs.getLocalMembers(tripId);
    cachedMembers.removeWhere((m) => m['id'] == memberId && m['is_owner'] != true);
    await _prefs.saveLocalMembers(tripId, cachedMembers);
  }

  /// Updates trip status to completed
  Future<void> endTrip(String tripId) async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        await SupabaseService.client!
            .from(AppConstants.tableTrips)
            .update({'status': 'completed', 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', tripId);
      } catch (_) {}
    }

    final cachedTrips = _prefs.getLocalTrips();
    for (int i = 0; i < cachedTrips.length; i++) {
      if (cachedTrips[i]['id'] == tripId) {
        cachedTrips[i]['status'] = 'completed';
        cachedTrips[i]['updated_at'] = DateTime.now().toIso8601String();
        break;
      }
    }
    await _prefs.saveLocalTrips(cachedTrips);
  }

  /// Delete a trip
  Future<void> deleteTrip(String tripId) async {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        await SupabaseService.client!
            .from(AppConstants.tableTrips)
            .delete()
            .eq('id', tripId);
      } catch (_) {}
    }

    final cachedTrips = _prefs.getLocalTrips();
    cachedTrips.removeWhere((t) => t['id'] == tripId);
    await _prefs.saveLocalTrips(cachedTrips);
  }
}
