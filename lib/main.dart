import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'features/bookings/controllers/booking_controller.dart';
import 'features/bookings/services/booking_service.dart';
import 'features/bookings/views/bookings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  await Supabase.instance.client.auth.signInWithPassword(
    email: 'B01@student.unimy.my',
    password: 'newpassword123',
  );

  final userId = Supabase.instance.client.auth.currentUser!.id;

  runApp(
    ChangeNotifierProvider(
      create: (_) => BookingController(
        BookingService(Supabase.instance.client),
        userId,
      ),
      child: const MaterialApp(home: BookingsScreen()),
    ),
  );
}