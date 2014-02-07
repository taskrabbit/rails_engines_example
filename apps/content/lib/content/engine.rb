module Content
  class Engine < ::Rails::Engine
    isolate_namespace Content
    
    initializer 'content.append_migrations' do |app|
      unless app.root.to_s == root.to_s
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"].push(path)
        end
      end
    end

    initializer 'content.asset_precompile_paths' do |app|
      app.config.assets.precompile += ["content/manifests/*"]
    end
  end
end
