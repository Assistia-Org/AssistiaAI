import resend
from app.core.config import settings

def send_password_reset_email(email: str, token: str) -> bool:
    """
    Send a password reset email using Resend.
    Returns True if successful, False otherwise.
    """
    resend.api_key = settings.RESEND_API_KEY
    
    subject = "Password Reset Request"
    # Link pointing directly to the backend HTML reset page
    reset_link = f"{settings.BACKEND_URL}/api/v1/auth/reset-password?token={token}" 
    
    html_content = f"""
    <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
        <h2 style="color: #333; text-align: center;">Şifre Sıfırlama Talebi</h2>
        <p>Hesabınız için bir şifre sıfırlama talebi aldık. Şifrenizi sıfırlamak için aşağıdaki butona tıklayabilirsiniz:</p>
        
        <div style="text-align: center; margin: 30px 0;">
            <a href="{reset_link}" style="background-color: #007bff; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">
                Şifremi Sıfırla
            </a>
        </div>
        
        <p>Eğer butona tıklayamıyorsanız aşağıdaki bağlantıyı tarayıcınıza kopyalayabilirsiniz:</p>
        <p style="word-break: break-all; color: #007bff;">{reset_link}</p>
        
        <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
        <p style="color: #888; font-size: 13px;">Eğer bu talebi siz yapmadıysanız bu e-postayı görmezden gelebilirsiniz.</p>
        <p style="color: #888; font-size: 13px;">Bu bağlantı 1 saat içinde geçerliliğini yitirecektir.</p>
    </div>
    """
    
    params = {
        "from": settings.EMAILS_FROM_EMAIL,
        "to": email,
        "subject": subject,
        "html": html_content,
    }

    try:
        resend.Emails.send(params)
        return True
    except Exception as e:
        print(f"Error sending email: {e}")
        return False
