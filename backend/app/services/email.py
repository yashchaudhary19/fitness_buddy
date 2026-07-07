import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging
import httpx
from app.core.config import settings

logger = logging.getLogger("nutritrack.email")

async def send_otp_email(to_email: str, otp_code: str) -> bool:
    """Send OTP code to user's email address."""
    subject = f"Your NutriVault Verification Code: {otp_code}"
    body = (
        f"Hello,\n\n"
        f"Your verification code for logging into NutriVault is: {otp_code}\n\n"
        f"This code will expire in 5 minutes.\n\n"
        f"If you did not request this code, please ignore this email.\n\n"
        f"Best regards,\n"
        f"The NutriVault Team"
    )

    # Log/Print OTP for local testing/development
    logger.info("==================================================")
    logger.info(f"OTP SEND REQUESTED: To: {to_email} | Code: {otp_code}")
    logger.info("==================================================")
    print(f"\n[EMAIL SIMULATION] Sending OTP {otp_code} to {to_email}\n")

    # If SMTP password/API key is not configured, treat simulated send as successful
    if not settings.SMTP_PASSWORD:
        logger.info("SMTP settings not configured. Simulated email delivery successfully.")
        return True

    # 1. Check if we should use Resend HTTPS API (starts with re_)
    if settings.SMTP_PASSWORD.startswith("re_"):
        url = "https://api.resend.com/emails"
        headers = {
            "Authorization": f"Bearer {settings.SMTP_PASSWORD}",
            "Content-Type": "application/json"
        }
        payload = {
            "from": settings.SMTP_FROM_EMAIL or "onboarding@resend.dev",
            "to": to_email,
            "subject": subject,
            "text": body
        }
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(url, headers=headers, json=payload)
                if resp.status_code in (200, 201, 202):
                    logger.info(f"Successfully sent Resend HTTPS email to {to_email}")
                    return True
                else:
                    logger.error(f"Resend HTTPS API returned error {resp.status_code}: {resp.text}")
        except Exception as e:
            logger.error(f"Failed to send Resend HTTPS email: {e}")

    # 2. Fallback to standard SMTP if Resend fails or SMTP is not Resend
    if not settings.SMTP_HOST or not settings.SMTP_USER:
        logger.warning("SMTP host/user not configured. Cannot fall back.")
        if settings.ENVIRONMENT == "development":
            return True
        return False

    try:
        msg = MIMEMultipart()
        msg["From"] = settings.SMTP_FROM_EMAIL or settings.SMTP_USER
        msg["To"] = to_email
        msg["Subject"] = subject

        msg.attach(MIMEText(body, "plain"))

        # Connect to SMTP server
        if settings.SMTP_PORT == 465:
            server = smtplib.SMTP_SSL(settings.SMTP_HOST, settings.SMTP_PORT)
        else:
            server = smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT)
            if settings.SMTP_PORT == 587:
                server.starttls()
        
        server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
        server.sendmail(msg["From"], to_email, msg.as_string())
        server.quit()
        logger.info(f"Successfully sent SMTP email to {to_email}")
        return True
    except Exception as e:
        logger.error(f"Failed to send SMTP email: {e}")
        # Return True for development environment even if SMTP fails so testing is not blocked
        if settings.ENVIRONMENT == "development":
            return True
        return False
