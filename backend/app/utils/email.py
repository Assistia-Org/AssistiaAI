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

def send_verification_code_email(email: str, code: str) -> bool:
    """
    Send a 6-digit verification code email using Resend.
    Returns True if successful, False otherwise.
    """
    resend.api_key = settings.RESEND_API_KEY
    
    subject = f"Doğrulama Kodunuz: {code}"
    
    html_content = f"""
    <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; background-color: #f9f9f9;">
        <h2 style="color: #333; text-align: center;">E-posta Doğrulama</h2>
        <p style="text-align: center;">Uygulamamıza giriş yapmak veya işlem yapmak için kullanacağınız doğrulama kodunuz aşağıdadır:</p>
        
        <div style="text-align: center; margin: 30px 0;">
            <div style="background-color: #fff; border: 2px solid #007bff; color: #007bff; padding: 15px 30px; font-size: 32px; font-weight: bold; border-radius: 5px; display: inline-block; letter-spacing: 5px;">
                {code}
            </div>
        </div>
        
        <p style="text-align: center; color: #888; font-size: 14px;">Bu kod 5 dakika içerisinde geçerliliğini yitirecektir.</p>
        
        <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
        <p style="color: #aaa; font-size: 12px; text-align: center;">Eğer bu işlemi siz yapmadıysanız bu e-postayı dikkate almayınız.</p>
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
        print(f"Error sending verification email: {e}")
        return False
