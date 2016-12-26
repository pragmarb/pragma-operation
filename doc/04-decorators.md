# Decorators

Operations integrate with [Pragma::Decorator](https://github.com/pragmarb/pragma-decorator). All you
have to do is specify the policy class with `#decorator`. This will give you access to `#decorate`:

```ruby
module API
  module V1
    module Post
      module Operation
        class Show < Pragma::Operation::Base
          policy API::V1::Post::Policy

          def call
            post = Post.find(params[:id])
            respond_with status: :ok, resource: decorate(post)
          end
        end
      end
    end
  end
end
```

Note that `#decorate` works with both singular resources and collections, as it uses the decorator's
[`.represent`](http://trailblazer.to/gems/representable/3.0/api.html) method.
