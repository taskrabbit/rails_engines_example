module Admin
  module ApplicationHelper
    def display_time(time, format=:day_zone)
      return "" if time.nil?
      I18n.l(time, :format => "%Y-%m-%d %H:%M %Z")
    end

    def display_markdown(content)
      return "" if content.blank?
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true)
      markdown.render(content).html_safe
    end

    def display_property(name, value, opts = {})
      opts = opts.reverse_merge({
        :html_escape => true,
      })

      return "" if (value.is_a?(Fixnum) && value == 0 && !opts[:allow_zero]) || (value.blank? && value != false && !opts[:allow_blank])

      if value.is_a?(ActiveRecord::Base)
        case value.class.table_name.to_s
        when "users"
          opts[:formatter] ||= :link_to_name
        end
      end

      value = value.strftime("%Y-%m-%d %H:%M") if value.respond_to?(:strftime)
      if opts[:html_escape]
        value = h(value) if value.is_a?(String)
        name = h(name)
      end

      value = self.send(opts[:formatter], value) if opts[:formatter]
      value = simple_format(value.html_safe) if opts[:paragraphs]

      "<dt>#{name}</dt><dd class='value-#{name.to_s.downcase.gsub(/\W/,"-")}'>#{value}</dd>".html_safe
    end

    def display_properties(obj, *keys)
      return nil if obj.nil?
      options = keys.extract_options!

      out = []
      keys.each do |key|
        name = key.to_s.titleize
        method = key
        value = obj.send(method)
        if value.is_a?(Hash)
          value.each do |hk, hv|
            out << display_property(hk, hv, options)
          end
        else
          out << display_property(name, value, options)
        end
      end
      out.join("\n").html_safe
    end

    def display_name(user, limit = nil)
      return "" unless user
      user.extend(::Shared::User::Display) unless user.respond_to?(:full_name)
      name = user.full_name
      name = truncate(name, length: limit) if limit
      name
    end

    def link_to_name(user, limit = nil)
      return "" unless user
      link_to display_name(user, limit), user_path(user.id)
    end

    def render_rescue(name, *args)
      name = "index_#{name}" if panel_collection?
      render name.to_s, *args
    rescue ActionView::MissingTemplate
      ""
    end

    def skip_sidebar?
      @skip_panels || @skip_sidebar
    end

    def skip_header?
      @skip_panels
    end

    def skip_top_bottom?
      @skip_panels
    end

    def panel_collection?
      @panel_collection
    end

    def skip_panels
      @skip_panels = true
    end

    def panel_collection(options = {})
      @panel_collection = true
      skip_sidebar unless options[:sidebar]
    end

    def alert_bootstrap(rails)
      case rails.to_s
      when "notice"
        "success"
      when "error", "alert"
        "danger"
      else
        # other: "warning"
        "info"
      end
    end
  end
end
