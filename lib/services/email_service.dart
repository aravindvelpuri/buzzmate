import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static final String smtpUsername = 'projects.aravind@gmail.com';
  static final String smtpPassword = 'ehan hdrj uaqr uwlc';

  static final SmtpServer smtpServer = gmail(smtpUsername, smtpPassword);

  // Generate a random 6-digit OTP
  static String generateOTP() {
    Random random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP email with professional styling
  static Future<bool> sendOTP(String email, String otp) async {
    try {
      final message = Message()
        ..from = Address(smtpUsername, 'BuzzMate Team')
        ..recipients.add(email)
        ..subject = 'BuzzMate - Email Verification Code'
        ..text = 'Your verification code is: $otp\n\nThis code will expire in 10 minutes.'
        ..html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BuzzMate Email Verification</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #F5F5F5;">
    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #F5F5F5; padding: 40px 0;">
        <tr>
            <td align="center">
                <table width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width: 600px; background-color: #FFFFFF; border-radius: 12px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); overflow: hidden;">
                    <!-- Header -->
                    <tr>
                        <td style="background-color: #6A1B9A; padding: 30px; text-align: center;">
                            <h1 style="color: #FFFFFF; margin: 0; font-size: 28px; font-weight: bold;">BuzzMate</h1>
                            <p style="color: #FFFFFF; margin: 10px 0 0 0; font-size: 16px; opacity: 0.9;">Email Verification</p>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px 30px; text-align: center;">
                            <h2 style="color: #212121; margin: 0 0 20px 0; font-size: 24px;">Verify Your Email Address</h2>
                            <p style="color: #757575; margin: 0 0 30px 0; font-size: 16px; line-height: 1.5;">
                                Thank you for joining BuzzMate! To complete your registration, please use the following verification code:
                            </p>
                            
                            <!-- OTP Code -->
                            <div style="background-color: #F5F5F5; padding: 20px; border-radius: 12px; margin: 0 0 30px 0;">
                                <p style="color: #757575; margin: 0 0 10px 0; font-size: 14px;">Your verification code:</p>
                                <div style="background-color: #6A1B9A; color: #FFFFFF; font-size: 32px; font-weight: bold; letter-spacing: 8px; padding: 15px; border-radius: 8px; display: inline-block;">
                                    $otp
                                </div>
                            </div>
                            
                            <!-- Instructions -->
                            <p style="color: #757575; margin: 0 0 20px 0; font-size: 14px;">
                                <strong>Important:</strong> This code will expire in <strong>10 minutes</strong> for security reasons.
                            </p>
                            
                            <p style="color: #757575; margin: 0; font-size: 14px;">
                                If you didn't request this code, please ignore this email.
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #F5F5F5; padding: 20px; text-align: center;">
                            <p style="color: #757575; margin: 0 0 10px 0; font-size: 12px;">
                                &copy; 2024 BuzzMate. All rights reserved.
                            </p>
                            <p style="color: #757575; margin: 0; font-size: 12px;">
                                This is an automated message, please do not reply to this email.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
        ''';

      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  // Clean up expired OTPs from database
  static Future<void> cleanupExpiredOTPs() async {
    try {
      final now = Timestamp.now();
      final expiredOTPs = await FirebaseFirestore.instance
          .collection('email_verifications')
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in expiredOTPs.docs) {
        batch.delete(doc.reference);
      }
      
      if (expiredOTPs.docs.isNotEmpty) {
        await batch.commit();
        print('Cleaned up ${expiredOTPs.docs.length} expired OTPs');
      }
    } catch (e) {
      print('Error cleaning up expired OTPs: $e');
    }
  }
}