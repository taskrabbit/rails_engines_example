module Admin
  class Engine < ::Rails::Engine
    isolate_namespace Admin
    
    initializer 'admin.append_migrations' do |app|
      unless app.root.to_s == root.to_s
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"].push(path)
        end
      end
    end

    initializer 'admin.asset_precompile_paths' do |app|
      app.config.assets.precompile += ["admin/manifests/*"]
    end
  end
end
