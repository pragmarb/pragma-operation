# Contracts

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
