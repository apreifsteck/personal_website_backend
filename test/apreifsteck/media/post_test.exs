defmodule APReifsteck.PostTest do
  use APReifsteck.DataCase, async: true

  alias APReifsteck.Media
  alias APReifsteck.Repo
  alias APReifsteck.Accounts.User

  alias APReifsteck.Media.Post

  @valid_attrs %{
    "title" => "simple title",
    "body" => "<h1>Hello</h1>",
    "enable_comments" => false
  }

  @invalid_attrs %{
    "title" => nil,
    "body" => nil
  }

  describe "create_post" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "create post with valid attrs creates a post", %{user: user} do
      assert {:ok, %Post{} = post} = Media.create_post(@valid_attrs, user)
    end

    test "create post with invalid attrs returns an error", %{user: user} do
      assert false
    end

    test "creating a post with invalid html will sanatize it", %{user: user} do
      assert false
    end
  end

  describe "get_post" do
    setup do
      user = user_fixture()
      {:ok, %Post{} = post} = Media.create_post(@valid_attrs, user)
      {:ok, user: user, post: post}
    end

    test "get a post that the user has created returns the post", %{user: user, post: post} do
      fetched_post = Media.get_post(post.id, user)
      assert fetched_post = post
    end

    test "get_post returns only one post when there are multiple", %{user: user, post: post} do
      attrs =
        @valid_attrs
        |> Map.replace!("title", "this is a different post")

      Media.create_post(attrs, user)
      assert post = Media.get_post(post.id, user)
    end

    test "trying to get a post not made by that user returns an error", %{user: user} do
      other_user = random_user()

      attrs =
        @valid_attrs
        |> Map.replace!("title", "this is a different post")

      {:ok, other_post} = Media.create_post(attrs, other_user)

      assert {:error, _} = Media.get_post(other_post.id, user)
    end
  end

  # this is supposed to return all posts in a series of edits, both forwards and backwards histories.
  # guarantee that the first post in the list is the root post
  # otherwise, posts are in no particular order
  describe "get_post_history" do
    setup do
      user = user_fixture()
      titles = ~w(one two three)
      bodies = ~w(bodyOne bodyTwo bodyThree)

      posts =
        for p <- Enum.zip(titles, bodies),
            do:
              %{"title" => elem(p, 0), "body" => elem(p, 1), "enable_comments" => false}
              |> Media.create_post(user)

      # I tested it and these get returned in order
      {:ok, user: user, posts: posts}
    end

    test "get_post_history(root_post) returns all posts", %{user: user, posts: posts} do
      [root_post | tail] = posts
      assert Media.get_post_history(root_post.id, user) |> Enum.count() == Enum.count(posts)
    end

    test "get_post_history(child) returns all posts, with the root post in front", %{
      user: user,
      posts: posts
    } do
      [head | [second | tail]] = posts
      post_history = Media.get_post_history(second.id, user)
      assert head = Enum.fetch(post_history, 0)
      assert Enum.count(post_history) == Enum.count(posts)
    end
  end

  describe "update_post" do
    setup do
      user = user_fixture()
      {:ok, root_post} = Media.create_post(@valid_attrs, user)

      update_attrs = %{
        "title" => "I decided to change the title",
        "body" => "here's a different body too",
        "enable_comments" => false
      }

      edit = Media.update_post(root_post.id, user, update_attrs)

      {:ok, user: user, post: root_post, edit: edit}
    end

    # I want to store the edit history of posts
    test "editing a post with valid attrs updates the post", %{user: user, post: post, edit: edit} do
      assert post.id != edit.id
      assert edit.prev_hist == post.id
      assert edit.title != post.title
      assert edit.body != post.body
    end

    test "can add an update to a chain of updates", %{user: user, post: post, edit: edit} do
      # I want you to only need to pass in the changes that you want and the rest will be kept
      update_attrs = %{
        "title" => "an even more different title"
      }

      another_edit = Media.update_post(edit.id, user, update_attrs)
      assert another_edit.body == edit.body
      assert another_edit.prev_hist == edit.id
      assert another_edit.title != edit.title
      assert edit.prev_hist == post.id
    end

    test "cannot edit a post that has already had an edit done", %{
      user: user,
      post: post,
      edit: edit
    } do
      # the intention of this is that you cannot sneakily edit a post with an edit already, you have
      # to make a new edit that becomes part of the history
      update_attrs = %{
        "title" => "an even more different title"
      }

      assert {:error, "may only edit the latest version of the post"} =
               Media.update_post(post.id, user, update_attrs)
    end

    test "editing a post with invalid attrs does not update the post", %{
      user: user,
      post: post,
      edit: edit
    } do
      assert {:error, errors} = Media.update_post(edit.id, user, @invalid_attrs)
      assert errors != []
    end

    test "cannot edit another user's post", %{user: user, post: post, edit: edit} do
      user2 = random_user()

      update_attrs = %{
        "title" => "an even more different title"
      }

      assert {:error, "must ask for post ID of a post from the given user"} =
               Media.update_post(post.id, user2, update_attrs)
    end
  end

  describe "delete_post" do
    # should trigger a cascade delete
    test "head post is the only one allowed to be deleted", %{user: user, posts: posts} do
      [head | [middle | last]] = posts

      assert {:error, "you can only delete posts from the most recent edit"} =
               Media.delete_post(last.id, user)
    end

    test "users can only delete their own posts", %{user: user, posts: posts} do
      other_user = random_user()

      another_post = %{
        "title" => "I decided to change the title",
        "body" => "here's a different body too",
        "enable_comments" => false
      }

      {:ok, another_post} = Media.create_post(another_post, other_user)

      assert {:error, "a user can only delete their own posts"} =
               Media.delete_post(another_post.id, user)
    end

    test "deleting root post does a cascading delete on edits", %{user: user, posts: posts} do
      [root | [branch | leaf]] = posts
      assert {:ok} = Media.delete_post(root.id, user)
      assert nil = Repo.get(Post, root.id)
      assert nil = Repo.get(Post, branch.id)
      assert nil = Repo.get(Post, leaf.id)
    end
  end
end
