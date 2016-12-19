# Pragma::Operation

[![Build Status](https://img.shields.io/travis/pragmarb/pragma-operation.svg?maxAge=3600&style=flat-square)](https://travis-ci.org/pragmarb/pragma-operation)
[![Dependency Status](https://img.shields.io/gemnasium/pragmarb/pragma-operation.svg?maxAge=3600&style=flat-square)](https://gemnasium.com/github.com/pragmarb/pragma-operation)
[![Code Climate](https://img.shields.io/codeclimate/github/pragmarb/pragma-operation.svg?maxAge=3600&style=flat-square)](https://codeclimate.com/github/pragmarb/pragma-operation)
[![Coveralls](https://img.shields.io/coveralls/pragmarb/pragma-operation.svg?maxAge=3600&style=flat-square)](https://coveralls.io/github/pragmarb/pragma-operation)

Operations encapsulate the business logic of your JSON API.

They are built on top of the awesome [Interactor](https://github.com/collectiveidea/interactor) gem.

<!-- MarkdownTOC depth=3 autolink=true -->

- [Installation][installation]
- [Usage][usage]
  - [Handling errors][handling-errors]
  - [Halting the execution][halting-the-execution]
- [Integrations][integrations]
  - [Pragma::Contract][pragmacontract]
  - [Pragma::Policy][pragmapolicy]
- [Contributing][contributing]
- [License][license]

<!-- /MarkdownTOC -->

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pragma-operation'
```

And then execute:

```console
$ bundle
```

Or install it yourself as:

```console
$ gem install pragma-operation
```

## Usage

Here's the simplest operation you can write:

```ruby
module API
  module V1
    module Ping
      module Operation
        class Create < Pragma::Operation::Base
          def call
            respond_with status: :ok, resource: { pong: params[:pong] }
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
only covers the features provided specifically by Pragma::Contract.

### Handling errors

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

### Halting the execution

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

## Integrations

### Pragma::Contract

Operations integrate with [Pragma::Contract](https://github.com/pragmarb/pragma-contract). You can
specify the contract to use with `#contract` and get access to `#validate` and `#validate!` in your
operations:

```ruby
module API
  module V1
    module Post
      module Operation
        class Create < Pragma::Operation::Base
          contract API::V1::Post::Contract::Create

          def call
            post = Post.new

            validate! contract
            contract.save

            respond_with status: :created, resource: post
          end
        end
      end
    end
  end
end
```

If the contract passes validation, then all is good. If not, an error is raised:

```ruby
result1 = API::V1::Post::Operation::Create.call(params: {
  title: 'My First Post',
  body: 'Hello everyone, this is my first post!'
})

result1.status # => :created
result1.resource
# => {
#      'title' => 'My First Post'
#      'body' => 'Hello everyone, this is my first post!'
#    }

result2 = API::V1::Post::Operation::Create.call(params: {
  title: 'My First Post'
})

result2.status # => :forbidden
result2.resource
# => {
#      'error_type' => 'unprocessable_entity',
#      'error_message' => 'The contract for this operation was not respected.',
#      'meta' => {
#        'errors' => {
#          'body' => ["can't be blank"]
#        }
#      }
#    }
```

You can also use the non-bang method `#validate` to implement your own logic:

```ruby
module API
  module V1
    module Post
      module Operation
        class Create < Pragma::Operation::Base
          contract API::V1::Post::Contract::Create

          def call
            post = Post.new
            contract = build_contract(post)

            unless validate(contract)
              respond_with!(
                status: :unprocessable_entity,
                resource: nil
              )
            end

            contract.save

            respond_with status: :created, resource: post
          end
        end
      end
    end
  end
end
```

### Pragma::Policy

Operations integrate with [Pragma::Policy](https://github.com/pragmarb/pragma-policy). All you have
to do is specify the policy class with `#policy`. This will give you access to `#authorize` and
`#authorize!`:

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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pragmarb/pragma-operation.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
