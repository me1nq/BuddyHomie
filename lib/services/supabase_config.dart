import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://fnupwfxndeklxklxxhtt.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZudXB3ZnhuZGVrbHhrbHh4aHR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwMDc5MjgsImV4cCI6MjA4NTU4MzkyOH0.qcAi2P6Mul2YSqFwWnT0Jbpc3yHSfMG8foS2RBMUawM';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}
