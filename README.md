# Controller Validations

## Learning Goals

- Check the validity of a model in a controller
- Render a response with the error messages
- Use HTTP status codes to provide additional context

## Introduction

Now that we've seen how Active Record can be used to validate our data, let's
see how we can use that in our controllers to give our user access to the
validation errors, so they can fix their typos or other problems with their
request.

To get set up, run:

```console
$ bundle install
$ rails db:migrate db:seed
$ rails s
```

## Manually Checking Validation

Up until this point, our `create` action has looked something like this:

```rb
# app/controllers/birds_controller.rb
def create
  bird = Bird.create(bird_params)
  render json: bird, status: :created
end
```

Let's add some validation to our `Bird` model, so that we don't end up with bad
data:

```rb
# app/models/bird.rb
class Bird < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
```

Now, if we try to create a bird using Postman with bad data, we've got a
problem!

```json
{
  "species": "Archilochus colubris"
}
```

Our server still returns a `Bird` object, but we can clearly see that it wasn't
saved successfully:

```json
{
  "id": null,
  "name": null,
  "species": "Archilochus colubris",
  "created_at": null,
  "updated_at": null,
  "likes": 0
}
```

From this process, we can tell:

- Our model validation prevented this bad data from being saved in the database
  (yay!)
- The response doesn't tell us anything about why the data wasn't saved (boo.)

To provide this additional context, we need to update our controller action to
change the response based on whether or not the bird was saved successfully.

```rb
def create
  bird = Bird.create(bird_params)
  if bird.valid?
    render json: bird, status: :created
  else
    render json: { errors: bird.errors }, status: :unprocessable_entity
  end
end
```

Now, we get a different response after sending that same request in Postman:

```json
{
  "errors": {
    "name": ["can't be blank"]
  }
}
```

From the controller, `bird.errors` will give a serializable object with all the
error messages from our Active Record validations.

We also included the status code of [422 Unprocessable Entity][422], indicating
this was a bad request.

[422]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/422

We can clean up this controller action by handling the
`ActiveRecord::RecordInvalid` exception class along with `create!` or `update!`:

```rb
def create
  bird = Bird.create!(bird_params)
  render json: bird, status: :created
rescue ActiveRecord::RecordInvalid => invalid
  render json: { errors: invalid.record.errors }, status: :unprocessable_entity
end
```

In the `rescue` block, the `invalid` variable is an instance of the exception
itself. From that `invalid` variable, we can access the actual Active Record
instance with the `record` method, where we can retrieve its errors.

We can take a similar approach to validation in our `update` method, since
validations will also run when a model is updated:

```rb
def update
  bird = find_bird
  bird.update!(bird_params)
  render json: bird
rescue ActiveRecord::RecordInvalid => invalid
  render json: { errors: invalid.record.errors }, status: :unprocessable_entity
end
```

We could also handle **all** `ActiveRecord::RecordInvalid` exceptions in the controller
with the `rescue_from` method:

```rb
class BirdsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found_response
  # added rescue_from
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity_response

  # rest of controller actions...

  private

  def render_unprocessable_entity_response(invalid)
    render json: { errors: invalid.record.errors }, status: :unprocessable_entity
  end

  # rest of private methods...
end
```

Now, our `create` and `update` actions can focus on the happy path:

```rb
def create
  # create! exceptions will be handled by the rescue_from ActiveRecord::RecordInvalid code
  bird = Bird.create!(bird_params)
  render json: bird, status: :created
end

def update
  bird = find_bird
  # update! exceptions will be handled by the rescue_from ActiveRecord::RecordInvalid code
  bird.update!(bird_params)
  render json: bird
end
```

## Formatting the Error Response

When we're sending back error messages, we should take care to format the error
messages in a way that can be easily displayed by our frontend. Take another
look at the current implementation:

```rb
render json: { errors: invalid.record.errors }, status: :unprocessable_entity
```

This will return a JSON object in the body of the response with a key of `errors`
pointing to a nested object where the **keys** are the invalid attributes, and
**values** are the validation error messages, like this:

```json
{
  "errors": {
    "name": ["can't be blank"],
    "species": ["must be unique"]
  }
}
```

We could also return a different format by using the `#full_messages` method
to output an array of pre-formatted error messages:

```rb
render json: { errors: invalid.record.errors.full_messages }, status: :unprocessable_entity
```

That would produce a slightly different output:

```json
{
  "errors": ["Name can't be blank", "Species must be unique"]
}
```

Notice in either case, the key on our JSON object is `errors` since we are
returning a collection of error messages (either an object or an array).

Which format you choose will depend largely on how you plan on using this data
on the frontend. It's good to know you have options!

## Conclusion

With model validations in place, we can help protect our database against bad
data. Active Record validations also help provide **error messages** to indicate
why a certain value wasn't considered valid data. We can access the model's
validity and error messages in the controller. By sending this data in the
response, we'll be able to provide additional context to our clients about what
went wrong with their request so they can fix it.
