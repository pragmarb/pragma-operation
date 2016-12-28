# Basic usage

Here's the simplest operation you can write:

```ruby
module API
  module V1
    module Ping
      module Operation
        class Create < Pragma::Operation::Base
          def call
            # The `status` parameter is optional (the default is `:ok`).
            respond_with(
              status: :ok,
              resource: { pong: params[:pong] }
            )
          end
        end
      end
    end
  end
end
```

Here's how you use it:

```ruby
result = API::V1::Ping::Operation::Create.call(params: { pong: 'HELLO' })

result.status # => :ok
result.resource # => { pong: 'HELLO' }
```

As you can see, an operation takes parameters as input and responds with:

- an HTTP status code;
- (optional) a resource (i.e. an object implementing `#to_json`).

If you don't want to return a resource, you can use the `#head` shortcut:

```ruby
module API
  module V1
    module Ping
      module Operation
        class Create < Pragma::Operation::Base
          def call
            head :no_content
          end
        end
      end
    end
  end
end
```

Since Pragma::Operation is built on top of [Interactor](https://github.com/collectiveidea/interactor),
you should consult its documentation for the basic usage of operations; the rest of this section
only covers the features provided specifically by Pragma::Operation.

## Headers

You can attach headers to your response by manipulating the `headers` hash:

```ruby
module API
  module V1
    module Post
      module Operation
        class Create < Pragma::Operation::Base
          def call
            post = ::Post.new(params)
            post.save!

            headers['X-Post-Id'] = post.id

            respond_with status: :created, resource: post
          end
        end
      end
    end
  end
end
```

You can also set headers when calling `#respond_with`:

```ruby
module API
  module V1
    module Post
      module Operation
        class Create < Pragma::Operation::Base
          def call
            post = ::Post.new(params)
            post.save!

            respond_with status: :created, resource: post, headers: {
              'X-Post-Id' => post.id
            }
          end
        end
      end
    end
  end
end
```

## HATEOAS

Pragma::Operation supports HATEOAS by allowing you to specify a list of links to use for building
the `Link` header. You can set the links by manipulating the `links` hash.

For instance, here's how you could link to a post's comments and author:

```ruby
module API
  module V1
    module Post
      module Operation
        class Show < Pragma::Operation::Base
          def call
            post = ::Post.find(params[:id])

            links['comments'] = "/posts/#{post.id}/comments"
            links['author'] = "/users/#{post.author.id}"

            respond_with resource: post
          end
        end
      end
    end
  end
end
```

You can also set the links when calling `#respond_with`:

```ruby
module API
  module V1
    module Post
      module Operation
        class Show < Pragma::Operation::Base
          def call
            post = ::Post.find(params[:id])

            respond_with resource: post, links: {
              comments: "/posts/#{post.id}/comments",
              author: "/users/#{post.author.id}"
            }
          end
        end
      end
    end
  end
end
```

This will build the `Link` header accordingly:

```ruby
result = API::V1::Post::Operation::Show.call(params: { id: 1 })

result.status # => :ok
result.headers
# => {
#   'Link' => '</posts/1/comments>; rel="comments",
#                </users/49>; rel="author"'
#    }
```

**Note: Do not set the `Link` header manually, as it will be replaced when building links from the
`links` hash.**

## Handling errors

You can use the `#success?` and `#failure?` method to check whether an operation was successful. An
operation is considered successful when it returns a 2xx or 3xx status code:

```ruby
module API
  module V1
    module Ping
      module Operation
        class Create < Pragma::Operation::Base
          def call
            if params[:pong].blank?
              return respond_with(
                status: :unprocessable_entity,
                resource: {
                  error_type: :missing_pong,
                  error_message: "You must provide a 'pong' parameter."
                }
              )
            end

            respond_with status: :ok, resource: { pong: params[:pong] }
          end
        end
      end
    end
  end
end
```

Once more, here's an example usage of the above operation:

```ruby
result1 = API::V1::Ping::Operation::Create.call(params: { pong: '' })
result1.success? # => false

result2 = API::V1::Ping::Operation::Create.call(params: { pong: 'HELLO' })
result2.success? # => true
```

## Halting the execution

Both `#respond_with` and `#head` provide bang counterparts that halt the execution of the operation.
They are useful, for instance, in before callbacks.

The above operation can be rewritten like this:

```ruby
module API
  module V1
    module Ping
      module Operation
        class Create < Pragma::Operation::Base
          before :validate_params

          def call
            respond_with status: :ok, resource: { pong: params[:pong] }
          end

          private

          def validate_params
            if params[:pong].blank?
              respond_with!(
                status: :unprocessable_entity,
                resource: {
                  error_type: :missing_pong,
                  error_message: "You must provide a 'pong' parameter."
                }
              )
            end
          end
        end
      end
    end
  end
end
```

The result is identical:

```ruby
result1 = API::V1::Ping::Operation::Create.call(params: { pong: '' })
result1.success? # => false

result2 = API::V1::Ping::Operation::Create.call(params: { pong: 'HELLO' })
result2.success? # => true
```
