import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/room_provider.dart';
import 'providers/tenant_provider.dart';
import 'providers/payment_provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/owner/dashboard_owner_screen.dart';
import 'screens/tenant/dashboard_tenant_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hmhnijrydikyfxuhaqdj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtaG5panJ5ZGlreWZ4dWhhcWRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwNzA5OTgsImV4cCI6MjA4MjY0Njk5OH0.sY_7gLxuAUAXmN7JDmqK518M2kVgu3PpDYS4W2sRse4',
  );

  runApp(const KostKuApp());
}

class KostKuApp extends StatelessWidget {
  const KostKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🔐 AUTH
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // 🏠 ROOMS
        ChangeNotifierProvider(create: (_) => RoomProvider()),

        // 👤 TENANT
        ChangeNotifierProvider(create: (_) => TenantProvider()),

        // 💰 PAYMENT
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        /// 🔥 SATU-SATUNYA TEMPAT ROUTING
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            // ⏳ TUNGGU AUTH SELESAI
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // ❌ BELUM LOGIN
            if (!auth.isLoggedIn) {
              return const LoginScreen();
            }

            // ✅ SUDAH LOGIN → ROLE BASED
            if (auth.role == 'owner') {
              return const DashboardOwnerScreen();
            }

            // DEFAULT = TENANT
            return const DashboardTenantScreen();
          },
        ),
      ),
    );
  }
}
