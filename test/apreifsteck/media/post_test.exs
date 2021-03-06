defmodule APReifsteck.PostTest do
  use APReifsteck.DataCase, async: true

  alias APReifsteck.Media
  alias APReifsteck.Repo

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
    @malicious_attrs %{
      "title" => "I'm a sneaky bastard",
      "body" => "<h1>Hello <script>World!</script></h1>"
    }
    setup do
      {:ok, user: user_fixture()}
    end

    test "create post with valid attrs creates a post", %{user: user} do
      assert {:ok, %Post{} = post} = Media.create_post(@valid_attrs, user)
    end

    test "create post with invalid attrs returns an error", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Media.create_post(@invalid_attrs, user)
    end

    test "creating a post with invalid html will sanatize it", %{user: user} do
      assert {:ok, %Post{} = post} = Media.create_post(@malicious_attrs, user)
      assert post.body == "<h1>Hello World!</h1>"
    end
  end

  describe "get_post" do
    setup do
      user = user_fixture()
      {:ok, %Post{} = post} = Media.create_post(@valid_attrs, user)
      {:ok, user: user, post: post}
    end

    test "get a post that the user has created returns the post", %{user: user, post: post} do
      assert Media.get_post(post.id, user).id == post.id
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
  describe "helper functions" do
    setup do
      user = user_fixture()
      titles = ~w(one two three)
      bodies = ~w(bodyOne bodyTwo bodyThree)

      attrs =
        for p <- Enum.zip(titles, bodies) do
          %{"title" => elem(p, 0), "body" => elem(p, 1), "enable_comments" => false}
        end

      # I realize this is awful, but it's what I had to do without defining a ton of extra functions
      posts = []
      {:ok, root_post} = Media.create_post(@valid_attrs, user)
      [head | tail] = attrs
      {:ok, post} = Media.update_post(root_post.id, user, head)
      posts = List.insert_at(posts, 0, post)
      [head | tail] = tail
      {:ok, post} = Media.update_post(post.id, user, head)
      posts = List.insert_at(posts, 1, post)
      [head | _] = tail
      {:ok, post} = Media.update_post(post.id, user, head)
      posts = List.insert_at(posts, 2, post)

      # I tested it and these get returned in order
      {:ok, user: user, posts: posts, root_post: root_post}
    end

    test "get_latest_edit gets last edit", %{user: user, posts: posts, root_post: root_post} do
      [head | [second | tail]] = posts
      [tail | _] = tail
      assert Media.get_latest_edit(head).id == tail.id
      assert Media.get_latest_edit(second).id == tail.id
      assert Media.get_latest_edit(tail).id == tail.id
      assert Media.get_latest_edit(root_post).id == tail.id

      {:ok, new_post} = Media.create_post(@valid_attrs, user)
      assert Media.get_latest_edit(new_post).id == new_post.id
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

      {:ok, edit} = Media.update_post(root_post.id, user, update_attrs)
      {:ok, user: user, post: root_post, edit: edit}
    end

    # I want to store the edit history of posts
    test "editing a post with valid attrs updates the post", %{post: post, edit: edit} do
      assert post.id != edit.id
      assert edit.root_id == post.id
      assert edit.title != post.title
      assert edit.body != post.body
    end

    test "can add an update to a chain of updates", %{user: user, post: post, edit: edit} do
      # I want you to only need to pass in the changes that you want and the rest will be kept
      update_attrs = %{
        "title" => "an even more different title"
      }

      # Post edits have one root node, and the edits are leaves.
      # You can order them either by their insert date or id, both are monotomically increasing.

      {:ok, another_edit} = Media.update_post(edit.id, user, update_attrs)
      assert another_edit.body == edit.body
      assert another_edit.root_id == post.id
      assert another_edit.title == update_attrs["title"]
      assert edit.root_id == post.id

      # Check to make sure the associations load correctly
      preloaded_post =
        post
        |> Repo.preload([:children, :root])

      assert preloaded_post.root == nil
      assert Enum.count(preloaded_post.children) == 2
      assert Enum.find(preloaded_post.children, nil, fn x -> x.id == edit.id end) != nil
      assert Enum.find(preloaded_post.children, nil, fn x -> x.id == another_edit.id end) != nil
    end

    test "cannot edit a post that has already had an edit done", %{
      user: user,
      post: post
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
      edit: edit
    } do
      assert {:error, errors} = Media.update_post(edit.id, user, @invalid_attrs)
      assert errors != []
    end

    test "cannot edit another user's post", %{post: post} do
      user2 = random_user()

      update_attrs = %{
        "title" => "an even more different title"
      }

      assert {:error, "must ask for post ID of a post from the given user"} =
               Media.update_post(post.id, user2, update_attrs)
    end
  end

  describe "delete_post" do
    setup do
      user = user_fixture()
      titles = ~w(one two three)
      bodies = ~w(bodyOne bodyTwo bodyThree)

      attrs =
        for p <- Enum.zip(titles, bodies) do
          %{"title" => elem(p, 0), "body" => elem(p, 1), "enable_comments" => false}
        end

      # I realize this is awful, but it's what I had to do without defining a ton of extra functions
      posts = []
      {:ok, root_post} = Media.create_post(@valid_attrs, user)
      [head | tail] = attrs
      {:ok, post} = Media.update_post(root_post.id, user, head)
      posts = List.insert_at(posts, 0, post)
      [head | tail] = tail
      {:ok, post} = Media.update_post(post.id, user, head)
      posts = List.insert_at(posts, 1, post)
      [head | _tail] = tail
      {:ok, post} = Media.update_post(post.id, user, head)
      posts = List.insert_at(posts, 2, post)

      # I tested it and these get returned in order
      {:ok, user: user, posts: posts, root_post: root_post}
    end

    # should trigger a cascade delete
    test "root post is the only one allowed to be deleted", %{user: user, posts: posts} do
      [_head | [middle | _last]] = posts

      assert {:error, "you can only delete posts from the root post"} =
               Media.delete_post(middle.id, user)
    end

    test "users can only delete their own posts", %{user: user} do
      other_user = random_user()

      another_post = %{
        "title" => "I decided to change the title",
        "body" => "here's a different body too",
        "enable_comments" => false
      }

      {:ok, another_post} = Media.create_post(another_post, other_user)

      assert {:error, "must ask for post ID of a post from the given user"} =
               Media.delete_post(another_post.id, user)
    end

    test "deleting root post does a cascading delete on edits", %{
      user: user,
      posts: posts,
      root_post: root_post
    } do
      [head | [branch | leaf]] = posts
      assert {:ok, root_post} = Media.delete_post(root_post.id, user)
      assert Repo.get(Post, head.id) == nil
      assert Repo.get(Post, branch.id) == nil
      assert Repo.get(Post, hd(leaf).id) == nil
    end
  end
end
