import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room.dart';

class RoomService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ======================
  // GET ALL ROOMS
  // ======================
  Future<List<Room>> getRooms() async {
    final response = await _supabase
        .from('rooms')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => Room.fromMap(e)).toList();
  }

  // ======================
  // ADD ROOM
  // ======================
  Future<void> addRoom({
    required String number,
    required String type,
    required int price,
    required String facilities,
    String? photoUrl,
  }) async {
    await _supabase.from('rooms').insert({
      'number': number,
      'type': type,
      'price': price,
      'status': 'available',
      'facilities': facilities,
      'photo_url': photoUrl,
    });
  }

  // ======================
  // DELETE ROOM
  // ======================
  Future<void> deleteRoom(String id) async {
    await _supabase.from('rooms').delete().eq('id', id);
  }

  // ======================
  // UPDATE ROOM
  // ======================
  Future<void> updateRoom({
    required String id,
    required String number,
    required String type,
    required int price,
    required String facilities,
    required String status,
    String? photoUrl,
  }) async {
    final data = {
      'number': number,
      'type': type,
      'price': price,
      'facilities': facilities,
      'status': status,
    };

    if (photoUrl != null) {
      data['photo_url'] = photoUrl;
    }

    await _supabase.from('rooms').update(data).eq('id', id);
  }

  // ======================
  // UPLOAD IMAGE TO STORAGE
  // ======================
  Future<String> uploadRoomImage(File file) async {
    final fileName = 'room_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage.from('room-images').upload(fileName, file);

    return _supabase.storage.from('room-images').getPublicUrl(fileName);
  }
}
