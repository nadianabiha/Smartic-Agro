
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

const _green = Color(0xFF08733B);
const _bg = Color(0xFFF1F9ED);

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BrandMark(size: 66),
                  const SizedBox(height: 12),
                  const Text(
                    'Smartic Agro',
                    style: TextStyle(
                      color: _green,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Tanah Sehat, Pangan Tepat',
                    style: TextStyle(
                      color: Color(0xFF78907A),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Mulai Smart Farming Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF173A25),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pantau kondisi tanah dan dapatkan rekomendasi '
                    'tanaman yang sesuai dengan lahan Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF6D806F),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 150,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F3DE),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 56,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _PrimaryButton(
                    label: 'Masuk',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _OutlineButton(
                    label: 'Daftar Akun',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Smartic Agro V2',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF91A192),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final double size;

  const _BrandMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.spa_rounded,
      size: size,
      color: const Color(0xFF73B82D),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _green,
          side: const BorderSide(color: _green),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
