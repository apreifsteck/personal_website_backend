defmodule APReifsteck.CommentTest do
  @moduledoc """
  Make sure Posts is working before you consider these test valid.
  """
  use APReifsteck.DataCase, async: true

  alias APReifsteck.Media
  alias APReifsteck.Repo

  alias APReifsteck.Media.Comment

  @valid_attrs %{
    "body" => "some comment body"
  }
  @update_attrs %{
    "body" => "a new comment body"
  }
  @invalid_update_attrs %{
    "body" => nil
  }
  @invalid_attrs %{
    "body" => nil
  }

  describe "create_comment/2" do
    setup do
      post_author = user_fixture()

      {:ok,
       post_author: post_author, post: post_fixture(post_author), comment_author: random_user()}
    end

    test "creates a basic comment", context do
      attrs = Map.merge(@valid_attrs, %{"author_id" => context.comment_author.id})
      {:ok, comment} = Media.create_comment(context.post, attrs)
      assert comment.author_id == context.comment_author.id
      assert comment.post_id == context.post.id
      assert comment.body == @valid_attrs["body"]
      assert comment.edited == false
    end

    test "on an edited post registers that comment to the root post", context do
      {:ok, edited_post} =
        Media.update_post(context.post, %{"body" => "a new post body"})

      attrs = Map.merge(@valid_attrs, %{"author_id" => context.comment_author.id})
      {:ok, comment} = Media.create_comment(edited_post, attrs)
      assert comment.author_id == context.comment_author.id
      assert comment.post_id == context.post.id
      assert comment.body == @valid_attrs["body"]
    end

    test "can created a nested comment", context do
      attrs = Map.merge(@valid_attrs, %{"author_id" => context.comment_author.id})
      {:ok, comment} = Media.create_comment(context.post, attrs)

      {:ok, nested_comment} =
        Media.create_comment(
          context.post,
          Map.merge(@update_attrs, %{
            "parent_comment_id" => comment.id,
            "author_id" => random_user().id
          })
        )

      nested_comment = Repo.preload(nested_comment, :parent_comment)
      assert nested_comment.parent_comment.id == comment.id
      assert nested_comment.body == @update_attrs["body"]
    end

    test "cannot create a comment if the post disallows it", context do
      {:ok, post} =
        Media.update_post(context.post, %{"enable_comments" => false})

      attrs = Map.merge(@valid_attrs, %{"author_id" => context.comment_author.id})
      {:error, msg} = Media.create_comment(post, attrs)
      assert msg == "This post does not allow comments"
    end

    test "cannot create a comment with invalid attrs", context do
      attrs = Map.merge(@invalid_attrs, %{"author_id" => context.comment_author.id})
      assert {:error, _} = Media.create_comment(context.post, attrs)
    end

    test "assoc constraint for author works", context do
      attrs = Map.merge(@valid_attrs, %{"author_id" => context.comment_author.id + 1})
      assert {:error, _} = Media.create_comment(context.post, attrs)
    end
  end

  describe "update_comment/2" do
    setup do
      post_author = user_fixture()
      post = post_fixture(post_author)

      {:ok, parent_comment} =
        Media.create_comment(post, %{
          "body" => "the parent body",
          "author_id" => random_user().id
        })

      {:ok, comment} =
        Media.create_comment(
          post,
          Map.merge(@valid_attrs, %{
            "parent_comment_id" => parent_comment.id,
            "author_id" => random_user().id
          })
        )

      {:ok, comment: comment, post: post}
    end

    test "can update a comment with valid attrs", %{comment: comment} do
      {:ok, updated_comment} = Media.update_comment(comment, @update_attrs)
      assert updated_comment.body == @update_attrs["body"]
      assert updated_comment.edited
    end

    test "cannot change the parent comment of a comment", %{comment: comment, post: post} do
      {:ok, random_comment} =
        Media.create_comment(post, %{
          "body" => "a different comment body",
          "author_id" => random_user().id
        })

      {:ok, updated_comment} =
        Media.update_comment(
          comment,
          Map.merge(@update_attrs, %{"parent_comment_id" => random_comment.id})
        )

      assert updated_comment.parent_comment_id == comment.parent_comment_id
      assert updated_comment.body == @update_attrs["body"]
      assert updated_comment.edited
    end
  end

  describe "show/2" do
    setup do
      post = post_fixture(user_fixture())

      for n <- 1..3 do
        "body " <> Integer.to_string(n)
      end
      |> Enum.each(&Media.create_comment(post, %{"body" => &1, "author_id" => random_user().id}))

      {:ok, post: post}
    end

    test "fetches all comments for a post", %{post: post} do
      assert length(Media.get_post_comments(post)) == 3
    end
  end
end
