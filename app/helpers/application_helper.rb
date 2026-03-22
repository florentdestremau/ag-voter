module ApplicationHelper
  def version_info
    commit = ENV["APP_VERSION"] || "unknown"
    build_date = ENV["BUILD_DATE"] || "unknown"
    "v#{commit} • #{build_date}"
  end
end
