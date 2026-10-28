import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

const _green = Color(0xFF08733B);
const _bg = Color(0xFFF1F9ED);
const _ink = Color(0xFF173A25);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _hide = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);

    Map<String, dynamic> result;

    try {
      result = await _auth.register(
        _name.text.trim(),
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
          content: Text('${result['message'] ?? 'Registrasi gagal'}'),
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
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 26),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: _green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.spa_rounded,
                            color: Color(0xFF73B82D),
                            size: 42,
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
                    const SizedBox(height: 34),
                    const Text(
                      'Daftar Akun',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Buat akun baru untuk menggunakan Smartic Agro.',
                      style: TextStyle(color: Color(0xFF718373)),
                    ),
                    const SizedBox(height: 22),
                    _field(
                      _name,
                      'Nama Lengkap',
                      Icons.person_outline,
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Nama wajib diisi'
                              : null,
                    ),
                    const SizedBox(height: 11),
                    _field(
                      _email,
                      'Email atau Nomor HP',
                      Icons.mail_outline,
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Email/nomor HP wajib diisi'
                              : null,
                    ),
                    const SizedBox(height: 11),
                    _field(
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
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.length < 6
                              ? 'Minimal 6 karakter'
                              : null,
                    ),
                    const SizedBox(height: 11),
                    _field(
                      _confirm,
                      'Konfirmasi Password',
                      Icons.lock_outline,
                      obscure: _hideConfirm,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _hideConfirm = !_hideConfirm,
                        ),
                        icon: Icon(
                          _hideConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      validator: (v) =>
                          v != _password.text
                              ? 'Password belum sama'
                              : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
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
                                'Daftar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun? ',
                            style: TextStyle(
                              color: Color(0xFF718373),
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            ),
                            child: const Text(
                              'Masuk',
                              style: TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
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

  Widget _field(
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