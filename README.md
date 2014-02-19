# Rails Engines Example

This shows how to use engines for namespacing within a "operator" Rails application.
For more info, see [the blog post](http://tech.taskrabbit.com/blog/2014/02/11/rails-4-engines/).

Actually, why not? Here it is:

<hr/>

At [TaskRabbit](https://www.taskrabbit.com), we have gone through a few iterations on how we make our app(s). In the beginning, there was the monolithic Rails app in the standard way with 100+ models and their many corresponding controllers and views. Then we moved to several apps with their own logic and often using the big one via API. Our newest [project](https://taskrabbit.co.uk) is a single "app" made up of several Rails engines. We have found that this strikes a great balance between the (initial) straightforwardness of the single Rails app and the modularity of the more service-oriented architecture.

We've talked about this approach with a few people and they often ask very specific questions about the tactics used to make this happen, so let's go through it here and via a [sample application](https://github.com/taskrabbit/rails_engines_example).

## Rails Engines

[Rails Engines](http://edgeguides.rubyonrails.org/engines.html) is basically a whole Rails app that lives in the container of another one. Put another way, as the docs note: an app itself is basically just an engine at the root level. Over the years, we've seen sen engines as parts of gems such as [devise](https://github.com/plataformatec/devise/blob/7a9ae13baadc3643d0f5b74077d9760d19c56adb/lib/devise/rails.rb) or [rails_admin](https://github.com/sferik/rails_admin/blob/master/lib/rails_admin/engine.rb). These example show the power of engines by providing a large set of relatively self-contained functionality "mounted" into an app.

At some point, there was a talk that suggested the approach of putting my our functionality into engines and that the Rails team seemed to be devoting more and more time to make them a first class citizen. Our friends at Pivotal Labs were talking about it a lot, too. Sometimes [good](http://pivotallabs.com/migrating-from-a-single-rails-app-to-a-suite-of-rails-engines/) and sometimes [not so good](http://pivotallabs.com/experience-report-engine-usage-that-didn-t-work/).

## Versus Many Apps

We'd seen an app balloon and get out of control before, leading us to try and find better ways of modularization. It was fun and somewhat liberating to say "Make a new app!" when there was a new problem domain to tackle. We also used it as a way to handle our growing organization. We could ask Team A to work on App A and know that they could run faster by understanding the scope was limited to that. As a side-note and in retrospect, we probably let organizational factors affect architecture way more than appropriate.

Lots of things were great about this scenario. The teams had freedom to explore new approaches and we learned a lot. App B could upgrade Rack (or whatever) because it depend on the crazy thing that App A depended on. App C had the terrible native code-dependent gem and we only had to put that on the App C servers. Memory usage was kept lower, allowing us to run more background workers and unicorn threads.

But things got rough in coordinating across these apps. It wasn't just the data access. We made APIs and allowed any app to have read-only access to the platform app's database. This allowed things go much faster by preventing creation of many GET endpoints and possible points of failure. The main issue in coordinating releases that spanned apps. They just went slower than if it was one codebase. There was also interminable bumping of gem versions to get shared code to all the apps. Integration testing the whole experience was also very rough.

So it's a simple one, but the main advantage that we've seen in the engine model is that it is one codebase and git repo. A single pull request has everything related to that feature. It rolls out atomically. Gems can be bumped once and our internal gems aren't bumped at all as they live unbuilt in a `gems` folder in the app itself. We still get most of the modularization that multiple apps had. For example, the User model in the payments engine has all the stuff about balances and the one in the profile engine doesn't know anything about all that and it's various helper methods.

The issue with gem upgrades and odd server configurations does continue to exist in the engine model and is mostly fine in the many app model. The gem one is tough and we just try to stay on top of upgrading to the newest things and overall reducing dependencies. The specs will also run slower in the engine app, but you'll have better integration testing. I'll go over a little bit about we've tackled server configurations and memory further down.

## Versus Single App

It's very tempting when green-fielding a project to just revert back to the good-old-days of the original app. Man, that was so nice back before the (too) fat models and tangled views and combinatorics of 4 years of iterating screwed things up. And we've learned a lot since then too, right? Especially about saying no to all those [combinatorics](http://firstround.com/article/The-one-cost-engineers-and-product-managers-dont-consider) and also using [decorators](http://robots.thoughtbot.com/tidy-views-and-beyond-with-decorators) and [service objects](http://adequate.io/culling-the-activerecord-lifecycle) and using [APIs](http://www.api-first.com/). Maybe.

What we do know is that you can feel that way again even a year into an app. Inside any given engine, you have the scope of a much smaller project. Some engines may grow larger and you'll start to use those tools to keep things under control. Some will (correctly) have limited scope and feel like a simple app in which you understand everything that is happening. For example, decorators are great tool and they came in handy in our big app and larger engines. However, we've found in an a targeted engine that only serves its one purpose, it feels like there is room in that model to have some things that would have been decorated in a larger app. This is because it doesn't have all that other junk in it. Only this engine's junk :-)

## Engine Usage

We've seen a few different ways to use engines in a Rails project. A few examples are below. The basic variables are what is in the "operator" (root) app and what kind of app we're making (API driven or not).

### Admin

The first engine we've recommend making to people is the admin engine. In the first app, we made the mistake of putting admin functionality in the "normal" pages. It was very enticing. We had that form already for the user to edit it. Just by changing the permissions, we could allow the admin to edit it, too. Forms are cheap and admins want extra fields. And more info. And basically a different UI.

So we can made an engine basically just like rails_admin did and gave it's own layout and views and JS and models and controllers, etc. Overall, we started treating our hardworking admins like we should: a customer with their own needs and dedicated experience.

The structure looked something like this...

```
app
  assets
  controllers
  models
    user.rb
    post.rb
  views
    layouts
admin
  app
    assets
    controllers
    models
      admin
        user.rb
        post.rb
    views
      layouts
config
db
  migrate
gems
spec
```

When we had this all mixed into one interface and set of models, at least a third of the code in a model like `Post` or `User` would be admin-specific actions. With this approach, we can give the admins a better, targeted experience and keep that code in admin-land.

Throughout these engine discussions, the question of sharing code and/or inheriting from objects will keep coming up. Specifically, for the admin scenario, we say do whatever works for you and on a case by case basis. In the above approach, we would probably tend to have `Admin::Post < ::Post` and other such inheritance. In Rails 2, we probably wouldn't have done what as they would have different `attr_accessible` situations but that's happening in the controller these days, so now inheriting from them will just get the benefit of the data validations, which is something we definitely want to share.

Note that inheriting is probably a bad choice if you have callbacks in the root model that you don't want triggered when the admin saves the record. In that case, it would be better to `Admin::Post < ActiveRecord::Base` and either duplicate the logic, have it only in SQL table (unique indexes for example), or have a mixin that is included in both.

### Shared Code

The note about controllers being in charge of the parameters involved leads to the next possibility. You can have your models (at least the ones you need to have shared) in the operator and all the other stuff in the engines. At this point, maybe you could add the `engines` namespace to be more clear.

```
app
  models
    user.rb
    post.rb
config
db
  migrate
engines
  customer
    app
      assets
      controllers
      models
        customer
          something_admin_doesnt_use.rb
      views
        layouts
  admin
    app
      assets
      controllers
      models
        admin
          admin_notes.rb
      views
        layouts
gems
spec
```

Now you can use `Post` from both and everything is just fine. This would work out well if it's mostly the data definition you are using and like to use things like decorators and/or service objects and/or fat controllers in your engines.

You could also put layouts or mixins in the operator. This might be a good idea if you were sharing the layout between two engines. At that point, maybe we'll just go all in on the engines by making a `shared` engine. Having a namespace for clarity is much simpler.

```
apps
  shared
    app
      assets
      controllers
        shared
          authentication.rb
      models
        shared
          post.rb
          user.rb
      views
        shared
          layouts
  marketing
    app
      controllers
        marketing
          application_controller.rb
          home_controller.rb
  content
    controllers
    models
      content
        something_admin_doesnt_use.rb
  admin
    app
      assets
      controllers
      models
        admin
          admin_notes.rb
      views
        layouts
config
db
  migrate
gems
spec
```

In this structure, admin can still get it's own layout if it wants, but marketing and content can easily share the same layout in addition to the models.

The [example in Github](https://github.com/taskrabbit/rails_engines_example) takes this just one step farther by not sharing models at all. Sharing the actual model can still lead to the [god model](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/) situation of a mono-Rails app without the use of other mitigating objects. To keep things as tight as possible, we've allowed each engine to have their own [User](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/content/app/models/content/user.rb) object, for example. If there is model code to share, it would still go in the shared engine, but as a mixin like [this one](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/shared/app/models/shared/user/display.rb). Note that in a well-designed schema, only one of these actually writes to the database and the others include a `ReadOnly` module from the shared engine.

The repo's structure looks as follows:

```
apps
  shared
    app
      assets
      controllers
        shared
          controller
            authentication.rb
      models
        shared
          model
            read_only.rb
          user
            user_display.rb
      views
        shared
          layouts
  marketing
    app
      controllers
        marketing
          application_controller.rb
          home_controller.rb
        models
          marketing
            user.rb
    db
      migrate
  account
    app
      controllers
      models
        content
          user.rb
          post.rb
    db
      migrate
  content
    app
      assets
      controllers
      models
        admin
          post.rb
          user.rb
    db
      migrate
  admin
    app
      assets
      controllers
      models
        admin
          admin_notes.rb
          post.rb
          user.rb
      views
        layouts
    db
      migrate
config
gems
spec
```

### API Server

Our latest project at TaskRabbit basically looks the the above and the [example](https://github.com/taskrabbit/rails_engines_example) with one difference: we don't share layouts between our engines. We've made the choice to have all the frontend code in one engine and all of the other engines just serve API endpoints. There are several shared mixins for these backend engines, but they don't need a layout because they are just using [jbuilder](https://github.com/rails/jbuilder) to send back JSON to the frontend client. The frontend engine, therefore, doesn't really use any models and has all the assets and such. Admin still has its own layout and uses a more traditional Rails MVC approach.

It looks like this:

```
apps
  shared
    app
      assets
      controllers
        shared
          controller
            authentication.rb
      models
        shared
          model
            read_only.rb
          user
            user_display.rb
  frontend
    app
      assets
      controllers
        marketing
          application_controller.rb
          home_controller.rb
        models
          marketing
            user.rb
      views
        frontend
          layouts
  account
    app
      controllers
      models
        content
          user.rb
          post.rb
      views
        account
          users
            show.json.jbuilder
    db
      migrate
  content
    app
      controllers
      models
        admin
          post.rb
          user.rb
      views
    db
      migrate
  admin
    app
      assets
      controllers
      models
        admin
          admin_notes.rb
          post.rb
          user.rb
      views
        layouts
    db
      migrate
config
gems
spec
```

The API setup alleviates one of the odder things about the example approach. Ideally, there is no interaction between engines. Particularly in the models and views, this is critical. However, some knowledge leaks out in the example though from the controllers. For example, the [login controller](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/account/app/controllers/account/application_controller.rb#L11) redirects to `/posts` after login. This is in the content engine. It's probably not the end of the world but that is coupling. We get around this using our one frontend engine and the several API ones, but this does some serious commitment.

## Strategies

We've gotten lots of questions and read about issues people are having with engines so let's go through them here.

### Migrations and Models

Rails bills itself as "convention over configuration" so it's not too surprising to be confronted with lots of questions about "where to put stuff" when deviating (slightly) from the conventions. The one people seem the most worried about are migrations. We've never had an issue, but there must be scenarios that get a little tricky. If you are sharing the models, wewould just put them in the normal `db/migrate` location. If your models live inside the engines, it's probably not a huge deal to still do that, but we've decided to have the migrations live with their models.

As notes, each model/table (say `users`) ideally has one master model. In the sample app, the `User` model's master is in the [account](https://github.com/taskrabbit/rails_engines_example/tree/434e687b795ec52705a3be1dd2c635f0054336d4/apps/account) engine. This engine is in charge of signing up and logging in users. Fleshed out, it would also be responsible for reseting a lost password and editing account information. It's the only `User` model that [mentions](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/account/app/models/account/user.rb#L7) `has_secure_password` and knows anything about that kind of thing. The rest of the engines may [need](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/content/app/models/content/user.rb#L5) a `User` model but they have the `ReadOnly` [module](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/shared/app/models/shared/model/read_only.rb) to prevent actually writing to the table.

Therefore, the account engine has the [migrations](https://github.com/taskrabbit/rails_engines_example/tree/434e687b795ec52705a3be1dd2c635f0054336d4/apps/account/db/migrate) having to do with the users table. In order to register that migrations are within these engines, we [add](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/account/lib/account/engine.rb) a snippet like the following to each engine.

```ruby
initializer 'account.append_migrations' do |app|
  unless app.root.to_s == root.to_s
    config.paths["db/migrate"].expanded.each do |path|
      app.config.paths["db/migrate"].push(path)
    end
  end
end
```

This (via [here](http://pivotallabs.com/leave-your-migrations-in-your-rails-engines/)) puts the engine's migrations in the path. Migrations continue to work as they normally do with the timestamps and such. So our `db/migrate` folder doesn't have any files in it (and is not checked into git). I have one locally, just because when I make a migration, Rails creates it automatically. However, I end up doing something like this immediately.

```bash
$ bundle exec rails g migration CreatePosts
      invoke  active_record
      create    db/migrate/20140207011608_create_posts.rb
$ mv db/migrate/20140207011608_create_posts.rb apps/content/db/migrate
```

You might wonder, and it does come up, what to do when you are adding a column to the users table for some other feature in some other engine. For example, we added a boolean `admin` column to the example users table to know if the given user is allowed to do stuff in the admin engine. We see the notion of permissions as being within the account engine's scope, even if it's not being actively leveraged there. Tt's still part of the account. Therefore, we [added](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/account/db/migrate/20140207164357_add_admin_to_users.rb) the migration to the account engine.

In part, if I couldn't justify to myself why it would be part of the account engine, it would be a red flag. Specifically, should this even be in the users table at all. If the answer is "yes" for whatever reason, then I'd likely still put the migration in the account engine, but usually it helps me realize that it shouldn't be in the users table at all. A good example that came up in our app was the notion of profile. It seemed like it was 1-to-1 with users and what ever columns supported it should go in the users table. For a variety of reasons, including that we wanted a different engine for that, we ended up making it's own table with a a `has_one` relationship in that engine. This paid off even further as we realized that a `User` should actually have two profiles, one for their activity as a TaskPoster and one as a TaskRabbit, as they record and display very different information. Each has their own table and engine now.

Let's say we wanted to cache the number of posts the user had made. That's a pretty clearcut case to use `counter_cache` and put a `posts_count` in the users table. We'll want to look closely at this situation. First of all, the `counter_cache` code would clearly go on the `User` model in the content engine. That would also require that model to not be read-only or at least not in spirit (depending on the specifics used to implement the feature). It's not a good feeling when you do all this architecture stuff and it gets in the way of something that is so easy and we have to look out for those cases. If this is one of those cases, just do it; literally, however you want. We would probably keep the migration in the account engine.

It might not be one of those cases, though. I have almost never been sorry when I've made another model in these cases. So we could make a `PostStatistic` model or something in the content engine which `belongs_to :user` for recording this (and likely other things that come up). The counter cache feature is not magic - we just increment that table as necessary. It also doesn't feel that superfluous as it exists only inside that engine (which. in turn, doesn't have all the random stuff internal to other engines). We have some tables that started out that way. Mostly because we actively try not to do JOINs on our API calls, these tables ending up being the hub of the most relevant data of what has happening in our marketplace. Another option that we've used in similar situations is not to make the column at all. The content engine, or whoever is using this kind of data, would use the timestamp of the last `Post` or some other data to use as the cache key to look up all kinds of stuff in a store like memcache or Redis. If it's not there, it will take bit the bullet and calculate it and store it in the cache.

Again, architecture does not exist for fun or to get in the way. If something is super-simple and obvious and easy to maintain while doing the "right" way for the design is difficult and fragile, we just do it the easy way. That's the way to ship things for customers. However, we've found that in most case the rules of the system kick off useful discussions and behaviors that tend to work out quite well.

### Admin

One of the cases where it's important to really examine the value and return on investment in engine separation is with the admin engine. We believe it's a special case.

In our system, the admin engine has it's own migrations. For example, we have a model called `AdminNote` where an admin can jot down little notes about most objects in the system. It clearly owns that. But the reason this whole experience exists in the first place is that it also is able to write more or less whatever it wants to _all_ the objects in the system. This clearly violates our single-model-master rule. So we don't fight an uphill battle here by making a special case and saying that the admin engine can literally do whatever it wants. All the other engines live in complete isolation from each other for a variety of reasons. Admin can depend directly on any or all of them. It's at the top of the food chain because it needs to regulate the whole system.

So it's [fine](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/admin/app/models/admin/post.rb) if `Admin::Post < Content::Post` or just uses `Content::Post` directly in it's controllers. It's just not worth it to share all of the data definitions and validations with when it will almost always be with engine X and admin. Note that it's important to have the same validations because admin might be in charge, but it still needs to produce valid data as that other engine will be using it.

In our much larger app, we inherit from and/or use most of the models in the system as well as service objects from other engines. We do not use outside controllers or views. Our admin engine does use it's own layout and much simpler request cycle than our much fancier frontend app. We tried to show the admin engine using a different layout in the example app, but they're both bootstrap so it might be hard to tell. The header is red in admin :-)

### Assets

Everyone seems to have struggled with this one and I can't even imagine pulling apart assets if they weren't coded in a modular way at the start. However, starting with them separate in Rails 4 has been fairly straightforward. We add the following [code](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/account/lib/account/engine.rb) to our engine much like the migration code.

```ruby
initializer 'account.asset_precompile_paths' do |app|
  app.config.assets.precompile += ["account/manifests/*"]
end
```
You could list all the manifests one by one, but we've found that it's simpler to just always put them in a folder created for the purpose. This works for both css and js. You would would reference those files something like this:

```ruby
= stylesheet_link_tag 'account/manifests/application'
= javascript_include_tag 'account/manifests/application'
```

### Routes

In an Engine, routes go within the engine directory at the [same](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/account/config/routes.rb) `config/routes.rb` path. It's important to note here that in order for these routes to be put into use in the overall app, the engine needs to be mounted. In a normal engine use case, you would mount rails_admin (say to /admin) to give a namespace in the url, but we think it's important that all of these engines get mounted at the root level. You can see our root routes.rb file [here](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/config/routes.rb).

```ruby
RailsEnginesExample::Application.routes.draw do
  BootInquirer.each_active_app do |app|
    mount app.engine => '/', as: app.gem_name
  end
end
```

So as expected, the operator app has no routes of it's own and it's all handled by the engines. I'll add little more about the `BootInquirer` in a bit. It is just a helper class that knows all the engines. This means that the code is functionally something more like this:

```ruby
RailsEnginesExample::Application.routes.draw do
  mount Admin::Engine     => '/', as: 'admin'
  mount Account::Engine   => '/', as: 'account'
  mount Content::Engine   => '/', as: 'content'
  mount Marketing::Engine => '/', as: 'marketing'
end
```

It would really clean to have something other than root in these mountings, but it doesn't seem practical or that important. We want to be able to have full control over our url structure. For example, mounting the account engine at anything but root would prevent it from handling both the `/login` and `/signup` paths. The tradeoff is that two engines could claim the same URLs and conflict with much confusion. That's something we can manage with minimal effort. We've found that most engine route files start with `scope` to put most things under one directory or a few `resources` which does basically the same thing.

Another important note is to [use](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/account/lib/account/engine.rb#L3) `isolate_namespace` in your Engine declaration. That prevents various things like helper methods from leaking into other engines. This makes sense for our case because the whole point is to stay contained. Another side effect is route helpers like 'posts_path' to work as expected without needing to prefix them like `content.posts_path` in your views. I believe it might also make the parameters more regular (for example having `params[:post]` instead of `params[:content_post]`). Oh, just put it in [there](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/apps/admin/lib/admin/engine.rb).

### Tests

Many of the issues noted [here](http://pivotallabs.com/experience-report-engine-usage-that-didn-t-work/) revolve around testing. One of the promises of engines is the existence of the subcomponents that you could (theoretically) use in some other app. This is not the goal here. We are using engines maximize local simplicity in our application, not create a reusable library. To that end, we don't think the normal Engine testing mechanism of creating a dummy app within the engine is helpful.

On our first engine application, we put a `spec` folder within each engine and then wrote a `rspec_all.sh` script to run each of them. It was not the right way. To do that really correctly, you'd test at that level and you'd have to test again at the integration level. This is another case of it not being worth it. Now we just put all our specs in the spec [directory](https://github.com/taskrabbit/rails_engines_example/tree/434e687b795ec52705a3be1dd2c635f0054336d4/spec) and run `rspec spec` to run them all.

Each engine has it's own directory in there to keep it somewhat separate and to be able to easily test all of a single engine and it ends up looking like a normal app's root spec folder with models, requests, controllers, etc. Much like the admin engine, there are no rules about what you can and can't use in the tests. The goal is make sure the code is right, not to follow some architectural edict. For example, in a test that checks whether a Task can be paid for, it's fine to use the models from the payment engine to make sure everything worked together well.

One thing that is interesting is [fixtures](http://api.rubyonrails.org/v3.2.13/classes/ActiveRecord/Fixtures.html). We like using fixtures because it's a pretty good balance between speed and fully executing most of the code in out tests. We use [fixture_builder](https://github.com/rdy/fixture_builder) to save the hassle of maintaining those yml files precisely. Anyway, the issue in the case where we have multiple engine's each with their own model class is that fixtures (and [factories](https://github.com/thoughtbot/factory_girl) for that matter) only get one class. So if you do something like this while testing in the content engine, you'd be in trouble:

```ruby
describe Content::Post do
  fixtures :users

  it "should be associated with a user" do
    user = users(:willy)
    post = Content::Post.new(content: "words")
    post.user = user
    post.save.should == true
    user.posts.count.should == 1
  end
end
```

This is a problem because of classes expecting to be a certain type. You'd get this error:

```bash
Failures:

  1) Content::Post should be associated with a user
     Failure/Error: post.user = user
     ActiveRecord::AssociationTypeMismatch:
       Content::User(#70346317272500) expected, got Account::User(#70346295701620)
```

So the user has to be and instance of the `Content::User` and not an `Account::User` class. We use a [helper](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/spec/support/fixture_class_name_helper.rb) to say what the classes are as well as switch between them. So this test will use the correct classes:

```ruby
describe Content::Post do
  fixtures :users

  it "should be associated with a user" do
    user = fixture(:users, :willy, Content)
    post = Content::Post.new(content: "words")
    post.user = user
    post.save.should == true
    user.posts.count.should == 1
  end
end
```

The same sort of thing could be done with FactoryGirl too. Often, we end up just using the ids more than we would in a normal test suite. The important thing to note is to just do whatever you feel gives you the best coverage with the most return on investment for your time.

### Memory

You may have noticed the [BootInquirer](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/lib/boot_inquirer.rb) class mentioned earlier. This is a class that know about all the engines in the system.

```ruby
  APPS = {
      'a' => 'account',
      'c' => 'content',
      'm' => 'marketing',
      'z' => 'admin'
    }
```

It is called from three places.

```ruby
# Gemfile
gemspec path: "apps/shared"
BootInquirer.each_active_app do |app|
  gemspec path: "apps/#{app.gem_name}"
end

# application.rb
require_relative "../lib/boot_inquirer"
BootInquirer.each_active_app do |app|
  require app.gem_name
end

# routes.rb
BootInquirer.each_active_app do |app|
  mount app.engine => '/', as: app.gem_name
end
```

The main point here is to simplify even further how to add a new engine to the app. The secondary point is somewhat interesting, though. One of the potential downsides of an engine-based app over multiple apps is the larger memory footprint or larger scale production rollout of some obscure and complicated native library for just one of the engines. This would not be a problem if you could "boot" the app with the just _some_ of the engines enabled. The `BootInquirer` makes that possible. It inspects and environment variable to know which engines to add to the gemspec and require and route towards.

```
$ ENGINE_BOOT=am bundle exec rails c
    => will boot the account and marketing engines - but not content, admin, etc.
$ ENGINE_BOOT=-m bundle exec rails c
    => will boot all engines except marketing
```

We haven't actually seen memory be that different that in our large Rails app. In fact, it is less because of a combination of Ruby upgrades and less conspicuous gem consumption. However, memory-wise this setup allows us to use our one codebase like multiple apps. In that case, we use a load balancer to map url paths to the correct app.

This is also useful in processing background workers. You would likely get an extra Resque worker or two. It's important to have a good queue strategy (different queues per engine) and to really not have the engines depend on each other to make this work, of course.

In order for this to work, we need to be more mindful of our gem usage. The first step is changing [application.rb](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/config/application.rb#L7) to say `Bundler.setup(:default, Rails.env)` instead of `Bundler.require(:default, Rails.env)` as usual. This mean we will have to explicitly require the gems we are using instead of it happening automatically. Most of those dependencies are in the engines' gemspecs and they'd have to be required anyway. However, by changing this line, we'll have to require what is needed from the main Gemfile as well. Ideally, there wouldn't be anything in [there](https://github.com/taskrabbit/rails_engines_example/blob/434e687b795ec52705a3be1dd2c635f0054336d4/Gemfile) at all, but we have some Rails and test stuff that all the engines use.

You may notice that the exception we made for the admin engine rears its head here. If admin depends on the other engines, you won't be able to use admin experience unless you launch the app with all those engines. This is definitely true. The servers that the admin urls route to will have to have all of the engines running. We found it was useful to quarantine admin usage anyway as there are a few requests and inputs that could blow out the heap size fairly easily.

### Folders and Files

If you're interested in this setup, you're just going to have to get used to it. There are a lot of directories. There are lot of files named the same thing. I've found that Sublime Text is better for this than Textmate. I'm a huge fan of ⌘T to open files and Sublime allows the use of the directory names in that typeahead list. If your editor doesn't do this, then you'll spend more time than you want to look through the six different `user.rb` or `application_contoller.rb` files in the project.

### Interaction Between Engines

So we've gone through a lot of trouble to keep that shiny new Rails app feel. Each engine has a particular goal in life and everything is nice and simple. Particularly in the API case, it writes and reads its data and generally just takes of business. But the world isn't always perfect and sometimes the engines need to talk to each other. If it's happening too much, we probably didn't modularize along the right lines and we should consider throwing them together. We don't have all the answers, but engine naming and scoping seems to be a fine art. It's very tempting to go very narrow for cleanliness and it's also very tempting to just throw stuff in to an existing one so I'm not surprised when we find that the lines are a not drawn quite right.

There are other cases, though, that are not systemic errors in engine-picking and future-prediction. It's the kind of case I talked about with the `posts_count` above. Let's say we had a good reason to make that happen. Actually let's change it just a little bit to be more realistic. Let's say we had a profile engine where user could manage his online presence. Let's also say that other users could see and rate his posts. It's a completely reasonable thing to have an average post rating shown on his profile. Does this data about posts mean that the profile pages or API should be part of the content engine? We don't think so. This is likely just one tiny detail in an engine otherwise setup to upload photos, quote favorite movies, or whatever. We just need a little average rating on the there somewhere with a link to the posts.

In this case, we use our [Resque Bus](https://github.com/taskrabbit/resque-bus) gem extensively. This is a minor add-on to [Resque](https://github.com/resque/resque/blob/1-x-stable/README.markdown) that changes the paradigm just enough to allow us to decouple these engines. In a normal Rails apps using Resque, we would queue up a background worker to process the rating. This worker would calculate the new average rating and store it in the profile. Resque Bus uses publishing and subscription to accomplish similar goals. If you buy into this model, you have all of your engines and in this case the content engine, publishing to the bus when interesting things happen. Creation of a post or rating would be a good example. Other engines (or completely separate apps) then subscribe to events they find interesting. There can be more than one subscriber. Even when there is nothing particularly interesting to do, we've found that always having a subscriber to record the event produces a really useful log. In the rating case, though, the profile engine would also subscribe to the event and record the new rating. By one engine simply noting that something happened and the other reacting to the occurrence, we maintain the conceptual as well as physical (these engines could be on different servers) decoupling.

What exactly gets published and how that is used is up to the developers involved. There seems to be a few options in this specific case.

A) The content engine is publishing data changes. `ResqueBus.publish('post_rated', {post_id: 42, author_id: 2, rated_by: 4, rating: 4})`
B) The content engine adds some calculations. `ResqueBus.publish('post_rated', {post_id: 42, author_id: 2, rated_by: 4, rating: 4, new_average: 4.25, total_ratings: 20})`

Choosing option B is interesting for a few reasons:

* It is predicting the information other engines will want to know.
* It decreases the coupling because now the profile engine now just records the info instead of having to calculate it.
* It creates a record of the averages in our event store. Maybe we'll draw a graph of it sometime.
* It adds to the time required to complete the request to create the rating.

This would mean the post engine would have something like this in an initializer:

```ruby
ResqueBus.dispatch('profile') do
  subscribe 'post_rated' do |attributes|
    profile = Profile::Document.find_by(user_id: attributes['author_id'])
    profile.post_ratings_total  = attributes['total_ratings']
    profile.post_rating_average = attributes['new_average']
    profile.save!
  end
end
```

Or in the way that we prefer using a subscriber class that we would put in `profile/app/subscribers`:

```ruby
class Profile::ContentSubscriber
  include ResqueBus::Subscriber

  subscribe :post_created

  def post_created(attributes)
    profile = Profile::Document.find_by(user_id: attributes['post_author_id'])
    profile.post_ratings_total  = attributes['total_ratings']
    profile.post_rating_average = attributes['new_average']
    profile.save!
  end
end
```

It's clearly a fine option and the added time probably isn't too much assuming we have the right indexes on our database, but we actually tend to use option A. We don't particularly like trying to predict which events are interesting and how other engines will use them so we just publish on all creations or updates. We are fine with the profile engine having read-only `Rate` model and code to calculate the average. It could keep a running tally of the total number and just add this one to it, but we tend to recalculate it every time because it's not that hard and is less fragile.

It would look something like this:

```ruby
class Profile::ContentSubscriber
  include ResqueBus::Subscriber

  subscribe :post_rated

  def post_rated(attributes)
    total = Profile::Rate.where(author_id: attributes['author_id']).count
    sum   = Profile::Rate.where(author_id: attributes['author_id']).sum(:rating)

    profile = Profile::Document.find_by(user_id: attributes['post_author_id'])
    profile.post_ratings_total  = total
    profile.post_rating_average = sum.to_f / (5*total.to_f)
    profile.save!
  end
end
```

However you do it, the point is that this engine is working on it's own for it's own purposes. Layering it on, it's quite straightforward to see how we could build spam detection as its own engine or into the admin one. We could subscribe to ratings or post creation and react accordingly, maybe pulling the post or giving the user a score that limits his visibility, etc. Or we could add a metrics engine, to report the conversion of a user on his first post to a variety of external services. Then, when a new developer starts and asks where the metrics code is, we don't have to say what we said before which was, "everywhere." We could show very simple mappings between things that are happening throughout the system and the numbers like revenue or engagement that are getting reported to something like Google Analytics.

## Summary

Try out engines. We like them.