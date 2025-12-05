class AuthController < ApplicationController
  def login_page
    # Serve a simple login form
    render html: <<~HTML.html_safe
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Login - LMS</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 400px; margin: 50px auto; padding: 20px; }
          .form-group { margin-bottom: 15px; }
          label { display: block; margin-bottom: 5px; }
          input { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }
          button { width: 100%; padding: 10px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; }
          button:hover { background: #0056b3; }
          .error { color: red; margin-bottom: 10px; }
        </style>
      </head>
      <body>
        <h2>Login to LMS</h2>
        <div id="error" class="error" style="display: none;"></div>
        <form id="loginForm">
          <div class="form-group">
            <label for="email">Email:</label>
            <input type="email" id="email" required>
          </div>
          <div class="form-group">
            <label for="password">Password:</label>
            <input type="password" id="password" required>
          </div>
          <button type="submit">Login</button>
        </form>
        <p style="margin-top: 20px; text-align: center;">
          Don't have an account? <a href="/signup">Sign up</a>
        </p>

        <script>
          document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;

            try {
              const response = await fetch('/api/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ usr: email, pwd: password })
              });

              if (response.ok) {
                window.location.href = '/lms';
              } else {
                const error = await response.json();
                document.getElementById('error').textContent = error.message || 'Login failed';
                document.getElementById('error').style.display = 'block';
              }
            } catch (error) {
              document.getElementById('error').textContent = 'Network error';
              document.getElementById('error').style.display = 'block';
            }
          });
        </script>
      </body>
      </html>
    HTML
  end

  def signup_page
    # Serve a simple signup form
    render html: <<~HTML.html_safe
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Sign Up - LMS</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 400px; margin: 50px auto; padding: 20px; }
          .form-group { margin-bottom: 15px; }
          label { display: block; margin-bottom: 5px; }
          input { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }
          button { width: 100%; padding: 10px; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer; }
          button:hover { background: #218838; }
          .error { color: red; margin-bottom: 10px; }
          .success { color: green; margin-bottom: 10px; }
        </style>
      </head>
      <body>
        <h2>Sign Up for LMS</h2>
        <div id="error" class="error" style="display: none;"></div>
        <div id="success" class="success" style="display: none;"></div>
        <form id="signupForm">
          <div class="form-group">
            <label for="fullName">Full Name:</label>
            <input type="text" id="fullName" required>
          </div>
          <div class="form-group">
            <label for="email">Email:</label>
            <input type="email" id="email" required>
          </div>
          <div class="form-group">
            <label for="password">Password:</label>
            <input type="password" id="password" required minlength="6">
          </div>
          <button type="submit">Sign Up</button>
        </form>
        <p style="margin-top: 20px; text-align: center;">
          Already have an account? <a href="/login">Login</a>
        </p>

        <script>
          document.getElementById('signupForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value;
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;

            try {
              const response = await fetch('/api/signup', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  signup_email: email,
                  full_name: fullName,
                  password: password
                })
              });

              const result = await response.json();

              if (response.ok && result.user_id) {
                document.getElementById('success').textContent = result.message;
                document.getElementById('success').style.display = 'block';
                document.getElementById('error').style.display = 'none';
                setTimeout(() => {
                  window.location.href = '/login';
                }, 2000);
              } else {
                document.getElementById('error').textContent = result.message || 'Signup failed';
                document.getElementById('error').style.display = 'block';
                document.getElementById('success').style.display = 'none';
              }
            } catch (error) {
              document.getElementById('error').textContent = 'Network error';
              document.getElementById('error').style.display = 'block';
              document.getElementById('success').style.display = 'none';
            }
          });
        </script>
      </body>
      </html>
    HTML
  end
end
