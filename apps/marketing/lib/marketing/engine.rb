module Marketing
  class Engine < ::Rails::Engine
    isolate_namespace Marketing

    initializer 'marketing.asset_precompile_paths' do |app|
      app.config.assets.precompile += ["marketing/manifests/*"]
    end
  end
end
