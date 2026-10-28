// ============================================
// FILE: lib/pages/forgot_password_page.dart
// ============================================
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart' hide AppColors;
import '../widgets/responsive_widgets.dart';
import '../utils/responsive_utils.dart';
import '../utils/app_theme.dart';

/// Halaman Forgot Password - 100% Responsif dengan Multi-step dan Desain Premium
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _email = '';

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  // ===== FUNGSI YANG TIDAK DIUBAH =====
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFE53935) : const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Masukkan email yang valid', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authService.requestPasswordReset(email);
    setState(() => _isLoading = false);
    if (result['success']) {
      setState(() {
        _email = email;
        _currentStep = 1;
      });
      _showSnackBar('Kode verifikasi telah dikirim');
    } else {
      _showSnackBar(result['message'], isError: true);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showSnackBar('Kode harus 6 digit', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authService.verifyResetCode(_email, code);
    setState(() => _isLoading = false);
    if (result['success']) {
      setState(() => _currentStep = 2);
      _showSnackBar('Kode valid!');
    } else {
      _showSnackBar(result['message'], isError: true);
    }
  }

  Future<void> _resetPassword() async {
    final pass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    if (pass.length < 6) {
      _showSnackBar('Password minimal 6 karakter', isError: true);
      return;
    }
    if (pass != confirm) {
      _showSnackBar('Password tidak cocok', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authService.resetPassword(
        _email, _codeController.text.trim(), pass);
    setState(() => _isLoading = false);
    if (result['success']) {
      _showSnackBar('Password berhasil direset!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } else {
      _showSnackBar(result['message'], isError: true);
    }
  }
  // ===== END FUNGSI YANG TIDAK DIUBAH =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PERBAIKAN: Tambahkan resizeToAvoidBottomInset
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),
          // Decorative Elements
          _buildDecorativeElements(),
          // Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final responsive = context.responsive;
                final isTablet = constraints.maxWidth >= 600;

                // PERBAIKAN: Hapus IntrinsicHeight dan gunakan SingleChildScrollView dengan benar
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48 : 24,
                    vertical: 16,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAppBar(responsive),
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isTablet ? 450 : double.infinity,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: responsive.spacing(24)),
                                  _buildStepIndicator(responsive),
                                  SizedBox(height: responsive.spacing(32)),
                                  _buildGlassCard(responsive),
                                  // PERBAIKAN: Tambah padding bawah untuk keyboard
                                  SizedBox(height: responsive.spacing(32)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A2E12),
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
                Color(0xFF1B5E20),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _BubblePainter(_backgroundController.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildDecorativeElements() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF81C784).withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(ResponsiveUtils responsive) {
    return Row(
      children: [
        // Back Button
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: responsive.iconSize(20),
            ),
          ),
        ),
        SizedBox(width: responsive.spacing(16)),
        // Title
        Text(
          'Lupa Password',
          style: TextStyle(
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(ResponsiveUtils responsive) {
    final labels = ['Email', 'Kode', 'Password'];
    final icons = [Icons.email_outlined, Icons.security, Icons.lock_reset];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(12),
        vertical: responsive.spacing(16),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (i) {
          if (i.isOdd) {
            // Connector Line
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.symmetric(horizontal: responsive.spacing(4)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: i < _currentStep * 2
                      ? const LinearGradient(
                          colors: [Color(0xFF66BB6A), Color(0xFFA5D6A7)],
                        )
                      : null,
                  color: i < _currentStep * 2 ? null : Colors.white24,
                ),
              ),
            );
          }
          final step = i ~/ 2;
          final isActive = step == _currentStep;
          final done = step < _currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: responsive.iconSize(40),
                height: responsive.iconSize(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: done || isActive
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF66BB6A),
                            Color(0xFF43A047),
                          ],
                        )
                      : null,
                  color: done || isActive
                      ? null
                      : Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: done || isActive
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: done || isActive
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFF4CAF50).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: done
                      ? Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: responsive.iconSize(18),
                        )
                      : Icon(
                          icons[step],
                          color: isActive ? Colors.white : Colors.white54,
                          size: responsive.iconSize(18),
                        ),
                ),
              ),
              SizedBox(height: responsive.spacing(6)),
              Text(
                labels[step],
                style: TextStyle(
                  color: isActive || done ? Colors.white : Colors.white54,
                  fontSize: responsive.fontSize(11),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildGlassCard(ResponsiveUtils responsive) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(responsive.spacing(24)),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildContent(responsive),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ResponsiveUtils responsive) {
    switch (_currentStep) {
      case 0:
        return _emailStep(responsive);
      case 1:
        return _codeStep(responsive);
      default:
        return _passwordStep(responsive);
    }
  }

  Widget _emailStep(ResponsiveUtils responsive) {
    return Column(
      key: const ValueKey('email'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon Container
        Container(
          width: responsive.iconSize(70),
          height: responsive.iconSize(70),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF81C784),
                Color(0xFF4CAF50),
                Color(0xFF2E7D32),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.email_outlined,
            size: responsive.iconSize(35),
            color: Colors.white,
          ),
        ),
        SizedBox(height: responsive.spacing(20)),

        // Title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFA5D6A7)],
          ).createShader(bounds),
          child: Text(
            'Masukkan Email',
            style: TextStyle(
              fontSize: responsive.fontSize(22),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: responsive.spacing(6)),
        Text(
          'Kami akan mengirim kode verifikasi ke email Anda',
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: responsive.spacing(24)),

        // Email TextField
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'contoh@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          responsive: responsive,
        ),
        SizedBox(height: responsive.spacing(20)),

        // Submit Button
        _buildPrimaryButton(
          onPressed: _requestCode,
          text: 'Kirim Kode',
          icon: Icons.send_rounded,
          responsive: responsive,
        ),
      ],
    );
  }

  Widget _codeStep(ResponsiveUtils responsive) {
    return Column(
      key: const ValueKey('code'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon Container
        Container(
          width: responsive.iconSize(70),
          height: responsive.iconSize(70),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF81C784),
                Color(0xFF4CAF50),
                Color(0xFF2E7D32),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.security,
            size: responsive.iconSize(35),
            color: Colors.white,
          ),
        ),
        SizedBox(height: responsive.spacing(20)),

        // Title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFA5D6A7)],
          ).createShader(bounds),
          child: Text(
            'Masukkan Kode',
            style: TextStyle(
              fontSize: responsive.fontSize(22),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: responsive.spacing(6)),
        Text(
          'Kode dikirim ke',
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          _email,
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            color: const Color(0xFFA5D6A7),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: responsive.spacing(24)),

        // Code TextField
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: responsive.fontSize(24),
            fontWeight: FontWeight.bold,
            letterSpacing: 10,
          ),
          cursorColor: const Color(0xFFA5D6A7),
          decoration: InputDecoration(
            counterText: '',
            hintText: '------',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: responsive.fontSize(24),
              letterSpacing: 10,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(16),
              vertical: responsive.spacing(16),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFA5D6A7),
                width: 2,
              ),
            ),
          ),
        ),
        SizedBox(height: responsive.spacing(20)),

        // Verify Button
        _buildPrimaryButton(
          onPressed: _verifyCode,
          text: 'Verifikasi',
          icon: Icons.verified_outlined,
          responsive: responsive,
        ),
        SizedBox(height: responsive.spacing(8)),

        // Resend Button
        TextButton(
          onPressed: () => setState(() {
            _currentStep = 0;
            _codeController.clear();
          }),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(12),
              vertical: responsive.spacing(6),
            ),
          ),
          child: Text(
            'Kirim ulang kode',
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              color: const Color(0xFFA5D6A7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordStep(ResponsiveUtils responsive) {
    return Column(
      key: const ValueKey('password'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon Container
        Container(
          width: responsive.iconSize(70),
          height: responsive.iconSize(70),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF81C784),
                Color(0xFF4CAF50),
                Color(0xFF2E7D32),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.lock_reset,
            size: responsive.iconSize(35),
            color: Colors.white,
          ),
        ),
        SizedBox(height: responsive.spacing(20)),

        // Title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFA5D6A7)],
          ).createShader(bounds),
          child: Text(
            'Password Baru',
            style: TextStyle(
              fontSize: responsive.fontSize(22),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: responsive.spacing(6)),
        Text(
          'Buat password baru untuk akun Anda',
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: responsive.spacing(24)),

        // New Password TextField
        _buildTextField(
          controller: _newPasswordController,
          label: 'Password Baru',
          hint: '********',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          responsive: responsive,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white60,
              size: responsive.iconSize(20),
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        SizedBox(height: responsive.spacing(14)),

        // Confirm Password TextField
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Konfirmasi Password',
          hint: '********',
          icon: Icons.lock_person_outlined,
          obscureText: _obscureConfirmPassword,
          responsive: responsive,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white60,
              size: responsive.iconSize(20),
            ),
            onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
        SizedBox(height: responsive.spacing(20)),

        // Reset Button
        _buildPrimaryButton(
          onPressed: _resetPassword,
          text: 'Reset Password',
          icon: Icons.check_circle_outline,
          responsive: responsive,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ResponsiveUtils responsive,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: responsive.spacing(6)),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(
            color: Colors.white,
            fontSize: responsive.fontSize(15),
          ),
          cursorColor: const Color(0xFFA5D6A7),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: responsive.fontSize(14),
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.7),
                size: responsive.iconSize(20),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 46,
              minHeight: 46,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(16),
              vertical: responsive.spacing(14),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFA5D6A7),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    required ResponsiveUtils responsive,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: responsive.spacing(52),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF66BB6A),
              Color(0xFF43A047),
              Color(0xFF2E7D32),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: _isLoading
                  ? SizedBox(
                      width: responsive.iconSize(22),
                      height: responsive.iconSize(22),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: Colors.white,
                          size: responsive.iconSize(20),
                        ),
                        SizedBox(width: responsive.spacing(8)),
                        Text(
                          text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: responsive.fontSize(15),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
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

// Bubble Painter for Animated Background
class _BubblePainter extends CustomPainter {
  final double animation;
  final List<_Bubble> bubbles;

  _BubblePainter(this.animation)
      : bubbles = List.generate(15, (index) => _Bubble.random(index));

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      final y = (bubble.startY + animation * bubble.speed) % 1.2 - 0.1;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: bubble.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(bubble.x * size.width, y * size.height),
        bubble.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Bubble {
  final double x;
  final double startY;
  final double radius;
  final double speed;
  final double opacity;

  _Bubble({
    required this.x,
    required this.startY,
    required this.radius,
    required this.speed,
    required this.opacity,
  });

  factory _Bubble.random(int seed) {
    final random = Random(seed);
    return _Bubble(
      x: random.nextDouble(),
      startY: random.nextDouble(),
      radius: random.nextDouble() * 25 + 8,
      speed: random.nextDouble() * 0.4 + 0.1,
      opacity: random.nextDouble() * 0.12 + 0.03,
    );
  }
}
