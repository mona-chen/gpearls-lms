module Payments
  class BillingAccessService
    def self.call(params, user)
      new(params, user).call
    end

    def initialize(params, user)
      @params = params
      @user = user
    end

    def call
      return error_response("User not found") unless @user
      return error_response("Item type is required") unless @params[:item_type]
      return error_response("Item ID is required") unless @params[:item_id]

      item = find_item
      return error_response("Item not found") unless item

      access_info = check_billing_access(item)

      success_response(access_info)
    end

    private

    def find_item
      case @params[:item_type]
      when "course"
        Course.find_by(id: @params[:item_id])
      when "batch"
        Batch.find_by(id: @params[:item_id])
      when "program"
        LmsProgram.find_by(id: @params[:item_id])
      else
        nil
      end
    end

    def check_billing_access(item)
      has_access = user_has_access?(item)
      is_paid = item_is_paid?(item)
      payment_required = is_paid && !has_access

      access_info = {
        item_type: @params[:item_type],
        item_id: @params[:item_id],
        item_name: get_item_name(item),
        has_access: has_access,
        is_paid: is_paid,
        payment_required: payment_required,
        access_granted_at: get_access_granted_at(item),
        payment_status: get_payment_status(item)
      }

      # Add pricing information if payment is required
      if payment_required
        access_info.merge!(get_pricing_info(item))
      end

      access_info
    end

    def user_has_access?(item)
      case item.class.name
      when "Course"
        Enrollment.exists?(user: @user, course: item)
      when "Batch"
        BatchEnrollment.exists?(user: @user, batch: item)
      when "LmsProgram"
        LmsProgramMember.exists?(user: @user, lms_program: item)
      else
        false
      end
    end

    def item_is_paid?(item)
      case item.class.name
      when "Course"
        item.course_price.present? && item.course_price > 0
      when "Batch"
        item.paid_batch?
      when "LmsProgram"
        item.price.present? && item.price > 0
      else
        false
      end
    end

    def get_item_name(item)
      case item.class.name
      when "Course"
        item.title
      when "Batch"
        item.title
      when "LmsProgram"
        item.title
      else
        "Unknown Item"
      end
    end

    def get_access_granted_at(item)
      case item.class.name
      when "Course"
        enrollment = Enrollment.find_by(user: @user, course: item)
        enrollment&.created_at&.strftime("%Y-%m-%d %H:%M:%S")
      when "Batch"
        enrollment = BatchEnrollment.find_by(user: @user, batch: item)
        enrollment&.created_at&.strftime("%Y-%m-%d %H:%M:%S")
      when "LmsProgram"
        membership = LmsProgramMember.find_by(user: @user, lms_program: item)
        membership&.created_at&.strftime("%Y-%m-%d %H:%M:%S")
      else
        nil
      end
    end

    def get_payment_status(item)
      case item.class.name
      when "Course"
        payment = Payment.find_by(user: @user, course: item)
        payment&.payment_status
      when "Batch"
        payment = Payment.find_by(user: @user, batch: item)
        payment&.payment_status
      when "LmsProgram"
        payment = Payment.find_by(user: @user, program: item)
        payment&.payment_status
      else
        nil
      end
    end

    def get_pricing_info(item)
      case item.class.name
      when "Course"
        {
          price: item.course_price,
          currency: item.currency || "USD",
          discount_price: item.discount_price,
          discount_valid_until: item.discount_valid_until&.strftime("%Y-%m-%d %H:%M:%S")
        }
      when "Batch"
        {
          price: item.amount,
          currency: item.currency || "USD"
        }
      when "LmsProgram"
        {
          price: item.price,
          currency: item.currency || "USD"
        }
      else
        {}
      end
    end

    def success_response(data)
      {
        success: true,
        data: data
      }
    end

    def error_response(message)
      {
        success: false,
        error: message
      }
    end
  end
end
