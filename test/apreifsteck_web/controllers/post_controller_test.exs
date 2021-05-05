defmodule APReifsteckWeb.PostControllerTest do
  use APReifsteckWeb.ConnCase

  alias APReifsteck.Media
  alias APReifsteck.Media.Post

  # TODO: test that CUD are user-only, but read actions can be unathenticated
  # TODO: test error path for each method (not just happy path)
  @create_attrs %{"title" => "(TEST) post", "body" => "HEY!!!!"}
  @update_attrs %{"body" => "SALUTATIONS!!!"}
  @invalid_attrs %{"body" => nil, "title" => nil}

  defp batch_create(user, attrs_list) when attrs_list != [] do
    [head | tail] = attrs_list
    {:ok, _post} = Media.create_post(head, user)
    batch_create(user, tail)
  end

  defp batch_create(user, _attrs_list) do
    alias APReifsteck.Repo

    Repo.all(Post)
    |> Repo.preload(:user)

    APReifsteck.Repo.preload(user, :posts).posts
  end

  def fixture(:posts, user) do
    titles = ~w(one two three)
    bodies = ~w(bodyOne bodyTwo bodyThree)

    attrs =
      for p <- Enum.zip(titles, bodies) do
        %{"title" => elem(p, 0), "body" => elem(p, 1), "enable_comments" => false}
      end

    batch_create(user, attrs)
  end

  def fixture(:post, user) do
    {:ok, post} = Media.create_post(@create_attrs, user)
    post
  end

  def fixture(:user, conn) do
    valid_params = %{
      "user" => %{
        "name" => "Test Testman",
        "uname" => "test",
        "email" => "test@example.com",
        "password" => "testpass",
        "password_confirmation" => "testpass"
      }
    }

    post(conn, Routes.registration_path(conn, :create, valid_params))
  end

  setup %{conn: conn} do
    registration_conn = fixture(:user, conn)
    authed_conn = Plug.Conn.assign(conn, :current_user, registration_conn.assigns.current_user)
    {:ok, conn: put_req_header(conn, "accept", "application/json"), authed_conn: authed_conn}
  end

  describe "index" do
    setup %{authed_conn: conn} do
      fixture(:post, random_user())
      posts = fixture(:posts, conn.assigns.current_user)
      {:ok, posts: posts}
    end

    test "lists all posts", %{conn: conn, posts: posts} do
      conn = get(conn, Routes.post_path(conn, :index))
      data = json_response(conn, 200)["data"]
      assert length(data) == length(posts) + 1
      assert Enum.find(data, fn item -> item["id"] == hd(posts).id end)
    end

    test "edits returned as children, but not top level elements", %{
      conn: conn,
      posts: posts,
      authed_conn: authed_conn
    } do
      {:ok, updated_post} =
        Media.update_post(hd(posts),  @update_attrs)

      Media.update_post(updated_post, @update_attrs)

      conn = get(conn, Routes.post_path(conn, :index))
      data = json_response(conn, 200)["data"]
      assert length(data) == length(posts) + 1

      assert Enum.find(data, fn item ->
               item["edits"] != [] and
                 hd(item["edits"])["id"] == updated_post.id
             end)
    end
  end

  describe "show" do
    setup %{authed_conn: conn} do
      create_post(conn.assigns.current_user)
    end

    test "returns id, title, comments_enabled and body of selected post", %{
      conn: conn,
      post: post
    } do
      conn = get(conn, Routes.post_path(conn, :show, post.id))
      data = json_response(conn, 200)["data"]
      assert data["id"] == post.id
      assert data["title"] == post.title
      assert data["body"] == post.body
      # defined by database default
      assert data["enable_comments"] == true
    end
  end

  describe "create post" do
    test "disallowed when not signed in", %{conn: conn} do
      conn = post(conn, Routes.post_path(conn, :create), post: @create_attrs)
      assert %{"error" => error} = json_response(conn, 401)

      assert %{
               "error" => %{"message" => "Not authenticated"}
             } = json_response(conn, 401)
    end

    test "renders post when data is valid", %{authed_conn: conn} do
      conn = post(conn, Routes.post_path(conn, :create), post: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.post_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: conn} do
      conn = post(conn, Routes.post_path(conn, :create), post: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update post" do
    setup %{authed_conn: conn} do
      create_post(conn.assigns.current_user)
    end

    setup context do
      mconn = Plug.Conn.assign(conn, :current_user, random_user())
      {:ok, malicious_conn: mconn}
    end

    test "renders post when data is valid", %{authed_conn: conn, post: %Post{id: id} = post} do
      conn = put(conn, Routes.post_path(conn, :update, post), post: @update_attrs)
      assert %{"id" => update_id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.post_path(conn, :show, id))

      assert %{
               "id" => update_id,
               "root_id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: conn, post: post} do
      conn = put(conn, Routes.post_path(conn, :update, post), post: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders errors when user tries to update a post that is not theirs", %{post: post, malicious_conn: mconn} do
      mconn = put(mconn, Routes.post_path(mconn, :update, post), post: @update_attrs)
      assert json_response(mconn, 401)
    end
  end

  describe "delete post" do
    setup %{authed_conn: conn} do
      create_post(conn.assigns.current_user)
    end
    setup _ do
      mconn = Plug.Conn.assign(conn, :current_user, random_user())
      {:ok, malicious_conn: mconn}
    end

    test "deletes chosen post", %{authed_conn: conn, post: post} do
      conn = delete(conn, Routes.post_path(conn, :delete, post))
      assert response(conn, 204)

      assert response(
               conn |> get(Routes.post_path(conn, :show, post)),
               404
             )
    end

    test "malicious actors cannot delete posts not their own", %{malicious_conn: mconn, post: post, authed_conn: conn} do
      mconn = delete(mconn, Routes.post_path(mconn, :delete, post))
      assert response(mconn, 401)

      assert response(get(conn, Routes.post_path(conn, :show, post)), 200) 
    end
  end

  defp create_post(user) do
    post = fixture(:post, user)
    {:ok, post: post}
  end
end
