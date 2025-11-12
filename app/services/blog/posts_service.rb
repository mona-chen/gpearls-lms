module Blog
  class PostsService
    def self.call(params = {})
      new(params).call
    end

    def initialize(params = {})
      @params = params
    end

    def call
      posts = BlogPost.includes(:author).where(published: true)

      # Apply filters from request
      if @params[:filters].present?
        filters = @params[:filters].to_unsafe_h
        posts = posts.where(category: filters['category']) if filters['category'].present?
        posts = posts.where(author_id: filters['author']) if filters['author'].present?
      end

      # Apply search
      if @params[:search].present?
        posts = posts.where('title ILIKE ? OR content ILIKE ?',
                           "%#{@params[:search]}%", "%#{@params[:search]}%")
      end

      # Apply pagination
      limit = @params[:limit] || 10
      offset = @params[:start] || 0
      posts = posts.limit(limit).offset(offset)

      posts_data = posts.map do |post|
        {
          name: post.title,
          title: post.title,
          post_id: post.id,
          author: post.author&.full_name,
          author_id: post.author_id,
          category: post.category,
          tags: post.tags&.split(',') || [],
          excerpt: post.excerpt,
          content: post.content,
          featured_image: post.featured_image,
          published: post.published,
          creation: post.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          modified: post.updated_at.strftime('%Y-%m-%d %H:%M:%S'),
          reading_time: calculate_reading_time(post.content),
          view_count: post.view_count || 0
        }
      end

      { 'data' => posts_data }
    end

    private

    def calculate_reading_time(content)
      return 0 if content.blank?
      words_per_minute = 200
      word_count = content.split.size
      (word_count / words_per_minute.to_f).ceil
    end
  end
end