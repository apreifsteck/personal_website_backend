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
    setup do
      {:ok, user: user_fixture()}
    end

    test "create post with valid attrs creates a post", %{user: user} do
      assert {:ok, %Post{} = post} = Media.create_post(@valid_attrs, user)
    end

    test "create post with invalid attrs returns an error", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Media.create_post(@invalid_attrs, user)
    end

    test "create post with a nil user returns an error" do
      assert {:error, _} = Media.create_post(@valid_attrs, nil)
    end
  end

  # TODO: write tests for list_post

  describe "get_post" do
    setup do
      user = user_fixture()
      {:ok, %Post{} = post} = Media.create_post(@valid_attrs, user)
      {:ok, user: user, post: post}
    end

    test "get a post that the user has created returns the post", %{user: user, post: post} do
      {:ok, test_post} = Media.get_post(post.id)
      assert test_post.id == post.id
    end

    test "returns only one post when there are multiple", %{user: user, post: post} do
      attrs =
        @valid_attrs
        |> Map.replace!("title", "this is a different post")

      Media.create_post(attrs, user)
      assert post = Media.get_post(post.id)
    end
  end

  # this is supposed to return all posts in a series of edits, both forwards and backwards histories.
  # guarantee that the first post in the list is the root post
  # otherwise, posts are in no particular order

  def batch_update(post, attrs_list) when attrs_list != [] do
    [head | tail] = attrs_list
    {:ok, post} = Media.update_post(post, head)
    batch_update(post, tail)
  end

  def batch_update(post, _attrs_list) do
    query = from c in Post, order_by: c.id

    # Get all the edits of a post in ascending order. Does not include root
    Repo.preload(post, root: [children: {query, []}]).root.children
  end

  describe "helper functions" do
    setup do
      user = user_fixture()
      titles = ~w(one two three)
      bodies = ~w(bodyOne bodyTwo bodyThree)

      attrs =
        for p <- Enum.zip(titles, bodies) do
          %{"title" => elem(p, 0), "body" => elem(p, 1), "enable_comments" => false}
        end

      {:ok, root_post} = Media.create_post(@valid_attrs, user)
      posts = batch_update(root_post, attrs)

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

    test "get_root_post gets the root post", %{user: user, posts: posts, root_post: root_post} do
      [p1, p2, p3] = posts
      assert Media.get_root_post(p3).id == root_post.id
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

      {:ok, edit} = Media.update_post(root_post, update_attrs)
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
      {:ok, another_edit} = Media.update_post(edit, update_attrs)
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

      latest_edit = Media.get_latest_edit(post)

      assert {:error, "may only edit the latest version of the post"} =
               Media.update_post(post, update_attrs)

      assert latest_edit.id == Media.get_latest_edit(post).id
    end

    test "editing a post with invalid attrs does not update the post", %{
      user: user,
      edit: edit
    } do
      assert {:error, errors} = Media.update_post(edit, @invalid_attrs)
      assert errors != []
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

      {:ok, root_post} = Media.create_post(@valid_attrs, user)
      posts = batch_update(root_post, attrs)

      # I tested it and these get returned in order
      {:ok, user: user, posts: posts, root_post: root_post}
    end

    # should trigger a cascade delete
    test "root post is the only one allowed to be deleted", %{user: user, posts: posts} do
      [_head | [middle | _last]] = posts

      assert {:error, "you can only delete posts from the root post"} =
               Media.delete_post(middle)
    end

    test "deleting root post does a cascading delete on edits", %{
      user: user,
      posts: posts,
      root_post: root_post
    } do
      [head | [branch | leaf]] = posts
      assert {:ok, root_post} = Media.delete_post(root_post)
      assert Repo.get(Post, head.id) == nil
      assert Repo.get(Post, branch.id) == nil
      assert Repo.get(Post, hd(leaf).id) == nil
    end
  end
end
