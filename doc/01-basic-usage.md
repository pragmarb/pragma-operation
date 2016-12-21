# Basic usage

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
only covers the features provided specifically by Pragma::Operation.

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
