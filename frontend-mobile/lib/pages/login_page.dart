import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'welcome_page.dart';

const _green = Color(0xFF08733B);
const _bg = Color(0xFFF1F9ED);
const _ink = Color(0xFF173A25);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);

    Map<String, dynamic> result;

    try {
      result = await _auth.login(
        _email.text.trim(),
        _password.text,
      );
    } catch (e) {
      result = {
        'success': false,
        'message':
            'Tidak dapat terhubung ke server. Periksa backend dan alamat API.',
      };
    }

    if (!mounted) return;

    setState(() => _loading = false);

    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        ),
        (r) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result['message'] ?? 'Login gagal'}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WelcomePage(),
                        ),
                        (r) => false,
                      ),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: _green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.spa_rounded,
                            color: Color(0xFF73B82D),
                            size: 45,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Smartic Agro',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _green,
                            ),
                          ),
                          Text(
                            'Tanah Sehat, Pangan Tepat',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF78907A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),
                    const Text(
                      'Selamat Datang!',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Masuk untuk mulai melihat kondisi lahan dan rekomendasi tanaman.',
                      style: TextStyle(
                        color: Color(0xFF718373),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _textField(
                      _email,
                      'Email atau Nomor HP',
                      Icons.person_outline,
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Wajib diisi'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      _password,
                      'Password',
                      Icons.lock_outline,
                      obscure: _hide,
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _hide = !_hide),
                        icon: Icon(
                          _hide
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey,
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty
                              ? 'Password wajib diisi'
                              : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ForgotPasswordPage(),
                          ),
                        ),
                        child: const Text(
                          'Lupa password?',
                          style: TextStyle(
                            color: _green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              color: Color(0xFF718373),
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            ),
                            child: const Text(
                              'Daftar',
                              style: TextStyle(
                                color: _green,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController c,
    String hint,
    IconData icon, {
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: c,
      validator: validator,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          size: 19,
          color: const Color(0xFF7C927F),
        ),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF9AA99B),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE2EAE0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE2EAE0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green),
        ),
      ),
    );
  }
}