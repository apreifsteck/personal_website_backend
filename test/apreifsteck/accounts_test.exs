defmodule APReifsteck.AccountsTest do
  use APReifsteck.DataCase

  alias APReifsteck.Accounts

  alias APReifsteck.Accounts.User

  @valid_attrs %{
    email: "some email",
    name: "some name",
    password: "some password",
    uname: "some uname"
  }
  @update_attrs %{
    email: "some updated email",
    name: "some updated name",
    password: "some updated password",
    uname: "some updated uname"
  }
  @invalid_attrs %{email: nil, name: nil, password: nil, uname: nil}

  describe "create_user/1" do
    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{id: id} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "some email"
      assert user.name == "some name"
      assert user.uname == "some uname"
      assert [%User{id: ^id}] = Accounts.list_users()
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "enforces unique usernames" do
      assert {:ok, %User{id: id}} = Accounts.create_user(@valid_attrs)
      assert {:error, changeset} = Accounts.create_user(@valid_attrs)

      assert %{uname: ["has already been taken"]} = errors_on(changeset)

      assert [%User{id: ^id}] = Accounts.list_users()
    end

    test "does not accept long usernames" do
      attrs = Map.put(@valid_attrs, :uname, String.duplicate("a", 30))
      {:error, changeset} = Accounts.create_user(attrs)

      assert %{uname: ["should be at most 20 character(s)"]} = errors_on(changeset)

      assert Accounts.list_users() == []
    end

    test "requires password to be at least 6 chars long" do
      attrs = Map.put(@valid_attrs, :password, "12345")
      {:error, changeset} = Accounts.create_user(attrs)

      assert %{password: ["should be at least 6 character(s)"]} = errors_on(changeset)

      assert Accounts.list_users() == []
    end
  end

  test "list_users/0 returns all users" do
    user = user_fixture()
    assert Accounts.list_users() == [user]
  end

  test "get_user!/1 returns the user with given id" do
    user = user_fixture()
    assert Accounts.get_user!(user.id) == user
  end

  test "update_user/2 with valid data updates the user" do
    old_user = user_fixture()
    assert {:ok, %User{} = user} = Accounts.update_user(old_user, @update_attrs)
    assert user.email == "some updated email"
    assert user.name == "some updated name"
    assert user.password_hash != old_user.password_hash
    assert user.uname == "some updated uname"
  end

  test "update_user/2 with invalid data returns error changeset" do
    user = user_fixture()
    assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
    assert user == Accounts.get_user!(user.id)
  end

  test "delete_user/1 deletes the user" do
    user = user_fixture()
    assert {:ok, %User{}} = Accounts.delete_user(user)
    assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
  end

  test "change_user/1 returns a user changeset" do
    user = user_fixture()
    assert %Ecto.Changeset{} = Accounts.change_user(user)
  end
end
