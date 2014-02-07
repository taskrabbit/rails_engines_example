module Content
  module PostHelper
    def display_content(content)
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true)
      markdown.render(content).html_safe
    end

    def display_time(datetime)
      diff = Time.now.to_i - datetime.to_i
      if diff.abs < 5
        "just now"
      else
        ago = time_ago_in_words(datetime)
        if diff > 0
          "#{ago} ago"
        else
          "#{ago} from now"
        end
      end
    end
  end
end
