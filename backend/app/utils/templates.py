from app.core.config import settings

def get_reset_password_html(token: str) -> str:
    """Return the HTML content for the password reset page."""
    return f"""
    <!DOCTYPE html>
    <html lang="tr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Şifre Sıfırlama - {settings.PROJECT_NAME}</title>
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
        <style>
            body {{ font-family: 'Inter', sans-serif; background: #f8f9fa; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }}
            .card {{ background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); width: 100%; max-width: 400px; }}
            h2 {{ color: #333; margin-top: 0; text-align: center; }}
            p {{ color: #666; font-size: 14px; text-align: center; margin-bottom: 30px; }}
            .form-group {{ margin-bottom: 20px; }}
            label {{ display: block; margin-bottom: 8px; color: #555; font-weight: 600; font-size: 14px; }}
            input {{ width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box; font-size: 16px; }}
            button {{ width: 100%; padding: 12px; background: #007bff; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer; font-size: 16px; margin-top: 10px; }}
            button:hover {{ background: #0056b3; }}
            .message {{ margin-top: 20px; text-align: center; font-size: 14px; display: none; padding: 10px; border-radius: 6px; }}
            .success {{ background: #d4edda; color: #155724; }}
            .error {{ background: #f8d7da; color: #721c24; }}
        </style>
    </head>
    <body>
        <div class="card">
            <h2>Şifre Sıfırlama</h2>
            <p>{settings.PROJECT_NAME} hesabınız için yeni bir şifre belirleyin.</p>
            <form id="resetForm">
                <input type="hidden" id="token" value="{token}">
                <div class="form-group">
                    <label for="new_password">Yeni Şifre</label>
                    <input type="password" id="new_password" required minlength="6">
                </div>
                <div class="form-group">
                    <label for="confirm_password">Yeni Şifre (Tekrar)</label>
                    <input type="password" id="confirm_password" required minlength="6">
                </div>
                <button type="submit">Şifreyi Güncelle</button>
            </form>
            <div id="statusMessage" class="message"></div>
        </div>

        <script>
            document.getElementById('resetForm').addEventListener('submit', async (e) => {{
                e.preventDefault();
                const token = document.getElementById('token').value;
                const new_password = document.getElementById('new_password').value;
                const confirm_password = document.getElementById('confirm_password').value;
                const messageDiv = document.getElementById('statusMessage');

                if (new_password !== confirm_password) {{
                    messageDiv.textContent = 'Şifreler eşleşmiyor.';
                    messageDiv.className = 'message error';
                    messageDiv.style.display = 'block';
                    return;
                }}

                try {{
                    const response = await fetch('/api/v1/auth/reset-password', {{
                        method: 'POST',
                        headers: {{ 'Content-Type': 'application/json' }},
                        body: JSON.stringify({{ token, new_password, confirm_password }})
                    }});

                    const data = await response.json();
                    if (response.ok) {{
                        messageDiv.textContent = 'Şifreniz başarıyla güncellendi! Giriş yapabilirsiniz.';
                        messageDiv.className = 'message success';
                        messageDiv.style.display = 'block';
                        document.getElementById('resetForm').style.display = 'none';
                    }} else {{
                        messageDiv.textContent = data.detail || 'Bir hata oluştu.';
                        messageDiv.className = 'message error';
                        messageDiv.style.display = 'block';
                    }}
                }} catch (error) {{
                    messageDiv.textContent = 'Sunucuyla bağlantı kurulamadı.';
                    messageDiv.className = 'message error';
                    messageDiv.style.display = 'block';
                }}
            }});
        </script>
    </body>
    </html>
    """

def get_reset_error_html(error_message: str) -> str:
    """Return the HTML content for the password reset error page."""
    return f"""
    <!DOCTYPE html>
    <html lang="tr">
    <head>
        <meta charset="UTF-8">
        <title>Hata - {settings.PROJECT_NAME}</title>
        <style>
            body {{ font-family: sans-serif; background: #f8f9fa; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }}
            .card {{ background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); width: 100%; max-width: 400px; text-align: center; }}
            h2 {{ color: #dc3545; }}
            a {{ display: inline-block; margin-top: 20px; color: #007bff; text-decoration: none; font-weight: bold; }}
        </style>
    </head>
    <body>
            <div class="card">
                <h2>Hata!</h2>
                <p>{error_message}</p>
                <p>Lütfen yeni bir şifre sıfırlama talebinde bulunun.</p>
            </div>
    </body>
    </html>
    """
