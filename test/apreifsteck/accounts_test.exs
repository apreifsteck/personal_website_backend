defmodule APReifsteck.AccountsTest do
  use APReifsteck.DataCase

  alias APReifsteck.Accounts

  alias APReifsteck.Accounts.User

  @update_attrs %{
    email: "some updated email",
    name: "some updated name",
    # I cheated and looked
    current_password: "secretpassword",
    password: "some updated password",
    password_confirmation: "some updated password",
    uname: "some updated uname"
  }
  @invalid_attrs %{email: nil, name: nil, password: nil, uname: nil}

  # User creation now handled by registration controller

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
