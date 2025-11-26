class Api::UtilitiesController < Api::BaseController
  skip_before_action :authenticate_user!, only: [ :categories, :count, :pwa_manifest ]

  def categories
    doctype = params[:doctype]
    filters = params[:filters] || {}

    categories = []

    case doctype
    when "LMS Course"
      categories = Course.where(published: true).pluck(:category).compact.uniq
    when "LMS Batch"
      categories = Batch.where(published: true).pluck(:category).compact.uniq
    end

    render json: categories
  end

  def count
    doctype = params[:doctype]

    count = case doctype
    when "LMS Course"
      Course.where(published: true).count
    when "LMS Batch"
      Batch.where(published: true).count
    when "User"
      User.where(enabled: true).count
    when "LMS Enrollment"
      Enrollment.count
    else
      0
    end

    render json: count
  end

  def pwa_manifest
    manifest = {
      name: "Frappe LMS",
      short_name: "LMS",
      description: "Learning Management System",
      start_url: "/",
      display: "standalone",
      background_color: "#ffffff",
      theme_color: "#1a73e8",
      icons: [
        {
          src: "/frontend/public/manifest-icon-192.maskable.png",
          sizes: "192x192",
          type: "image/png",
          purpose: "any maskable"
        },
        {
          src: "/frontend/public/manifest-icon-512.maskable.png",
          sizes: "512x512",
          type: "image/png",
          purpose: "any maskable"
        }
      ]
    }

    render json: manifest
  end
end
