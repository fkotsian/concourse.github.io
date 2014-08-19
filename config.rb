###
# Compass
###

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
#  :which_fake_page => "Rendering a fake page with a local variable" }

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

activate :syntax

activate :navtree do |o|
  o.ignore_files = ["index.html.markdown"]
end

set :markdown_engine, :kramdown

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end

helpers do
  def navigation(value, key = nil, context = "")
    if key.nil?
      value.collect do |newkey, child|
        navigation(child, newkey, newkey)
      end.join
    elsif value.is_a?(String)
      this_resource = sitemap.find_resource_by_path(sitemap.extensionless_path(value))
      active = this_resource == current_page ? ' active' : ''
      title = discover_title(this_resource)
      link = link_to(title, this_resource)

      "<li class='child#{active}'>#{link}</li>"
    else
      parent_path = context+"/index.html"
      parent_resource = sitemap.find_resource_by_path(parent_path)

      active = parent_resource == current_page ? ' active' : ''
      title = discover_title(parent_resource)
      link = link_to(title, parent_resource)

      html = ""

      html << "<li class='parent'><span class='parent-label#{active}'>#{link}</span>"
      html << '<ol>'

      value.each do |newkey, child|
        html << navigation(child, newkey, context+"/"+newkey)
      end

      html << '</ol>'
      html << '</li>'

      html
    end
  end
end

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript

  # Enable cache buster
  # activate :asset_hash

  # Use relative URLs
  # activate :relative_assets

  # Or use a different image path
  # set :http_prefix, "/Content/images/"
end
