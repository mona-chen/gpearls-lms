module Search
  class LinksService
    def self.call(params = {})
      new(params).call
    end

    def initialize(params = {})
      @params = params
    end

    def call
      query = @params[:q]
      return [] if query.blank?

      results = []

      # Search courses
      if @params[:doctype].blank? || @params[:doctype] == "Course"
        courses = Course.where("title ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
                       .limit(5)
        results += courses.map do |course|
          {
            name: course.title,
            type: "Course",
            url: "/courses/#{course.id}",
            description: course.description&.truncate(100),
            image: course.image
          }
        end
      end

      # Search batches
      if @params[:doctype].blank? || @params[:doctype] == "Batch"
        batches = Batch.where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
                      .limit(5)
        results += batches.map do |batch|
          {
            name: batch.name,
            type: "Batch",
            url: "/batches/#{batch.id}",
            description: batch.description&.truncate(100),
            start_date: batch.start_date
          }
        end
      end

      # Search users (if applicable)
      if @params[:doctype].blank? || @params[:doctype] == "User"
        users = User.where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
                          "%#{query}%", "%#{query}%", "%#{query}%")
                   .limit(5)
        results += users.map do |user|
          {
            name: user.full_name,
            type: "User",
            url: "/users/#{user.id}",
            description: user.email,
            image: user.user_image
          }
        end
      end

      results
    end
  end
end
