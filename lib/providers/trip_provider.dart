import 'package:flutter/foundation.dart';
import '../models/member_model.dart';
import '../models/trip_model.dart';
import '../repositories/trip_repository.dart';

class TripProvider extends ChangeNotifier {
  final TripRepository _repository;

  List<TripModel> _trips = [];
  TripModel? _currentTrip;
  bool _isLoading = false;
  String? _errorMessage;

  TripProvider(this._repository);

  List<TripModel> get trips => _trips;
  TripModel? get currentTrip => _currentTrip;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TripModel> get activeTrips => _trips.where((t) => t.isActive).toList();
  List<TripModel> get completedTrips => _trips.where((t) => t.isCompleted).toList();

  TripModel? get latestActiveTrip {
    final active = activeTrips;
    return active.isNotEmpty ? active.first : null;
  }

  /// Loads all trips
  Future<void> loadTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _trips = await _repository.getTrips();
      if (_currentTrip != null) {
        // Refresh currently selected trip
        try {
          _currentTrip = _trips.firstWhere((t) => t.id == _currentTrip!.id);
        } catch (_) {
          _currentTrip = _trips.isNotEmpty ? _trips.first : null;
        }
      } else if (activeTrips.isNotEmpty) {
        _currentTrip = activeTrips.first;
      }
    } catch (e) {
      _errorMessage = "Couldn't load trips. Please check connection.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selects active trip by ID
  void selectTrip(String tripId) {
    try {
      _currentTrip = _trips.firstWhere((t) => t.id == tripId);
      notifyListeners();
    } catch (_) {}
  }

  /// Creates a new trip
  Future<TripModel?> createTrip({
    required String name,
    required DateTime fromDate,
    DateTime? toDate,
    String? description,
    List<String> memberNames = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final trip = await _repository.createTrip(
        name: name,
        fromDate: fromDate,
        toDate: toDate,
        description: description,
        memberNames: memberNames,
      );
      _trips.insert(0, trip);
      _currentTrip = trip;
      return trip;
    } catch (e) {
      _errorMessage = "Couldn't create trip. Please try again.";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new member to the current trip
  Future<MemberModel?> addMemberToTrip({
    required String tripId,
    required String memberName,
    String? phone,
  }) async {
    try {
      final member = await _repository.addMember(
        tripId: tripId,
        memberName: memberName,
        phone: phone,
      );

      // Update in memory
      for (int i = 0; i < _trips.length; i++) {
        if (_trips[i].id == tripId) {
          final updatedMembers = List<MemberModel>.from(_trips[i].members)..add(member);
          _trips[i] = _trips[i].copyWith(members: updatedMembers);
          if (_currentTrip?.id == tripId) {
            _currentTrip = _trips[i];
          }
          break;
        }
      }
      notifyListeners();
      return member;
    } catch (e) {
      _errorMessage = "Couldn't add member.";
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing member in a trip
  Future<bool> updateMember({
    required String tripId,
    required String memberId,
    required String name,
    String? phone,
  }) async {
    try {
      await _repository.updateMember(
        tripId: tripId,
        memberId: memberId,
        name: name,
        phone: phone,
      );

      for (int i = 0; i < _trips.length; i++) {
        if (_trips[i].id == tripId) {
          final updatedMembers = _trips[i].members.map((m) {
            if (m.id == memberId) {
              return m.copyWith(name: name.trim(), phone: phone?.trim());
            }
            return m;
          }).toList();
          _trips[i] = _trips[i].copyWith(members: updatedMembers);
          if (_currentTrip?.id == tripId) {
            _currentTrip = _trips[i];
          }
          break;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Couldn't update member.";
      notifyListeners();
      return false;
    }
  }

  /// Removes a member from a trip
  Future<bool> removeMember({
    required String tripId,
    required String memberId,
  }) async {
    try {
      await _repository.removeMember(
        tripId: tripId,
        memberId: memberId,
      );

      for (int i = 0; i < _trips.length; i++) {
        if (_trips[i].id == tripId) {
          final updatedMembers =
              _trips[i].members.where((m) => m.id != memberId).toList();
          _trips[i] = _trips[i].copyWith(members: updatedMembers);
          if (_currentTrip?.id == tripId) {
            _currentTrip = _trips[i];
          }
          break;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Couldn't remove member.";
      notifyListeners();
      return false;
    }
  }

  /// Marks a trip as completed
  Future<bool> endTrip(String tripId) async {
    try {
      await _repository.endTrip(tripId);
      for (int i = 0; i < _trips.length; i++) {
        if (_trips[i].id == tripId) {
          _trips[i] = _trips[i].copyWith(status: 'completed');
          if (_currentTrip?.id == tripId) {
            _currentTrip = _trips[i];
          }
          break;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Couldn't end trip.";
      notifyListeners();
      return false;
    }
  }

  /// Deletes a trip
  Future<bool> deleteTrip(String tripId) async {
    try {
      await _repository.deleteTrip(tripId);
      _trips.removeWhere((t) => t.id == tripId);
      if (_currentTrip?.id == tripId) {
        _currentTrip = _trips.isNotEmpty ? _trips.first : null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Couldn't delete trip.";
      notifyListeners();
      return false;
    }
  }
}
