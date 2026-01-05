import 'dart:io';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/room_service.dart';

class RoomProvider extends ChangeNotifier {
  final RoomService _roomService = RoomService();

  List<Room> rooms = [];
  bool isLoading = false;
  String? error;

  // ======================
  // FETCH ROOMS
  // ======================
  Future<void> fetchRooms() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      rooms = await _roomService.getRooms();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================
  // ADD ROOM (+ OPTIONAL PHOTO)
  // ======================
  Future<void> addRoom({
    required String number,
    required String type,
    required int price,
    required String facilities,
    File? photoFile,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      String? photoUrl;

      if (photoFile != null) {
        photoUrl = await _roomService.uploadRoomImage(photoFile);
      }

      await _roomService.addRoom(
        number: number,
        type: type,
        price: price,
        facilities: facilities,
        photoUrl: photoUrl,
      );

      await fetchRooms();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================
  // DELETE ROOM
  // ======================
  Future<void> deleteRoom(String id) async {
    isLoading = true;
    notifyListeners();

    try {
      await _roomService.deleteRoom(id);
      await fetchRooms();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================
  // UPDATE ROOM (+ OPTIONAL PHOTO)
  // ======================
  Future<void> updateRoom({
    required String id,
    required String number,
    required String type,
    required int price,
    required String facilities,
    required String status,
    File? newPhotoFile,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      String? photoUrl;

      if (newPhotoFile != null) {
        photoUrl = await _roomService.uploadRoomImage(newPhotoFile);
      }

      await _roomService.updateRoom(
        id: id,
        number: number,
        type: type,
        price: price,
        facilities: facilities,
        status: status,
        photoUrl: photoUrl,
      );

      await fetchRooms();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
