namespace :payments do
  namespace :polling do
    desc "Poll all pending payment transactions via Sidekiq"
    task poll_all: :environment do
      puts "🔍 Starting payment polling via Sidekiq at #{Time.current}"

      begin
        Payments::TransactionPollingService.poll_all_pending_transactions
        puts "✅ Payment polling jobs enqueued successfully"
        puts "📊 Check Sidekiq dashboard or run 'payments:polling:stats' for progress"
      rescue => e
        puts "❌ Payment polling failed: #{e.message}"
        puts e.backtrace.first(5).join("\n")
        Rails.logger.error "Payment polling failed: #{e.message}"
      end
    end

    desc "Start Sidekiq workers for payment polling"
    task start_workers: :environment do
      puts "🚀 Starting Sidekiq workers..."

      if defined?(Rails)
        # Check if Sidekiq is running
        begin
          require 'sidekiq/api'

          # Get Sidekiq processes
          processes = Sidekiq::ProcessSet.new

          if processes.size > 0
            puts "✅ Sidekiq is already running with #{processes.size} processes"
            processes.each do |process|
              puts "  📊 Process #{process['hostname']}: #{process['pid']} (#{process['tag']} workers)"
            end
          else
            puts "⚠️  Sidekiq processes not found"
            puts "💡 Start Sidekiq with: bundle exec sidekiq"
            puts "📊 Or use systemd for production: systemctl start sidekiq"
          end
        rescue LoadError
          puts "❌ Sidekiq not installed. Install with: gem install sidekiq"
        rescue => e
          puts "❌ Error checking Sidekiq status: #{e.message}"
        end
      else
        puts "❌ Rails not available in this context"
      end
    end

    desc "Clean up expired payment polls"
    task cleanup: :environment do
      puts "🧹 Cleaning up expired payment polls at #{Time.current}"

      begin
        Payments::TransactionPollingService.cleanup_expired_polls
        puts "✅ Cleanup completed successfully"
      rescue => e
        puts "❌ Cleanup failed: #{e.message}"
        Rails.logger.error "Payment polling cleanup failed: #{e.message}"
      end
    end

    desc "Show polling statistics and Sidekiq status"
    task stats: :environment do
      puts "📊 Payment Polling Statistics - #{Time.current}"
      puts "=" * 60

      stats = Payments::TransactionPollingService.get_polling_statistics

      puts "📈 Total Pending Payments: #{stats[:total_pending]}"
      puts "⏰ Pending (Last Hour): #{stats[:pending_last_hour]}"
      puts "🔄 Actively Polling: #{stats[:polling_active]}"
      puts "⏱️  Expired Polls: #{stats[:expired_polls]}"
      puts "📊 High Poll Count: #{stats[:high_poll_count]}"

      # Show Sidekiq queue status
      if defined?(Sidekiq)
        begin
          require 'sidekiq/api'

          # Get Redis info
          redis_info = Sidekiq.redis_info
          puts "\n🔄 Sidekiq & Redis Status:"
          puts "  🔗 Redis URL: #{Sidekiq::Client.redis.connection[:url]}"
          puts "  📊 Redis Version: #{redis_info['redis_version']}"
          puts "  📊 Connected Clients: #{redis_info['connected_clients']}"

          # Get queue stats
          stats = Sidekiq::Stats.new
          queue_stats = stats.queues['payments']
          if queue_stats
            puts "\n📊 Payments Queue Status:"
            puts "  📊 Queue Size: #{queue_stats['size'] || 0}"
            puts "  📊 Latency: #{queue_stats['latency'] || 0}s"
          end

          # Get process info
          processes = Sidekiq::ProcessSet.new
          if processes.size > 0
            puts "\n👷 Sidekiq Processes:"
            processes.each do |process|
              puts "  🖥️ #{process['hostname']} (PID: #{process['pid']})"
              puts "    📊 Tag: #{process['tag']}"
              puts "    📊 Concurrency: #{process['concurrency']}"
              puts "    📊 Busy: #{process['busy']}"
              puts "    📊 Quiet: #{process['quiet']}"
            end
          end

        rescue LoadError
          puts "\n⚠️  Sidekiq API not available (install sidekiq-api gem)"
        rescue => e
          puts "\n⚠️  Could not fetch Sidekiq stats: #{e.message}"
        end
      else
        puts "\n⚠️  Sidekiq not available in this context"
      end

      # Show payment gateway status
      puts "\n💳 Payment Gateway Status:"
      PaymentGateway.active.each do |gateway|
        status = "🟢 Active"
        puts "  • #{gateway.name} (#{gateway.gateway_type}): #{status}"
      end

      # Show recent polling activity
      puts "\n📋 Recent Polling Activity:"
      recent_logs = PaymentLog
        .where(event_type: 'polling_error')
        .order(created_at: :desc)
        .limit(5)

      if recent_logs.any?
        recent_logs.each do |log|
          puts "  • #{log.created_at.strftime('%H:%M:%S')} - Payment #{log.payment_id}: #{log.error_message}"
        end
      else
        puts "  ✅ No recent polling errors"
      end
    end

    desc "Test Paystack API connection"
    task test_paystack: :environment do
      puts "🧪 Testing Paystack API connection..."

      begin
        gateway = PaymentGateway.active_for_type('paystack')
        unless gateway
          puts "❌ No active Paystack gateway found"
          exit 1
        end

        service = Paystack::PaystackService.new(gateway)
        result = service.test_connection

        if result[:success]
          puts "✅ Paystack API connection successful"
          puts "📊 Response: #{result[:message]}"
        else
          puts "❌ Paystack API connection failed"
          puts "📊 Error: #{result[:message]}"
        end
      rescue => e
        puts "❌ Test failed: #{e.message}"
        puts e.backtrace.first(3).join("\n")
      end
    end

    desc "Create test payment and start polling"
    task test_payment: :environment do
      puts "🧪 Creating test payment for polling..."

      begin
        # Get test user and course
        user = User.find_by(email: 'student@lms.test')
        course = Course.first

        unless user && course
          puts "❌ Test user or course not found. Run rails db:seed first."
          exit 1
        end

        # Create test payment
        payment = Payment.create_for_course(user, course, 'paystack')

        puts "✅ Created test payment: #{payment.name}"
        puts "💰 Amount: #{payment.amount} #{payment.currency}"
        puts "📧 User: #{user.email}"
        puts "📚 Course: #{course.title}"

        # Start polling
        payment.start_polling!
        puts "🔄 Started polling for payment #{payment.id}"
        puts "📊 Run 'rails payments:polling:stats' to monitor progress"

      rescue => e
        puts "❌ Test payment creation failed: #{e.message}"
        puts e.backtrace.first(3).join("\n")
      end
    end

    desc "Monitor specific payment"
    task :monitor, [:payment_id] => :environment do |t, args|
      payment_id = args[:payment_id]

      unless payment_id
        puts "❌ Please provide a payment ID: rails payments:polling:monitor[123]"
        exit 1
      end

      puts "🔍 Monitoring payment #{payment_id}..."

      begin
        payment = Payment.find(payment_id)

        puts "💰 Payment Details:"
        puts "  • ID: #{payment.name}"
        puts "  • Amount: #{payment.amount} #{payment.currency}"
        puts "  • Status: #{payment.payment_status}"
        puts "  • Method: #{payment.payment_method}"
        puts "  • Created: #{payment.created_at}"
        puts "  • Poll Count: #{payment.poll_count}"
        puts "  • Last Polled: #{payment.last_polled_at}"
        puts "  • Polling Expires: #{payment.polling_expires_at}"
        puts "  • Auto Verification: #{payment.auto_verification_enabled ? 'Yes' : 'No'}"

        # Show recent logs
        puts "\n📋 Recent Activity:"
        PaymentLog
          .where(payment: payment)
          .order(created_at: :desc)
          .limit(10)
          .each do |log|
            status_icon = case log.status
                        when 'success' then '✅'
                        when 'error' then '❌'
                        when 'warning' then '⚠️'
                        else 'ℹ️'
                  end
            puts "  #{status_icon} #{log.created_at.strftime('%H:%M:%S')} - #{log.event_type}: #{log.error_message || 'Success'}"
          end

      rescue ActiveRecord::RecordNotFound
        puts "❌ Payment #{payment_id} not found"
      rescue => e
        puts "❌ Error monitoring payment: #{e.message}"
      end
    end

    desc "Setup Sidekiq instructions"
    task setup_sidekiq: :environment do
      puts "🚀 Sidekiq Setup Instructions"
      puts "=" * 60
      puts
      puts "📦 Installation:"
      puts "  gem install sidekiq sidekiq-status"
      puts "  bundle install"
      puts
      puts "🔧 Development Setup:"
      puts "  # Start Sidekiq in development"
      puts "  bundle exec sidekiq"
      puts
      puts "  # Or start with specific queue"
      puts "  bundle exec sidekiq -q payments"
      puts
      puts "🏭 Production Setup:"
      puts "  # Using systemd (recommended)"
      puts "  sudo systemctl enable sidekiq"
      puts "  sudo systemctl start sidekiq"
      puts "  sudo systemctl status sidekiq"
      puts
      puts "  # Using foreman (alternative)"
      puts "  gem install foreman"
      puts "  echo 'bundle exec sidekiq' > Procfile.dev"
      puts "  foreman start -f Procfile.dev"
      puts
      puts "📊 Monitoring:"
      puts "  # Sidekiq Web UI (add to routes.rb)"
      puts "  mount Sidekiq::Web => '/sidekiq'"
      puts "  # Visit: http://localhost:3000/sidekiq"
      puts
      puts "  # Command line monitoring"
      puts "  bundle exec rake payments:polling:stats"
      puts "  bundle exec sidekiq stats"
      puts
      puts "⚙️  Configuration (config/sidekiq.yml):"
      puts "  :concurrency: 5"
      puts "  :queues:"
      puts "    - default"
      puts "    - payments"
      puts "  :polling:"
      puts "    :concurrency: 2"
      puts "    :queues:"
      puts "      - payments"
      puts
      puts "🔄 Automatic Polling:"
      puts "  # Polling jobs are automatically enqueued when payments are created"
      puts "  # No cron job needed - Sidekiq handles the scheduling"
      puts "  # Jobs retry automatically with exponential backoff"
      puts "  # Dead jobs are moved to Dead Letter Queue for inspection"
      puts
      puts "📝 Environment Variables:"
      puts "  REDIS_URL=redis://localhost:6379/0"
      puts "  SIDEKIQ_CONCURRENCY=5"
      puts "  RAILS_ENV=production"
      puts
      puts "🔍 Troubleshooting:"
      puts "  # Check Sidekiq status"
      puts "  bundle exec rake payments:polling:start_workers"
      puts "  bundle exec rake payments:polling:stats"
      puts
      puts "  # Check Redis connection"
      puts "  redis-cli ping"
      puts
      puts "  # Check Sidekiq logs"
      puts "  tail -f log/sidekiq.log"
      puts
      puts "  # Restart Sidekiq"
      puts "  sudo systemctl restart sidekiq"
      puts
      puts "🎯 Benefits over Cron:"
      puts "  ✅ Real-time job processing"
      puts "  ✅ Automatic retries with exponential backoff"
      puts "  ✅ Web UI for monitoring"
      puts "  ✅ Dead Letter Queue for failed jobs"
      puts "  ✅ Concurrency control"
      puts "  ✅ Memory-efficient processing"
      puts "  ✅ Better error handling and logging"
      puts "  ✅ Works seamlessly with Rails"
    end
  end
end
