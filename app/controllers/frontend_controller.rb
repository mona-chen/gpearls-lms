class FrontendController < ApplicationController
  def index
    # Serve the built frontend index.html
    frontend_path = Rails.root.join("public", "assets", "lms", "frontend", "index.html")

    if File.exist?(frontend_path)
      render file: frontend_path, layout: false, content_type: "text/html"
    else
      render plain: "Frontend not built yet. Run 'cd client && bun run build' first.", status: 503
    end
  end
end
