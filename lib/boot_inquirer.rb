# This determines which engines to boot / mount within the operator app (v3).
# The boot flag is a collection of characters representing the different engines in this project
# For example:
#   ~> ENGINE_BOOT=am bundle exec rails c
#   => will boot the account and marketing engines - but not content, admin, etc.
#
# The boot flag can be negated to have the opposite effect.
# For example:
#   ~> ENGINE_BOOT=-f bundle exec rails c
#   => will boot all engines except frontend
#
# The boot flag characters are not necessarily the first letter of each engine name, so check this file if you're using boot flags.
#
# When Rails.env is "test" all boot flags are assumed to be present, no matter what you provide.

class BootInquirer
  APPS = {
    'a' => 'account',
    'c' => 'content',
    'm' => 'marketing',
    'z' => 'admin'
  }

  class << self

    def apps
      APPS.map{ |k,v| BootInquirer::App.new(k, v) }
    end

    def each_active_app
      apps.each do |app|
        yield app if app.enabled?
      end
    end

    def any?(*keys)
      keys.any?{|k| send("#{k}?") }
    end

    def all?(*keys)
      keys.all?{|k| send("#{k}?") }
    end

    def using_boot_flags?
      boot_flag.present?
    end

    def method_missing(method_name, *args)
      if method_name.to_s =~ /(.+)\?$/
        app = apps.detect{|app| app.gem_name == $1}
        if app
          app.enabled?
        else
          super
        end
      else
        super
      end
    end

    def boot_flag
      @boot_flag ||= ENV['ENGINE_BOOT']
    end

    def negate?
      boot_flag.to_s =~ /^[\-\^]/
    end

    def boot_flag?(flag)
      return true if boot_flag.nil?

      default_value = !!boot_flag.to_s.index(flag)
      negate? ? !default_value : default_value
    end

  end

  class App
    attr_reader :key, :gem_name
    def initialize(key, val)
      @key = key
      @gem_name = val
    end

    def enabled?
      BootInquirer.boot_flag?(@key)
    end

    def engine
      module_name = gem_name.classify
      module_name << 's' if gem_name[-1] == 's'
      module_name.constantize.const_get(:Engine)
    end
  end
end
