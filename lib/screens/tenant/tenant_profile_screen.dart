import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class TenantProfileScreen extends StatefulWidget {
  const TenantProfileScreen({super.key});

  @override
  State<TenantProfileScreen> createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends State<TenantProfileScreen> {
  final supabase = Supabase.instance.client;

  final emergencyNameCtrl = TextEditingController();
  final emergencyPhoneCtrl = TextEditingController();

  DateTime? contractStart;
  DateTime? contractEnd;

  // KTP
  File? ktpImage;
  String? ktpUrl;
  String ktpStatus = 'pending';

  bool isLoading = true;
  bool isUploadingKtp = false;

  @override
  void initState() {
    super.initState();
    _loadTenant();
  }

  // ===============================
  // LOAD TENANT (FIX mounted)
  // ===============================
  Future<void> _loadTenant() async {
    final userId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from('tenants')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data != null) {
      emergencyNameCtrl.text = data['emergency_name'] ?? '';
      emergencyPhoneCtrl.text = data['emergency_phone'] ?? '';

      if (data['contract_start'] != null) {
        contractStart = DateTime.parse(data['contract_start']);
      }
      if (data['contract_end'] != null) {
        contractEnd = DateTime.parse(data['contract_end']);
      }

      ktpUrl = data['ktp_url'];
      ktpStatus = data['ktp_status'] ?? 'pending';
    }

    if (!mounted) return;
    setState(() {
      isUploadingKtp = false;
      isLoading = false;
    });
  }

  // ===============================
  // SAVE PROFILE
  // ===============================
  Future<void> _saveProfile() async {
    final userId = supabase.auth.currentUser!.id;

    await supabase
        .from('tenants')
        .update({
          'emergency_name': emergencyNameCtrl.text,
          'emergency_phone': emergencyPhoneCtrl.text,
          'contract_start': contractStart?.toIso8601String(),
          'contract_end': contractEnd?.toIso8601String(),
        })
        .eq('user_id', userId);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // ===============================
  // PICK KTP
  // ===============================
  Future<void> _pickKtp() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null && mounted) {
      setState(() {
        ktpImage = File(picked.path);
      });
    }
  }

  // ===============================
  // UPLOAD KTP (FIX try–finally)
  // ===============================
  Future<void> _uploadKtp() async {
    if (ktpImage == null) return;

    setState(() => isUploadingKtp = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      final path = '$userId/ktp.jpg';

      await supabase.storage
          .from('ktp')
          .upload(
            path,
            ktpImage!,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = supabase.storage.from('ktp').getPublicUrl(path);

      await supabase
          .from('tenants')
          .update({
            'ktp_url': url,
            'ktp_status': 'pending',
            'ktp_verified': false,
          })
          .eq('user_id', userId);

      if (!mounted) return;
      setState(() {
        ktpUrl = url;
        ktpStatus = 'pending';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('KTP berhasil diupload')));
    } catch (e) {
      debugPrint('❌ uploadKtp error: $e');
    } finally {
      if (mounted) {
        setState(() => isUploadingKtp = false);
      }
    }
  }

  int? _remainingDays() {
    if (contractEnd == null) return null;
    return contractEnd!.difference(DateTime.now()).inDays;
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canUploadKtp = ktpStatus != 'verified' && !isUploadingKtp;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EMERGENCY CONTACT
            const Text(
              'Emergency Contact',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: emergencyNameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kontak'),
            ),
            TextField(
              controller: emergencyPhoneCtrl,
              decoration: const InputDecoration(labelText: 'No. Telepon'),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24),

            // CONTRACT
            const Text(
              'Contract Period',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            ListTile(
              title: const Text('Mulai Kontrak'),
              subtitle: Text(
                contractStart == null
                    ? '-'
                    : DateFormat('dd MMM yyyy').format(contractStart!),
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: contractStart ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null && mounted) {
                  setState(() => contractStart = picked);
                }
              },
            ),

            ListTile(
              title: const Text('Akhir Kontrak'),
              subtitle: Text(
                contractEnd == null
                    ? '-'
                    : DateFormat('dd MMM yyyy').format(contractEnd!),
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: contractEnd ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null && mounted) {
                  setState(() => contractEnd = picked);
                }
              },
            ),

            if (_remainingDays() != null)
              Text(
                _remainingDays()! >= 0
                    ? 'Sisa kontrak: ${_remainingDays()} hari'
                    : 'Kontrak sudah berakhir',
                style: TextStyle(
                  color: _remainingDays()! >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 24),

            // KTP
            const Text(
              'Verifikasi KTP',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            GestureDetector(
              onTap: _pickKtp,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ktpImage != null
                    ? Image.file(ktpImage!, fit: BoxFit.cover)
                    : ktpUrl != null
                    ? Image.network(
                        ktpUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      )
                    : const Center(child: Text('Tap untuk upload foto KTP')),
              ),
            ),

            const SizedBox(height: 8),
            Text('Status: ${ktpStatus.toUpperCase()}'),

            if (ktpStatus != 'verified')
              ElevatedButton(
                onPressed: canUploadKtp ? _uploadKtp : null,
                child: isUploadingKtp
                    ? const Text('Mengupload...')
                    : const Text('Upload KTP'),
              ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
