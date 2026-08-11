defmodule Finsave.Identity.AccountsTest do
  alias Finsave.Identity.Account
  use Finsave.DataCase, async: true

  alias Finsave.Identity.Accounts
  import Finsave.Factory

  describe "get_account/1" do
    test "should return account from DB and populate cache or cache miss" do
      account = insert(:account)

      assert {:ok, nil} = Cachex.get(:account_cache, account.id)
      assert {:ok, fetched_account} = Accounts.get_account(account.id)
      assert fetched_account.id == account.id

      assert {:ok, cached_account} = Cachex.get(:account_cache, account.id)
      assert cached_account.id == account.id
    end

    test "should return account from cache on cache hit" do
      account = insert(:account)
      Cachex.put(:account_cache, account.id, account)

      assert {:ok, fetched_account} = Accounts.get_account(account.id)
      assert fetched_account.id == account.id
    end

    test "should return error if account doesnt exist" do
      fake_id = Ecto.UUID.generate()

      assert {:error, :not_found} = Accounts.get_account(fake_id)
    end
  end

  describe "get_account_by_email/1" do
    test "should return account if exist" do
      account = insert(:account, email: "example@email.com")

      assert {:ok, fetched_account} = Accounts.get_account_by_email("example@email.com")
      assert fetched_account.id == account.id
    end

    test "should return error if account doesnt exist" do
      assert {:error, :not_found} = Accounts.get_account_by_email("nonexist@email.com")
    end
  end

  describe "create_account/1" do
    test "shouls create account with valid data" do
      attrs = %{email: "new_user@email.com", password: "Q1w2e3r4t5!"}

      assert {:ok, %Account{} = account} = Accounts.create_account(attrs)

      assert account.email == "new_user@email.com"
      assert account.password_hash != nil
    end

    test "should return error changeset with invalid data" do
      attrs = %{email: "invalid_email", password: "invalid_password"}

      assert {:error, changeset} = Accounts.create_account(attrs)

      assert "has invalid format" in errors_on(changeset).email

      assert "has invalid format" in errors_on(changeset).password
    end
  end

  describe "update_account/2" do
    test "should update account and invalidate cache" do
      account = insert(:account, name: "old_name")
      Cachex.put(:account_cache, account.id, account)

      attrs = %{name: "new_name"}

      assert {:ok, updated_account} = Accounts.update_account(account, attrs)
      assert updated_account.name == "new_name"

      assert {:ok, nil} = Cachex.get(:account_cache, account.id)
    end

    test "should return error changeset with invalid data and keep cache intact" do
      account = insert(:account, name: "normal_name")
      Cachex.put(:account_cache, account.id, account)

      attrs = %{name: "12"}

      assert {:error, changeset} = Accounts.update_account(account, attrs)
      assert "should be at least 3 character(s)" in errors_on(changeset).name

      assert {:ok, %Account{}} = Cachex.get(:account_cache, account.id)
    end

    test "should not update email" do
      account = insert(:account)

      attrs = %{email: "email@email.com"}

      Accounts.update_account(account, attrs)
      assert {:ok, new_account} = Accounts.get_account(account.id)
      assert account.email == new_account.email
    end
  end

  describe "soft_delete_account/1" do
    test "should set deleated_at timestump and clear cache" do
      account = insert(:account)

      Cachex.put(:account_cache, account.id, account)

      assert {:ok, deleted_account} = Accounts.soft_delete_account(account)

      assert deleted_account.deleted_at != nil

      assert {:ok, nil} = Cachex.get(:account_cache, account.id)
    end
  end

  describe "change_password/2" do
    test "should update password and clear cache" do
      account = insert(:account)
      Cachex.put(:account_cache, account.id, account)

      attrs = %{password: "NewStrongPass1!"}

      assert {:ok, updated_account} = Accounts.change_password(account, attrs)

      assert updated_account.password_hash != account.password_hash

      assert {:ok, nil} = Cachex.get(:account_cache, account.id)
    end

    test "should return error changeset when password does not meet requirements" do
      account = insert(:account)
      attrs = %{password: "123"}

      assert {:error, changeset} = Accounts.change_password(account, attrs)

      assert "has invalid format" in errors_on(changeset).password
    end
  end

  describe "authentificate/2" do
    test "should return account on successful authentication" do
      password = "Password123!"
      password_hash = Argon2.hash_pwd_salt(password)

      account = insert(:account, email: "auth_user@example.com", password_hash: password_hash)

      assert {:ok, auth_account} = Accounts.authentificate("auth_user@example.com", password)
      assert auth_account.id == account.id
    end

    test "should return error on invalid password" do
      insert(:account, email: "auth_user@example.com", password: "Password123!")

      assert {:error, :invalid_credentials} =
               Accounts.authentificate("auth_user@example.com", "WrongPassword")
    end

    test "should return error when account doesn't exist" do
      assert {:error, :invalid_credentials} =
               Accounts.authentificate("ghost@example.com", "Password123!")
    end
  end
end
