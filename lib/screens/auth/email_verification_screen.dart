import 'package:buzzmate/screens/auth/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/email_service.dart';
import '../../theme/colors.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String userId;
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  String _generatedOTP = '';
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerified = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _sendOTP();
    
    // Clean up expired OTPs on screen load
    EmailService.cleanupExpiredOTPs();
    
    // Set up focus nodes to move to next field
    for (int i = 0; i < 5; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus && _otpControllers[i].text.isEmpty) {
          if (i > 0 && _otpControllers[i-1].text.isEmpty) {
            _focusNodes[i-1].requestFocus();
          }
        }
      });
    }
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    // Clean up any existing OTPs for this user
    await FirebaseFirestore.instance
        .collection('email_verifications')
        .doc(widget.userId)
        .delete();

    _generatedOTP = EmailService.generateOTP();
    
    // Store OTP in Firestore with expiration time
    await FirebaseFirestore.instance
        .collection('email_verifications')
        .doc(widget.userId)
        .set({
      'otp': _generatedOTP,
      'email': widget.email,
      'createdAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10))),
    });

    final success = await EmailService.sendOTP(widget.email, _generatedOTP);
    
    setState(() {
      _isResending = false;
      if (!success) {
        _errorMessage = 'Failed to send OTP. Please try again.';
      }
    });
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final enteredOTP = _otpControllers.map((controller) => controller.text).join();
    
    if (enteredOTP.length != 6) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    // Clean up expired OTPs before verification
    await EmailService.cleanupExpiredOTPs();

    // Get the stored OTP from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('email_verifications')
        .doc(widget.userId)
        .get();

    if (!doc.exists) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'OTP expired or not found. Please request a new one.';
      });
      return;
    }

    final storedOTP = doc.data()!['otp'] as String;
    final expiresAt = (doc.data()!['expiresAt'] as Timestamp).toDate();

    if (DateTime.now().isAfter(expiresAt)) {
      // Delete expired OTP
      await doc.reference.delete();
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'OTP expired. Please request a new one.';
      });
      return;
    }

    if (enteredOTP == storedOTP) {
      // Delete the used OTP
      await doc.reference.delete();
      
      // Mark email as verified in user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'emailVerified': true});

      setState(() {
        _isLoading = false;
        _isVerified = true;
      });

      // Navigate to profile setup after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileSetupScreen(userId: widget.userId),
            ),
          );
        }
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid OTP. Please try again.';
      });
    }
  }

  void _handleOTPChange(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-submit when all fields are filled
    if (index == 5 && value.isNotEmpty) {
      final allFilled = _otpControllers.every((controller) => controller.text.isNotEmpty);
      if (allFilled) {
        _verifyOTP();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: 20),

              // Title
              Center(
                child: Text(
                  "Verify Your Email",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              const SizedBox(height: 8),

              Center(
                child: Text(
                  "We sent a 6-digit code to ${widget.email}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // OTP Input Fields
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.textSecondary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                        onChanged: (value) => _handleOTPChange(index, value),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Success Message
              if (_isVerified)
                const Center(
                  child: Text(
                    "Email verified successfully!",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              const SizedBox(height: 24),

              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify Email',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Resend OTP
              Center(
                child: TextButton(
                  onPressed: _isResending ? null : _sendOTP,
                  child: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          "Resend OTP",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              // Timer countdown (optional enhancement)
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "OTP expires in 10 minutes",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}