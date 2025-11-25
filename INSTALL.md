# LMS Installation Guide

This guide provides step-by-step instructions for installing and setting up the Learning Management System (LMS), which is a complete replica of Frappe LMS functionality.

## Prerequisites

Before installing the LMS, ensure you have the following:

### System Requirements
- **Ruby**: 3.3.3 (recommended) or 3.2.3 (minimum)
- **Rails**: 7.0+
- **Database**: PostgreSQL 12+ or SQLite 3+ (PostgreSQL recommended for production)
- **Node.js**: 16+ (for frontend assets)
- **Yarn**: Latest version (for package management)

### Hardware Requirements
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 5GB free space
- **CPU**: 1 core minimum, 2+ cores recommended

## Installation Methods

### Method 1: Automated Setup (Recommended)

#### Step 1: Install Ruby Version Manager
```bash
# Install rbenv (recommended)
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Add to your shell
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install Ruby 3.3.3
rbenv install 3.3.3
rbenv global 3.3.3
```

#### Step 2: Clone and Setup
```bash
# Clone the repository
git clone <repository-url> lms
cd lms

# Install Ruby dependencies
bundle install

# Install Node.js dependencies
yarn install

# Setup database
rails db:create
rails db:migrate

# Run automated installation
rails lms:setup
```

#### Step 3: Start the Application
```bash
# Start Rails server
rails server

# In another terminal, start frontend assets
yarn dev
```

#### Step 4: Access Setup Wizard
Open your browser and navigate to `http://localhost:3000/setup` to complete the web-based setup wizard.

### Method 2: Manual Setup

#### Database Setup
```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Seed initial data
rails lms:install
rails lms:sync
```

#### Environment Configuration
Create `.env` file:
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost/lms

# Email (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# File Storage (optional)
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_REGION=us-east-1
AWS_BUCKET=your-bucket

# Payment Gateways (optional)
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
```

#### Web Server Setup
```bash
# For development
rails server

# For production (using Puma)
bundle exec puma -C config/puma.rb
```

## Setup Wizard

The LMS includes a comprehensive web-based setup wizard that guides you through the initial configuration. The wizard consists of the following steps:

### Step 1: Welcome
- Database connection verification
- File system permissions check
- System requirements validation

### Step 2: Site Settings
- **Site Name**: Display name for your LMS
- **Site Description**: Brief description of your platform
- **Default Currency**: Primary currency for transactions
- **Default Timezone**: System-wide timezone setting
- **Registration Settings**: Enable/disable user registration
- **Course Visibility**: Public access to courses

### Step 3: Administrator Account
- **Full Name**: Administrator's complete name
- **Username**: Unique username for login
- **Email**: Administrator email address
- **Password**: Secure password (minimum 8 characters)

### Step 4: Payment Settings (Optional)
- **Enable Payments**: Toggle payment processing
- **Default Gateway**: Choose Stripe, PayPal, or other
- **API Keys**: Configure payment gateway credentials
- **Currency Settings**: Multi-currency support

### Step 5: Email Settings (Optional)
- **SMTP Configuration**: Email server settings
- **From Address**: Default sender email
- **Notification Settings**: Email notification preferences

### Step 6: Completion
- **Final Setup**: Database seeding and role assignment
- **Welcome Message**: Administrator notification
- **Next Steps**: Post-installation guidance

## Post-Installation Configuration

### 1. Email Configuration
```bash
# Configure SMTP settings in LMS Settings
# Or set environment variables
export SMTP_HOST=smtp.gmail.com
export SMTP_PORT=587
export SMTP_USERNAME=your-email@gmail.com
export SMTP_PASSWORD=your-app-password
```

### 2. File Storage
```bash
# For AWS S3
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
export AWS_REGION=us-east-1
export AWS_BUCKET=your-bucket

# For local storage (default)
# Files stored in public/uploads/
```

### 3. Payment Gateways
```bash
# Stripe
export STRIPE_PUBLISHABLE_KEY=pk_live_...
export STRIPE_SECRET_KEY=sk_live_...

# PayPal
export PAYPAL_CLIENT_ID=your-client-id
export PAYPAL_CLIENT_SECRET=your-client-secret
```

### 4. Background Jobs
```bash
# Install Redis (required for Sidekiq)
# Ubuntu/Debian
sudo apt-get install redis-server

# Start Sidekiq
bundle exec sidekiq

# Or use systemd service
sudo systemctl enable sidekiq
sudo systemctl start sidekiq
```

## Verification

After installation, verify everything is working:

```bash
# Check installation status
rails lms:status

# Run tests
bundle exec rspec

# Check system health
curl http://localhost:3000/api/health
```

## Troubleshooting

### Common Issues

#### Ruby Version Issues
```bash
# Check Ruby version
ruby --version

# Install correct version
rbenv install 3.3.3
rbenv global 3.3.3
```

#### Database Connection
```bash
# Check database connection
rails db:migrate:status

# Reset database if needed
rails db:reset
rails lms:setup
```

#### Permission Issues
```bash
# Fix file permissions
chmod -R 755 tmp/
chmod -R 755 log/
chmod -R 755 public/uploads/
```

#### Email Not Working
```bash
# Test email configuration
rails console
ActionMailer::Base.delivery_method
# Should show :smtp or :sendmail
```

## Production Deployment

### Using Docker
```dockerfile
FROM ruby:3.3.3

WORKDIR /app
COPY Gemfile* ./
RUN bundle install

COPY . .
RUN rails assets:precompile

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
```

### Using Capistrano
```ruby
# config/deploy.rb
set :application, "lms"
set :repo_url, "git@github.com:your-org/lms.git"
set :deploy_to, "/var/www/lms"

# Add deployment tasks
namespace :deploy do
  after :published, :restart
end
```

### Nginx Configuration
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /cable {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Backup and Recovery

### Database Backup
```bash
# PostgreSQL
pg_dump lms_production > lms_backup.sql

# SQLite
cp db/production.sqlite3 db/backup.sqlite3
```

### File Backup
```bash
# Backup uploaded files
tar -czf uploads_backup.tar.gz public/uploads/
```

### Recovery
```bash
# Restore database
psql lms_production < lms_backup.sql

# Restore files
tar -xzf uploads_backup.tar.gz
```

## Support

For additional support:
- Check the logs: `tail -f log/production.log`
- Run diagnostics: `rails lms:status`
- View API documentation: `/api/docs`
- Check system health: `/api/health`

## Migration from Frappe LMS

If you're migrating from Frappe LMS:

1. Export your Frappe data
2. Use the import scripts in `lib/tasks/import.rake`
3. Run data migrations
4. Update user passwords (Frappe uses different hashing)
5. Test all functionality

The LMS provides exact API compatibility with Frappe LMS, ensuring seamless migration.