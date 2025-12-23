import smtplib
from email.mime.text import MIMEText
from core.config import EMAIL_ALERTS

def send_email(subject: str, message: str):
    if not EMAIL_ALERTS.get("enabled"):
        return

    msg = MIMEText(message)
    msg["Subject"] = subject
    msg["From"] = EMAIL_ALERTS["sender"]
    msg["To"] = EMAIL_ALERTS["receiver"]

    try:
        with smtplib.SMTP(
            EMAIL_ALERTS["smtp_server"],
            EMAIL_ALERTS["smtp_port"]
        ) as server:
            server.starttls()
            server.login(
                EMAIL_ALERTS["sender"],
                EMAIL_ALERTS["password"]
            )
            server.send_message(msg)
    except Exception as e:
        print(f"[ALERT ERROR] Failed to send email: {e}")