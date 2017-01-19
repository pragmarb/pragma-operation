# Policies

Operations integrate with [Pragma::Policy](https://github.com/pragmarb/pragma-policy). All you have
to do is specify the policy class with `#policy`:

```ruby
module API
  module V1
    module Post
      module Operation
        class Create < Pragma::Operation::Base
          policy API::V1::Post::Policy

          def call
            post = Post.new(params)
            authorize! post

            post.save!

            respond_with status: :created, resource: post
          end
        end
      end
    end
  end
end
```

You can also pass a block to compute the policy class dynamically. If the block returns `nil`,
authorization will be skipped:

```ruby
module API
  module V1
    module Post
      module Operation
        class Create < Pragma::Operation::Base
          policy do |context|
            # ...
          end

          def call
            # ...
          end
        end
      end
    end
  end
end
```

Of course, you will now have to pass the user performing the operation in addition to the usual
parameters:

```ruby
result1 = API::V1::Post::Operation::Create.call(
  params: {
    title: 'My First Post',
    body: 'Hello everyone, this is my first post!'
  },
  current_user: authorized_user
)

result1.status # => :created
result1.resource
# => {
#      'title' => 'My First Post'
#      'body' => 'Hello everyone, this is my first post!'
#    }

result2 = API::V1::Post::Operation::Create.call(
  params: {
    title: 'My First Post',
    body: 'Hello everyone, this is my first post!'
  },
  current_user: unauthorized_user
)

result2.status # => :forbidden
result2.resource
# => {
#      'error_type' => 'forbidden',
#      'error_message' => 'You are not authorized to perform this operation.'
#    }
```

If you want to customize how you handle authorization, you can use the non-bang method `#authorize`:

```ruby
module API
  module V1
    module Post
      module Operation
        class Create < Pragma::Operation::Base
          policy API::V1::Post::Policy

          def call
            post = Post.new(params)

            unless authorize(post)
              respond_with!(
                status: :forbidden,
                resource: nil # if you don't need error info
              )
            end

            post.save!

            respond_with status: :created, resource: post
          end
        end
      end
    end
  end
end
```

## Authorizing collections

To authorize a collection, use `#authorize_collection`. This will call `.accessible_by` on the
policy class with the current user and the provided collection and return an authorized collection
containing only records accessible by the user.

```ruby
module API
  module V1
    module Post
      module Operation
        class Index < Pragma::Operation::Base
          policy API::V1::Post::Policy

          def call
            posts = authorize_collection Post.all
            respond_with status: :ok, resource: posts
          end
        end
      end
    end
  end
end
```
