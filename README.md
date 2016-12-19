# Pragma::Policy

[![Build Status](https://img.shields.io/travis/pragmarb/pragma-operation.svg?maxAge=3600&style=flat-square)](https://travis-ci.org/pragmarb/pragma-operation)
[![Dependency Status](https://img.shields.io/gemnasium/pragmarb/pragma-operation.svg?maxAge=3600&style=flat-square)](https://gemnasium.com/github.com/pragmarb/pragma-operation)
[![Code Climate](https://img.shields.io/codeclimate/github/pragmarb/pragma-operation.svg?maxAge=3600&style=flat-square)](https://codeclimate.com/github/pragmarb/pragma-operation)
[![Coveralls](https://img.shields.io/coveralls/pragmarb/pragma-operation.svg?maxAge=3600&style=flat-square)](https://coveralls.io/github/pragmarb/pragma-operation)

Operations encapsulate the business logic of your JSON API.

They are built on top of the awesome [Interactor](https://github.com/collectiveidea/interactor) gem.

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

As you can see, an operation takes parameters as an input and returns:

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

### Handling errors

You can use the `#success?` method to check whether an operation was successful. An operation is
considered successful when it returns a 2xx or 3xx status code:

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

### Halting execution

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

### Validating records

...

### Authorizing records

...

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pragmarb/pragma-operation.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
