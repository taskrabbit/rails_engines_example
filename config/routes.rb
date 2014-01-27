require 'boot_inquirer'

RailsEnginesExample::Application.routes.draw do

  BootInquirer.each_active_app do |app|
    mount app.engine => '/', as: app.gem_name
  end
end
