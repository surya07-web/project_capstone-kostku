import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/room_provider.dart';
import '../../models/room.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  static const Color blue = Color(0xFF2F6FED);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<RoomProvider>().fetchRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<RoomProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // =====================
      // HEADER BIRU
      // =====================
      appBar: AppBar(
        backgroundColor: blue,
        elevation: 0,
        title: const Text('Kelola Kamar'),
      ),

      body: roomProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : roomProvider.rooms.isEmpty
          ? const Center(child: Text('Belum ada kamar'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: roomProvider.rooms.length,
              itemBuilder: (context, index) {
                final room = roomProvider.rooms[index];
                final isOccupied = room.status == 'occupied';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // =====================
                      // FOTO KAMAR
                      // =====================
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: room.photoUrl != null
                            ? Image.network(
                                room.photoUrl!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 72,
                                height: 72,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.meeting_room,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                      ),

                      const SizedBox(width: 12),

                      // =====================
                      // INFO KAMAR
                      // =====================
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kamar ${room.number}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${room.type} • Rp ${room.price}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // STATUS BADGE
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isOccupied
                                    ? Colors.red.withOpacity(0.15)
                                    : Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isOccupied ? 'Occupied' : 'Available',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isOccupied ? Colors.red : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =====================
                      // ACTION
                      // =====================
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: blue),
                            tooltip: 'Edit Kamar',
                            onPressed: () => _showEditRoomDialog(context, room),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Hapus Kamar',
                            onPressed: () async {
                              await roomProvider.deleteRoom(room.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

      // =====================
      // FAB
      // =====================
      floatingActionButton: FloatingActionButton(
        backgroundColor: blue,
        child: const Icon(Icons.add),
        onPressed: () => _showAddRoomDialog(context),
      ),
    );
  }

  // =====================================================
  // ADD ROOM (TIDAK DIUBAH LOGIC)
  // =====================================================
  void _showAddRoomDialog(BuildContext context) {
    final numberController = TextEditingController();
    final typeController = TextEditingController();
    final priceController = TextEditingController();
    final facilitiesController = TextEditingController();

    File? selectedImage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Kamar'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _imagePicker(
                      imageFile: selectedImage,
                      onPick: (file) {
                        setState(() => selectedImage = file);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Kamar',
                      ),
                    ),
                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(labelText: 'Tipe'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Harga'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: facilitiesController,
                      decoration: const InputDecoration(labelText: 'Fasilitas'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await context.read<RoomProvider>().addRoom(
                      number: numberController.text,
                      type: typeController.text,
                      price: int.tryParse(priceController.text) ?? 0,
                      facilities: facilitiesController.text,
                      photoFile: selectedImage,
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =====================================================
  // EDIT ROOM (TIDAK DIUBAH LOGIC)
  // =====================================================
  void _showEditRoomDialog(BuildContext context, Room room) {
    final numberController = TextEditingController(text: room.number);
    final typeController = TextEditingController(text: room.type);
    final priceController = TextEditingController(text: room.price.toString());
    final facilitiesController = TextEditingController(text: room.facilities);

    String selectedStatus = room.status;
    File? newImage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Kamar'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _imagePicker(
                      imageFile: newImage,
                      networkImage: room.photoUrl,
                      onPick: (file) {
                        setState(() => newImage = file);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Kamar',
                      ),
                    ),
                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(labelText: 'Tipe'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Harga'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: facilitiesController,
                      decoration: const InputDecoration(labelText: 'Fasilitas'),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status Kamar',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'available',
                          child: Text('Available'),
                        ),
                        DropdownMenuItem(
                          value: 'occupied',
                          child: Text('Occupied'),
                        ),
                      ],
                      onChanged: (value) {
                        selectedStatus = value!;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await context.read<RoomProvider>().updateRoom(
                      id: room.id,
                      number: numberController.text,
                      type: typeController.text,
                      price: int.tryParse(priceController.text) ?? room.price,
                      facilities: facilitiesController.text,
                      status: selectedStatus,
                      newPhotoFile: newImage,
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =====================
  // IMAGE PICKER WIDGET
  // =====================
  Widget _imagePicker({
    File? imageFile,
    String? networkImage,
    required Function(File) onPick,
  }) {
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 75,
        );
        if (picked != null) {
          onPick(File(picked.path));
        }
      },
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
          image: imageFile != null
              ? DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover)
              : networkImage != null
              ? DecorationImage(
                  image: NetworkImage(networkImage),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: (imageFile == null && networkImage == null)
            ? const Center(child: Text('Tap untuk pilih foto'))
            : null,
      ),
    );
  }
}
